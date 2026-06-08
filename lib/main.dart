import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:stitch_daily_delivery_ledger/core/app_theme.dart';
import 'package:stitch_daily_delivery_ledger/core/app_state.dart';
import 'package:stitch_daily_delivery_ledger/core/ai_analyst_controller.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_customer_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_delivery_log_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_expense_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_rice_bag_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_settings_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_owner_finance_repository.dart';
import 'package:stitch_daily_delivery_ledger/screens/home_shell.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 1. Programmatically calculate date range for the entire previous calendar day
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
      final yesterdayEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);

      final String startIso = yesterdayStart.toIso8601String();
      final String endIso = yesterdayEnd.toIso8601String();

      // Format yesterday for expenses: "yyyy-MM-dd"
      final String yesterdayDateStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      // 2. Fetch yesterday-only payload
      // 2.1 Yesterday's transaction logs (delivery logs)
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('deliveryLogs')
          .where('dateTime', isGreaterThanOrEqualTo: startIso)
          .where('dateTime', isLessThanOrEqualTo: endIso)
          .get();

      // 2.2 Yesterday's expenses
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('date', isEqualTo: yesterdayDateStr)
          .get();

      // 2.3 Customers ledger balances
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();

      // 2.4 Owner repayments yesterday
      final repaymentsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('repayments')
          .where('repaymentDate', isGreaterThanOrEqualTo: startIso)
          .where('repaymentDate', isLessThanOrEqualTo: endIso)
          .get();

      // 3. Build text payload
      final buffer = StringBuffer();
      buffer.writeln("=== DATE OF AUDIT ===");
      buffer.writeln("Yesterday's Date: $yesterdayDateStr\n");

      buffer.writeln("=== TRANSACTION LOGS (DELIVERIES & PAYMENTS) ===");
      if (logsSnapshot.docs.isEmpty) {
        buffer.writeln("No delivery logs or cash collection entries for yesterday.");
      } else {
        for (var doc in logsSnapshot.docs) {
          final data = doc.data();
          final serialNo = data['serialNo'] ?? '';
          final cName = data['customerName'] ?? '';
          final itemName = data['itemName'] ?? '';
          final amount = data['amount'] ?? 0.0;
          final isPaid = data['isPaid'] ?? false;
          final isPayment = data['isPayment'] ?? false;
          buffer.writeln("- Log #$serialNo: Customer: $cName, Item: $itemName, Amount: ₹$amount, Paid Status: ${isPaid ? 'PAID' : 'UNPAID'}, Is Cash Payment Entry: $isPayment");
        }
      }
      buffer.writeln();

      buffer.writeln("=== BUSINESS EXPENSES ===");
      if (expensesSnapshot.docs.isEmpty) {
        buffer.writeln("No expenses recorded for yesterday.");
      } else {
        for (var doc in expensesSnapshot.docs) {
          final data = doc.data();
          final itemName = data['itemName'] ?? '';
          final category = data['category'] ?? '';
          final amount = data['amount'] ?? 0.0;
          buffer.writeln("- Item: $itemName, Category: $category, Cost: ₹$amount");
        }
      }
      buffer.writeln();

      buffer.writeln("=== CUSTOMER LEDGER BALANCES (CURRENT OUTSTANDING) ===");
      if (customersSnapshot.docs.isEmpty) {
        buffer.writeln("No customers found.");
      } else {
        for (var doc in customersSnapshot.docs) {
          final data = doc.data();
          final name = data['name'] ?? '';
          final outstanding = data['outstanding'] ?? 0.0;
          buffer.writeln("- Customer: $name, Outstanding Balance: ₹$outstanding");
        }
      }
      buffer.writeln();

      buffer.writeln("=== OWNER CAPITAL REPAYMENTS ===");
      if (repaymentsSnapshot.docs.isEmpty) {
        buffer.writeln("No owner loan repayments recorded for yesterday.");
      } else {
        for (var doc in repaymentsSnapshot.docs) {
          final data = doc.data();
          final amountPaid = data['amountPaid'] ?? 0.0;
          buffer.writeln("- Repayment Amount: ₹$amountPaid");
        }
      }

      final payload = buffer.toString();

      // 4. Send payload to Gemini model endpoint
      const String key = String.fromEnvironment('GEMINI_API_KEY');
      if (key.isEmpty) {
        debugPrint("Background Auditor Error: GEMINI_API_KEY is empty.");
        return false;
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: key,
      );

      final prompt = Content.text(
        "You are a professional auditor reviewing the finalized financial records for yesterday. "
        "Audit the mathematical consistency of the sales totals, expenses, and calculated margins. "
        "If everything balances perfectly, reply with exactly 'PASS'. "
        "If there is a miscalculation, a missing entry pattern, or a duplicate record typo, reply with exactly 'ALERT: [Concise description of the discrepancy]'.\n\n"
        "Here are the records for yesterday:\n"
        "$payload"
      );

      final response = await model.generateContent([prompt]);
      final responseText = response.text?.trim() ?? "PASS";

      debugPrint("Background Auditor Result: $responseText");

      // Save the audit result into Firestore so the app can fetch it next day
      await FirebaseFirestore.instance
          .collection('audit_results')
          .doc(yesterdayDateStr)
          .set({
        'date': yesterdayDateStr,
        'result': responseText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Check if we need to show notification
      if (responseText.contains("ALERT:")) {
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();

        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );

        await flutterLocalNotificationsPlugin.initialize(
          settings: initializationSettings,
        );

        const AndroidNotificationDetails androidNotificationDetails =
            AndroidNotificationDetails(
          'daily_audit_alerts',
          'Daily Financial Audit Alerts',
          channelDescription: 'Alerts flagged by the automated daily background auditor',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

        const NotificationDetails notificationDetails =
            NotificationDetails(android: androidNotificationDetails);

        await flutterLocalNotificationsPlugin.show(
          id: 888,
          title: 'Financial Audit Alert',
          body: responseText.replaceFirst("ALERT:", "").trim(),
          notificationDetails: notificationDetails,
        );
      }

      return true;
    } catch (e, stack) {
      debugPrint("Background task execution error: $e");
      debugPrint("$stack");
      return false;
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Calculate the delay until the next midnight to align execution
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    final initialDelay = nextMidnight.difference(now);

    await Workmanager().registerPeriodicTask(
      "daily_financial_audit", // uniqueName
      "daily_financial_audit_task", // taskName
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      tag: "daily_financial_audit",
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LedgerState(
            customerRepository: FirestoreCustomerRepository(),
            deliveryLogRepository: FirestoreDeliveryLogRepository(),
            expenseRepository: FirestoreExpenseRepository(),
            riceBagRepository: FirestoreRiceBagRepository(),
            settingsRepository: FirestoreSettingsRepository(),
            ownerFinanceRepository: FirestoreOwnerFinanceRepository(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AIAnalystController(
            customerRepository: FirestoreCustomerRepository(),
            deliveryLogRepository: FirestoreDeliveryLogRepository(),
            expenseRepository: FirestoreExpenseRepository(),
            riceBagRepository: FirestoreRiceBagRepository(),
            ownerFinanceRepository: FirestoreOwnerFinanceRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Sales Tracking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeShell(),
      ),
    );
  }
}
