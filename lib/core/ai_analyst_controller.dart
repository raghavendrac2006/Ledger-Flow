import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'repositories/customer_repository.dart';
import 'repositories/delivery_log_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/rice_bag_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/repositories/owner_finance_repository.dart';
import 'package:stitch_daily_delivery_ledger/core/models/models.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIAnalystController extends ChangeNotifier {
  final CustomerRepository customerRepository;
  final DeliveryLogRepository deliveryLogRepository;
  final ExpenseRepository expenseRepository;
  final RiceBagRepository riceBagRepository;
  final OwnerFinanceRepository ownerFinanceRepository;

  AIAnalystController({
    required this.customerRepository,
    required this.deliveryLogRepository,
    required this.expenseRepository,
    required this.riceBagRepository,
    required this.ownerFinanceRepository,
  });

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get apiKey {
    return const String.fromEnvironment('GEMINI_API_KEY');
  }

  bool get isConfigured => apiKey.isNotEmpty;

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<String> _buildDataPayload() async {
    final customers = await customerRepository.getAllCustomers((_) => Icons.person);
    final logs = await deliveryLogRepository.getAllLogs();
    final expenses = await expenseRepository.getAllExpenses();
    final bags = await riceBagRepository.getAllRiceBags();

    OwnerLoanConfig? loan;
    List<RepaymentLog> repayments = [];
    try {
      loan = await ownerFinanceRepository.getActiveLoan();
      if (loan != null) {
        repayments = await ownerFinanceRepository.getRepayments(loan.id);
      }
    } catch (e) {
      debugPrint("Error fetching owner finance logs for AI payload: $e");
    }

    final buffer = StringBuffer();
    buffer.writeln("=== CUSTOMERS OUTSTANDING BALANCE SHEET ===");
    for (var c in customers) {
      buffer.writeln("- Customer: ${c.name}, Outstanding Debt: ₹${c.outstanding.toStringAsFixed(2)}, Area: ${c.area}, Type: ${c.type}, Location: ${c.location}");
    }
    buffer.writeln();

    buffer.writeln("=== HISTORICAL DELIVERY LOGS & SALES ===");
    for (var l in logs) {
      buffer.writeln("- LogID: ${l.logId}, Customer: ${l.customerName}, Item: ${l.itemName}, Amount: ₹${l.amount.toStringAsFixed(2)}, Status: ${l.isPaid ? 'PAID' : 'UNPAID'}, Date: ${l.date}, IsPaymentEntry: ${l.isPayment}");
    }
    buffer.writeln();

    buffer.writeln("=== BUSINESS EXPENSES ===");
    for (var e in expenses) {
      buffer.writeln("- ExpenseID: ${e.expenseId}, Category: ${e.category}, Item: ${e.itemName}, Cost: ₹${e.amount.toStringAsFixed(2)}, Date: ${e.date}");
    }
    buffer.writeln();

    buffer.writeln("=== RICE FLOUR PRODUCTION BAGS ===");
    for (var b in bags) {
      buffer.writeln("- Bag #${b.bagNumber}, Cap: ${b.totalKg} KG, Used: ${b.usedKg} KG, Remaining: ${b.remainingKg} KG, Purchase Cost: ₹${b.cost.toStringAsFixed(2)}, Start Date: ${b.startDate}, Status: ${b.status}");
    }
    buffer.writeln();

    if (loan != null) {
      buffer.writeln("=== OWNER CAPITAL LOANS ===");
      buffer.writeln("- Loan Description: ${loan.description}, Total Borrowed: ₹${loan.totalBorrowed.toStringAsFixed(2)}, Amount Repaid: ₹${loan.amountRepaid.toStringAsFixed(2)}, Remaining Debt: ₹${loan.remainingBalance.toStringAsFixed(2)}, Notes: ${loan.notes}");
      buffer.writeln("- Repayment History:");
      for (var r in repayments) {
        buffer.writeln("  * Paid: ₹${r.amountPaid.toStringAsFixed(2)} on ${r.repaymentDate}");
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<void> askAnalyst(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final userMsg = ChatMessage(text: cleanQuery, isUser: true, timestamp: DateTime.now());
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final key = apiKey;
      if (key.isEmpty) {
        _messages.add(ChatMessage(
          text: "Configuration Error: Gemini API Key is missing. Please define `GEMINI_API_KEY` using --dart-define compiler flag.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        return;
      }

      final dataPayload = await _buildDataPayload();

      // Instantiate Gemini model model endpoint
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: key,
        systemInstruction: Content.system(
          "You are an expert financial analyst. You will be given a text-based payload of raw sales and expense ledgers. Answer the user's explicit question accurately using only the data provided. Keep responses clear and concise."
        ),
      );

      final prompt = Content.text(
        "Here is the raw snapshot of the business databases:\n\n"
        "$dataPayload\n\n"
        "User query: $cleanQuery"
      );

      final response = await model.generateContent([prompt]);
      final responseText = response.text ?? "No reply was returned by the model.";

      _messages.add(ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Error generating response: $e",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
