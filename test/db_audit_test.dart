// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Removed compile-time dependency on firebase_options.dart to support repository isolation

void main() {
  test('Audit Firestore calculations and report discrepancies', () async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'mock-api-key',
            appId: '1:123456:web:123456',
            messagingSenderId: '123456',
            projectId: 'mock-project-id',
          ),
        );
      }
    } catch (e) {
      print("Skipping Firestore calculations audit: Firebase Core channel not available in this test environment.");
      return;
    }

    print("\n==========================================");
    print("STARTING FIRESTORE CALCULATIONS AUDIT");
    print("==========================================\n");

    // 1. Fetch all Firestore data
    print("Fetching Firestore collection snapshots...");
    final customersSnap = await FirebaseFirestore.instance.collection('customers').get();
    final logsSnap = await FirebaseFirestore.instance.collection('deliveryLogs').get();
    final expensesSnap = await FirebaseFirestore.instance.collection('expenses').get();
    final bagsSnap = await FirebaseFirestore.instance.collection('riceBags').get();
    final usagesSnap = await FirebaseFirestore.instance.collection('dailyUsages').get();

    print("Fetched:");
    print("- ${customersSnap.docs.length} Customers");
    print("- ${logsSnap.docs.length} Delivery Logs");
    print("- ${expensesSnap.docs.length} Expenses");
    print("- ${bagsSnap.docs.length} Rice Bags");
    print("- ${usagesSnap.docs.length} Daily Usages\n");

    // Map logs to lists for easier processing
    final logs = logsSnap.docs.map((doc) => doc.data()).toList();
    final expenses = expensesSnap.docs.map((doc) => doc.data()).toList();
    final bags = bagsSnap.docs.map((doc) => doc.data()).toList();

    // 2. AUDIT CUSTOMER OUTSTANDING BALANCES
    print("--- AUDITING CUSTOMER OUTSTANDING BALANCES ---");
    bool customerDiscrepancyFound = false;
    for (var custDoc in customersSnap.docs) {
      final custData = custDoc.data();
      final name = custData['name'] as String? ?? custDoc.id;
      final storedOutstanding = (custData['outstanding'] as num?)?.toDouble() ?? 0.0;

      // Calculate outstanding balance from delivery logs
      double calculatedOutstanding = 0.0;
      int unpaidDeliveries = 0;
      int paymentEntries = 0;

      final custLogs = logs.where((log) => (log['customerName'] as String?).toString().toLowerCase() == name.toLowerCase()).toList();
      for (var log in custLogs) {
        final amt = (log['amount'] as num?)?.toDouble() ?? 0.0;
        final isPayment = log['isPayment'] as bool? ?? false;
        final isPaid = log['isPaid'] as bool? ?? false;

        if (isPayment) {
          calculatedOutstanding -= amt;
          paymentEntries++;
        } else if (!isPaid) {
          calculatedOutstanding += amt;
          unpaidDeliveries++;
        }
      }

      final diff = (storedOutstanding - calculatedOutstanding).abs();
      if (diff > 0.01) {
        print("🚨 DISCREPANCY: Customer '$name'");
        print("   - Stored Outstanding:  ₹${storedOutstanding.toStringAsFixed(2)}");
        print("   - Calculated Outstanding: ₹${calculatedOutstanding.toStringAsFixed(2)}");
        print("   - Difference:           ₹${diff.toStringAsFixed(2)}");
        print("   - Unpaid Deliveries:    $unpaidDeliveries, Payments: $paymentEntries");
        customerDiscrepancyFound = true;
      }
    }
    if (!customerDiscrepancyFound) {
      print("✅ All customer outstanding balances match transaction logs perfectly.");
    }
    print("");

    // 3. AUDIT COMPLETED RICE BAGS FINANCIALS
    print("--- AUDITING COMPLETED RICE BAGS ---");
    bool bagDiscrepancyFound = false;
    final completedBags = bags.where((b) => b['status'] == 'Completed').toList();
    for (var bag in completedBags) {
      final bagId = bag['bagId'] as String? ?? '';
      final bagNum = bag['bagNumber'] ?? 'Unknown';
      final storedRev = (bag['revenue'] as num?)?.toDouble() ?? 0.0;
      final storedExp = (bag['expenses'] as num?)?.toDouble() ?? 0.0;
      final storedProfit = (bag['profit'] as num?)?.toDouble() ?? 0.0;
      final storedMargin = (bag['profitMargin'] as num?)?.toDouble() ?? 0.0;

      // Calculate Revenue
      final bagLogs = logs.where((l) => !(l['isPayment'] as bool? ?? false) && l['associatedBagId'] == bagId).toList();
      final calculatedRev = bagLogs.fold(0.0, (total, l) => total + ((l['amount'] as num?)?.toDouble() ?? 0.0));

      // Calculate Expenses
      DateTime? startDate;
      try {
        startDate = DateFormat('dd MMMM yyyy').parse(bag['startDate'] as String? ?? '');
      } catch (_) {}

      final bagExpenses = expenses.where((exp) {
        if (exp['associatedBagId'] == bagId) return true;
        if (exp['associatedBagId'] != null) return false;
        if (startDate != null) {
          try {
            final expDate = DateTime.parse(exp['date'] as String? ?? '');
            return expDate.isAfter(startDate.subtract(const Duration(days: 1)));
          } catch (_) {}
        }
        return false;
      }).toList();
      final calculatedExp = bagExpenses.fold(0.0, (total, e) => total + ((e['amount'] as num?)?.toDouble() ?? 0.0));

      final calculatedProfit = calculatedRev - calculatedExp;
      final calculatedMargin = calculatedRev <= 0.0 ? 0.0 : (calculatedProfit / calculatedRev) * 100.0;

      final diffRev = (storedRev - calculatedRev).abs();
      final diffExp = (storedExp - calculatedExp).abs();
      final diffProfit = (storedProfit - calculatedProfit).abs();
      final diffMargin = (storedMargin - calculatedMargin).abs();

      if (diffRev > 0.01 || diffExp > 0.01 || diffProfit > 0.01 || diffMargin > 0.1) {
        print("🚨 DISCREPANCY: Rice Bag #$bagNum ($bagId)");
        if (diffRev > 0.01) {
          print("   - Revenue: Stored: ₹${storedRev.toStringAsFixed(2)}, Calc: ₹${calculatedRev.toStringAsFixed(2)} (Diff: ₹${diffRev.toStringAsFixed(2)})");
        }
        if (diffExp > 0.01) {
          print("   - Expenses: Stored: ₹${storedExp.toStringAsFixed(2)}, Calc: ₹${calculatedExp.toStringAsFixed(2)} (Diff: ₹${diffExp.toStringAsFixed(2)})");
        }
        if (diffProfit > 0.01) {
          print("   - Profit: Stored: ₹${storedProfit.toStringAsFixed(2)}, Calc: ₹${calculatedProfit.toStringAsFixed(2)} (Diff: ₹${diffProfit.toStringAsFixed(2)})");
        }
        if (diffMargin > 0.1) {
          print("   - Margin: Stored: ${storedMargin.toStringAsFixed(2)}%, Calc: ${calculatedMargin.toStringAsFixed(2)}% (Diff: ${diffMargin.toStringAsFixed(2)}%)");
        }
        bagDiscrepancyFound = true;
      }
    }
    if (!bagDiscrepancyFound) {
      print("✅ All completed rice bags have mathematically consistent revenue/expense totals.");
    }
    print("");

    // 4. AUDIT OVERALL LIFETIME SUMMARY
    print("--- AUDITING OVERALL BUSINESS SUMMARY ---");
    final double calculatedOverallRevenue = logs
        .where((log) => !(log['isPayment'] as bool? ?? false))
        .fold(0.0, (total, log) => total + ((log['amount'] as num?)?.toDouble() ?? 0.0));

    final double calculatedOverallExpenses = expenses
        .fold(0.0, (total, exp) => total + ((exp['amount'] as num?)?.toDouble() ?? 0.0));

    final double calculatedOverallProfit = calculatedOverallRevenue - calculatedOverallExpenses;
    final double calculatedOverallMargin = calculatedOverallRevenue <= 0.0 ? 0.0 : (calculatedOverallProfit / calculatedOverallRevenue) * 100.0;

    print("Calculated Overall Business Stats:");
    print("- Total Lifetime Sales:    ₹${calculatedOverallRevenue.toStringAsFixed(2)}");
    print("- Total Lifetime Expenses: ₹${calculatedOverallExpenses.toStringAsFixed(2)}");
    print("- Net Lifetime Profit:     ₹${calculatedOverallProfit.toStringAsFixed(2)}");
    print("- Lifetime Profit Margin:  ${calculatedOverallMargin.toStringAsFixed(2)}%\n");

    print("==========================================");
    print("AUDIT COMPLETE");
    print("==========================================\n");
  });
}
