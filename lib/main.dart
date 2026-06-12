import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stitch_daily_delivery_ledger/core/app_theme.dart';
import 'package:stitch_daily_delivery_ledger/core/app_state.dart';
import 'package:stitch_daily_delivery_ledger/core/ai_analyst_controller.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_customer_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_delivery_log_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_expense_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_rice_bag_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_settings_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/firestore/firestore_owner_finance_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/mock_repositories.dart';
import 'package:stitch_daily_delivery_ledger/screens/home_shell.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();

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

      // --- CASH-FLOW CORE REPOSITORY AGGREGATION & ADVISOR LOOP ---
      double actualCashInHand = 0.0;
      double salesPaid = 0.0;
      double repaymentsIncoming = 0.0;

      for (var doc in logsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final isPaid = data['isPaid'] ?? false;
        final isPayment = data['isPayment'] ?? false;

        if (!isPayment && isPaid) {
          salesPaid += amount;
        } else if (isPayment) {
          repaymentsIncoming += amount;
        }
      }
      actualCashInHand = salesPaid + repaymentsIncoming;

      double actualExpenses = 0.0;
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        actualExpenses += amount;
      }

      double netLiquidMargin = actualCashInHand - actualExpenses;

      // Fetch dynamic settings from Firestore
      int minSavingsPct = 2;
      int maxSavingsPct = 7;
      try {
        final settingsDoc = await FirebaseFirestore.instance
            .collection('settings')
            .doc('financeSettings')
            .get();
        if (settingsDoc.exists && settingsDoc.data() != null) {
          final data = settingsDoc.data()!;
          minSavingsPct = (data['min_savings_pct'] as num?)?.toInt() ?? 2;
          maxSavingsPct = (data['max_savings_pct'] as num?)?.toInt() ?? 7;
        }
      } catch (e) {
        debugPrint("Could not fetch remote finance settings in background: $e. Using default 2% to 7%.");
      }

      final savingsPrompt = Content.text(
        "You are an on-the-ground cash flow analyst for a local distribution market. Analyze yesterday's true physical cash flow.\n\n"
        "Yesterday's Financial Summary:\n"
        "- Cash Received from Paid Sales: ₹$salesPaid\n"
        "- Customer Repayments/Installments: ₹$repaymentsIncoming\n"
        "- Total Cash-In-Hand: ₹$actualCashInHand\n"
        "- Total Expenses: ₹$actualExpenses\n"
        "- Net Liquid Margin (Surplus): ₹$netLiquidMargin\n\n"
        "Rules:\n"
        "1. If Net Liquid Margin is less than or equal to 0, return a recommended savings value of 0.\n"
        "2. If positive, calculate a safe micro-savings recommendation between $minSavingsPct% to $maxSavingsPct% of that physical cash surplus, rounded to the nearest 10 or 50 rupees.\n"
        "3. You MUST return a clean, verified JSON structure matching exactly:\n"
        "{\n"
        "  \"suggested_savings\": <int>,\n"
        "  \"conversational_reason\": \"<String brief summary in English describing the cash-in performance>\"\n"
        "}\n\n"
        "Do NOT return any markdown wrapping, code block tags, or extra text. Return ONLY the raw JSON string."
      );

      final savingsResponse = await model.generateContent([savingsPrompt]);
      final savingsResponseText = savingsResponse.text?.trim() ?? "{\"suggested_savings\": 0, \"conversational_reason\": \"No response from advisor.\"}";

      String cleanJsonText = savingsResponseText;
      if (cleanJsonText.startsWith("```")) {
        cleanJsonText = cleanJsonText.replaceAll(RegExp(r'^```[a-z]*\n|```$'), '');
      }
      cleanJsonText = cleanJsonText.trim();

      int suggestedSavings = 0;
      String conversationalReason = "Could not parse advisor response.";
      try {
        final parsed = jsonDecode(cleanJsonText) as Map<String, dynamic>;
        suggestedSavings = (parsed['suggested_savings'] as num?)?.toInt() ?? 0;
        conversationalReason = parsed['conversational_reason'] as String? ?? '';
      } catch (e) {
        debugPrint("Failed to parse savings advisor JSON: $e. Response was: $savingsResponseText");
      }

      await FirebaseFirestore.instance
          .collection('savings_recommendations')
          .doc(yesterdayDateStr)
          .set({
        'date': yesterdayDateStr,
        'suggested_savings': suggestedSavings,
        'conversational_reason': conversationalReason,
        'status': 'pending',
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
  
  bool isMockMode = false;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e. Falling back to local mock sandbox simulation.");
    isMockMode = true;
  }

  if (!kIsWeb && !isMockMode) {
    try {
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
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    } catch (e) {
      debugPrint("Workmanager initialization failed: $e");
    }
  }

  runApp(MyApp(isMockMode: isMockMode));
}

class MyApp extends StatelessWidget {
  final bool isMockMode;
  const MyApp({super.key, this.isMockMode = false});

  @override
  Widget build(BuildContext context) {
    final customerRepo = isMockMode ? MockCustomerRepository() : FirestoreCustomerRepository();
    final deliveryLogRepo = isMockMode ? MockDeliveryLogRepository() : FirestoreDeliveryLogRepository();
    final expenseRepo = isMockMode ? MockExpenseRepository() : FirestoreExpenseRepository();
    final riceBagRepo = isMockMode ? MockRiceBagRepository() : FirestoreRiceBagRepository();
    final settingsRepo = isMockMode ? MockSettingsRepository() : FirestoreSettingsRepository();
    final ownerFinanceRepo = isMockMode ? MockOwnerFinanceRepository() : FirestoreOwnerFinanceRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LedgerState(
            customerRepository: customerRepo,
            deliveryLogRepository: deliveryLogRepo,
            expenseRepository: expenseRepo,
            riceBagRepository: riceBagRepo,
            settingsRepository: settingsRepo,
            ownerFinanceRepository: ownerFinanceRepo,
            isMockMode: isMockMode,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AIAnalystController(
            customerRepository: customerRepo,
            deliveryLogRepository: deliveryLogRepo,
            expenseRepository: expenseRepo,
            riceBagRepository: riceBagRepo,
            ownerFinanceRepository: ownerFinanceRepo,
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
