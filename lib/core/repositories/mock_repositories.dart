import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ledgerflow/core/models/customer.dart';
import 'package:ledgerflow/core/models/delivery_log.dart';
import 'package:ledgerflow/core/models/expense_log.dart';
import 'package:ledgerflow/core/models/rice_bag.dart';
import 'package:ledgerflow/core/models/daily_usage.dart';
import 'package:ledgerflow/core/models/owner_finance_model.dart';
import 'package:ledgerflow/core/repositories/customer_repository.dart';
import 'package:ledgerflow/core/repositories/delivery_log_repository.dart';
import 'package:ledgerflow/core/repositories/expense_repository.dart';
import 'package:ledgerflow/core/repositories/rice_bag_repository.dart';
import 'package:ledgerflow/core/repositories/settings_repository.dart';
import 'package:ledgerflow/core/repositories/owner_finance_repository.dart';

class MockDb {
  static final List<Customer> customers = [
    Customer(
      name: "Balu",
      outstanding: 1200.0,
      type: "RETAIL",
      area: "Market Street",
      icon: Icons.store,
      location: "Market St, 1st Cross",
    ),
    Customer(
      name: "Anwar Store",
      outstanding: 450.0,
      type: "WHOLESALE",
      area: "Main Bazaar",
      icon: Icons.business,
      location: "Main Bazaar Road",
    ),
    Customer(
      name: "Ganesh Kirana",
      outstanding: 0.0,
      type: "RETAIL",
      area: "Station Road",
      icon: Icons.store,
      location: "Station Road",
    ),
  ];

  static final List<DeliveryLog> deliveryLogs = [
    DeliveryLog(
      serialNo: 1001,
      customerName: "Balu",
      itemName: "Five Rupees Chikki",
      amount: 500.0,
      isPaid: false,
      isPayment: false,
      associatedBagId: "BAG_1",
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      date: "12 Jun 2026",
    ),
    DeliveryLog(
      serialNo: 1002,
      customerName: "Anwar Store",
      itemName: "Nippat",
      amount: 450.0,
      isPaid: false,
      isPayment: false,
      associatedBagId: "BAG_1",
      dateTime: DateTime.now().subtract(const Duration(hours: 3)),
      date: "12 Jun 2026",
    ),
    DeliveryLog(
      serialNo: 1003,
      customerName: "Balu",
      itemName: "Cash Collected",
      amount: 700.0,
      isPaid: true,
      isPayment: true,
      associatedBagId: "BAG_1",
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      date: "12 Jun 2026",
    ),
  ];

  static final List<ExpenseLog> expenses = [
    ExpenseLog(
      expenseId: "EXP_1",
      amount: 150.0,
      itemName: "Diesel",
      category: "Fuel",
      associatedBagId: "BAG_1",
      date: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
    ),
  ];

  static final List<RiceBag> riceBags = [
    RiceBag(
      bagId: "BAG_1",
      bagNumber: 1,
      status: "Active",
      revenue: 950.0,
      expenses: 150.0,
      profit: 800.0,
      profitMargin: 84.2,
      startDate: "12 Jun 2026",
      endDate: "",
      totalKg: 25.0,
      remainingKg: 25.0,
      cost: 1000.0,
    ),
  ];

  static final List<DailyUsage> dailyUsages = [];

  static String googleSheetsUrl = "https://script.google.com/macros/s/dummy/exec";
  static List<String> expenseSuggestions = ["Diesel", "Labor", "Meals", "Repairs"];

  static OwnerLoanConfig loanConfig = OwnerLoanConfig(
    id: "default_owner_loan",
    description: "Owner Capital Fund",
    totalBorrowed: 50000.0,
    amountRepaid: 15000.0,
    notes: "Sandbox owner fund tracking notes.",
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  static final List<RepaymentLog> repayments = [
    RepaymentLog(
      id: "REP_1",
      amountPaid: 15000.0,
      repaymentDate: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  static final List<SavingsLog> savingsLogs = [
    SavingsLog(
      id: "SAV_1",
      amount: 1000.0,
      type: "deposit",
      notes: "Initial sandbox savings log",
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static final List<SavingsRecommendation> savingsRecommendations = [];
}

class MockCustomerRepository implements CustomerRepository {
  final _controller = StreamController<List<Customer>>.broadcast();

  MockCustomerRepository() {
    _controller.add(List.from(MockDb.customers));
  }

  @override
  Stream<List<Customer>> getCustomersStream(IconData Function(String?) getIcon) {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_controller.isClosed) {
        _controller.add(List.from(MockDb.customers));
      } else {
        timer.cancel();
      }
    });
    return _controller.stream;
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    MockDb.customers.add(customer);
    _controller.add(List.from(MockDb.customers));
  }

  @override
  Future<void> updateCustomerOutstanding(String customerName, double amount) async {
    for (int i = 0; i < MockDb.customers.length; i++) {
      if (MockDb.customers[i].name.toLowerCase() == customerName.toLowerCase()) {
        MockDb.customers[i] = MockDb.customers[i].copyWith(outstanding: amount);
      }
    }
    _controller.add(List.from(MockDb.customers));
  }

  @override
  Future<void> saveCustomer(Customer customer) async {
    final idx = MockDb.customers.indexWhere((c) => c.name == customer.name);
    if (idx != -1) {
      MockDb.customers[idx] = customer;
    } else {
      MockDb.customers.add(customer);
    }
    _controller.add(List.from(MockDb.customers));
  }

  @override
  Future<void> deleteCustomer(String customerName) async {
    MockDb.customers.removeWhere((c) => c.name == customerName);
    _controller.add(List.from(MockDb.customers));
  }

  @override
  Future<List<Customer>> getAllCustomers(IconData Function(String?) getIcon) async {
    return List.from(MockDb.customers);
  }
}

class MockDeliveryLogRepository implements DeliveryLogRepository {
  final _controller = StreamController<List<DeliveryLog>>.broadcast();

  MockDeliveryLogRepository() {
    _controller.add(List.from(MockDb.deliveryLogs));
  }

  @override
  Stream<List<DeliveryLog>> getDeliveryLogsStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_controller.isClosed) {
        _controller.add(List.from(MockDb.deliveryLogs));
      } else {
        timer.cancel();
      }
    });
    return _controller.stream;
  }

  @override
  Stream<Map<String, double>> getMonthlyStatsStream() {
    final statsController = StreamController<Map<String, double>>.broadcast();
    statsController.add({});
    return statsController.stream;
  }

  @override
  Future<void> addDeliveryLog(DeliveryLog log) async {
    MockDb.deliveryLogs.add(log);
    _controller.add(List.from(MockDb.deliveryLogs));
  }

  @override
  Future<void> updateDeliveryLog(String logId, Map<String, dynamic> data) async {
    final serial = int.tryParse(logId);
    if (serial != null) {
      final idx = MockDb.deliveryLogs.indexWhere((l) => l.serialNo == serial);
      if (idx != -1) {
        final current = MockDb.deliveryLogs[idx];
        MockDb.deliveryLogs[idx] = DeliveryLog(
          serialNo: current.serialNo,
          customerName: data['customerName'] ?? current.customerName,
          itemName: data['itemName'] ?? current.itemName,
          amount: (data['amount'] as num?)?.toDouble() ?? current.amount,
          isPaid: data['isPaid'] ?? current.isPaid,
          isPayment: data['isPayment'] ?? current.isPayment,
          associatedBagId: data['associatedBagId'] ?? current.associatedBagId,
          dateTime: current.dateTime,
          date: current.date,
        );
      }
    }
    _controller.add(List.from(MockDb.deliveryLogs));
  }

  @override
  Future<void> deleteDeliveryLog(String logId) async {
    final serial = int.tryParse(logId);
    if (serial != null) {
      MockDb.deliveryLogs.removeWhere((l) => l.serialNo == serial);
    }
    _controller.add(List.from(MockDb.deliveryLogs));
  }

  @override
  Future<List<DeliveryLog>> getLogsForCustomer(String customerName) async {
    return MockDb.deliveryLogs.where((l) => l.customerName.toLowerCase() == customerName.toLowerCase()).toList();
  }

  @override
  Future<List<DeliveryLog>> getAllLogs() async {
    return List.from(MockDb.deliveryLogs);
  }

  @override
  Future<void> deleteLogBySerialNo(int serialNo) async {
    MockDb.deliveryLogs.removeWhere((l) => l.serialNo == serialNo);
    _controller.add(List.from(MockDb.deliveryLogs));
  }

  @override
  Future<void> updateLogBySerialNo(int serialNo, String newDetails, double newAmount) async {
    final idx = MockDb.deliveryLogs.indexWhere((l) => l.serialNo == serialNo);
    if (idx != -1) {
      final current = MockDb.deliveryLogs[idx];
      MockDb.deliveryLogs[idx] = DeliveryLog(
        serialNo: current.serialNo,
        customerName: current.customerName,
        itemName: newDetails,
        amount: newAmount,
        isPaid: current.isPaid,
        isPayment: current.isPayment,
        associatedBagId: current.associatedBagId,
        dateTime: current.dateTime,
        date: current.date,
      );
    }
    _controller.add(List.from(MockDb.deliveryLogs));
  }

  @override
  Future<void> purgeLogsOlderThan(DateTime date) async {
    // No-op in mock sandbox
  }
}

class MockExpenseRepository implements ExpenseRepository {
  final _controller = StreamController<List<ExpenseLog>>.broadcast();

  MockExpenseRepository() {
    _controller.add(List.from(MockDb.expenses));
  }

  @override
  Stream<List<ExpenseLog>> getExpensesStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_controller.isClosed) {
        _controller.add(List.from(MockDb.expenses));
      } else {
        timer.cancel();
      }
    });
    return _controller.stream;
  }

  @override
  Future<void> addExpense(ExpenseLog expense) async {
    MockDb.expenses.add(expense);
    _controller.add(List.from(MockDb.expenses));
  }

  @override
  Future<void> updateExpense(String expenseId, String itemName, double amount) async {
    final idx = MockDb.expenses.indexWhere((e) => e.expenseId == expenseId);
    if (idx != -1) {
      final current = MockDb.expenses[idx];
      MockDb.expenses[idx] = ExpenseLog(
        expenseId: current.expenseId,
        amount: amount,
        itemName: itemName,
        category: current.category,
        associatedBagId: current.associatedBagId,
        date: current.date,
      );
    }
    _controller.add(List.from(MockDb.expenses));
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    MockDb.expenses.removeWhere((e) => e.expenseId == expenseId);
    _controller.add(List.from(MockDb.expenses));
  }

  @override
  Future<List<ExpenseLog>> getAllExpenses() async {
    return List.from(MockDb.expenses);
  }
}

class MockRiceBagRepository implements RiceBagRepository {
  final _bagsController = StreamController<List<RiceBag>>.broadcast();
  final _usagesController = StreamController<List<DailyUsage>>.broadcast();

  MockRiceBagRepository() {
    _bagsController.add(List.from(MockDb.riceBags));
    _usagesController.add(List.from(MockDb.dailyUsages));
  }

  @override
  Stream<List<RiceBag>> getRiceBagsStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_bagsController.isClosed) {
        _bagsController.add(List.from(MockDb.riceBags));
      } else {
        timer.cancel();
      }
    });
    return _bagsController.stream;
  }

  @override
  Stream<List<DailyUsage>> getDailyUsagesStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_usagesController.isClosed) {
        _usagesController.add(List.from(MockDb.dailyUsages));
      } else {
        timer.cancel();
      }
    });
    return _usagesController.stream;
  }

  @override
  Future<void> saveRiceBag(RiceBag bag) async {
    final idx = MockDb.riceBags.indexWhere((b) => b.bagId == bag.bagId);
    if (idx != -1) {
      MockDb.riceBags[idx] = bag;
    } else {
      MockDb.riceBags.add(bag);
    }
    _bagsController.add(List.from(MockDb.riceBags));
  }

  @override
  Future<void> updateRiceBag(String bagId, Map<String, dynamic> data) async {
    final idx = MockDb.riceBags.indexWhere((b) => b.bagId == bagId);
    if (idx != -1) {
      final current = MockDb.riceBags[idx];
      MockDb.riceBags[idx] = current.copyWith(
        status: data['status'] ?? current.status,
        revenue: (data['revenue'] as num?)?.toDouble() ?? current.revenue,
        expenses: (data['expenses'] as num?)?.toDouble() ?? current.expenses,
        profit: (data['profit'] as num?)?.toDouble() ?? current.profit,
        profitMargin: (data['profitMargin'] as num?)?.toDouble() ?? current.profitMargin,
        endDate: data['endDate'] ?? current.endDate,
      );
    }
    _bagsController.add(List.from(MockDb.riceBags));
  }

  @override
  Future<void> addDailyUsage(DailyUsage usage) async {
    MockDb.dailyUsages.add(usage);
    _usagesController.add(List.from(MockDb.dailyUsages));
  }

  @override
  Future<List<RiceBag>> getAllRiceBags() async {
    return List.from(MockDb.riceBags);
  }
}

class MockSettingsRepository implements SettingsRepository {
  final _urlController = StreamController<String>.broadcast();
  final _suggestionsController = StreamController<List<String>>.broadcast();

  MockSettingsRepository() {
    _urlController.add(MockDb.googleSheetsUrl);
    _suggestionsController.add(List.from(MockDb.expenseSuggestions));
  }

  @override
  Stream<String> getGoogleSheetsUrlStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_urlController.isClosed) {
        _urlController.add(MockDb.googleSheetsUrl);
      } else {
        timer.cancel();
      }
    });
    return _urlController.stream;
  }

  @override
  Future<void> updateGoogleSheetsUrl(String url) async {
    MockDb.googleSheetsUrl = url;
    _urlController.add(MockDb.googleSheetsUrl);
  }

  @override
  Stream<List<String>> getExpenseSuggestionsStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_suggestionsController.isClosed) {
        _suggestionsController.add(List.from(MockDb.expenseSuggestions));
      } else {
        timer.cancel();
      }
    });
    return _suggestionsController.stream;
  }

  @override
  Future<void> updateExpenseSuggestions(List<String> suggestions) async {
    MockDb.expenseSuggestions = suggestions;
    _suggestionsController.add(List.from(MockDb.expenseSuggestions));
  }
}

class MockOwnerFinanceRepository implements OwnerFinanceRepository {
  final _loanController = StreamController<OwnerLoanConfig?>.broadcast();
  final _repaymentsController = StreamController<List<RepaymentLog>>.broadcast();
  final _savingsLogsController = StreamController<List<SavingsLog>>.broadcast();
  final _recsController = StreamController<SavingsRecommendation?>.broadcast();

  MockOwnerFinanceRepository() {
    _loanController.add(MockDb.loanConfig);
    _repaymentsController.add(List.from(MockDb.repayments));
    _savingsLogsController.add(List.from(MockDb.savingsLogs));
  }

  @override
  Stream<OwnerLoanConfig?> getActiveLoanStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_loanController.isClosed) {
        _loanController.add(MockDb.loanConfig);
      } else {
        timer.cancel();
      }
    });
    return _loanController.stream;
  }

  @override
  Future<void> updateNotes(String loanId, String notes) async {
    MockDb.loanConfig = OwnerLoanConfig(
      id: MockDb.loanConfig.id,
      description: MockDb.loanConfig.description,
      totalBorrowed: MockDb.loanConfig.totalBorrowed,
      amountRepaid: MockDb.loanConfig.amountRepaid,
      notes: notes,
      createdAt: MockDb.loanConfig.createdAt,
    );
    _loanController.add(MockDb.loanConfig);
  }

  @override
  Future<void> addRepayment(String loanId, RepaymentLog repayment) async {
    MockDb.repayments.add(repayment);
    MockDb.loanConfig = OwnerLoanConfig(
      id: MockDb.loanConfig.id,
      description: MockDb.loanConfig.description,
      totalBorrowed: MockDb.loanConfig.totalBorrowed,
      amountRepaid: MockDb.loanConfig.amountRepaid + repayment.amountPaid,
      notes: MockDb.loanConfig.notes,
      createdAt: MockDb.loanConfig.createdAt,
    );
    _repaymentsController.add(List.from(MockDb.repayments));
    _loanController.add(MockDb.loanConfig);
  }

  @override
  Future<void> updateTotalBorrowed(String loanId, double totalBorrowed) async {
    MockDb.loanConfig = OwnerLoanConfig(
      id: MockDb.loanConfig.id,
      description: MockDb.loanConfig.description,
      totalBorrowed: totalBorrowed,
      amountRepaid: MockDb.loanConfig.amountRepaid,
      notes: MockDb.loanConfig.notes,
      createdAt: MockDb.loanConfig.createdAt,
    );
    _loanController.add(MockDb.loanConfig);
  }

  @override
  Stream<List<RepaymentLog>> getRepaymentsStream(String loanId) {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_repaymentsController.isClosed) {
        _repaymentsController.add(List.from(MockDb.repayments));
      } else {
        timer.cancel();
      }
    });
    return _repaymentsController.stream;
  }

  @override
  Future<void> initDefaultLoanConfigIfEmpty() async {
    // Always initialized
  }

  @override
  Future<OwnerLoanConfig?> getActiveLoan() async {
    return MockDb.loanConfig;
  }

  @override
  Future<List<RepaymentLog>> getRepayments(String loanId) async {
    return List.from(MockDb.repayments);
  }

  @override
  Stream<List<SavingsLog>> getSavingsLogsStream() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_savingsLogsController.isClosed) {
        _savingsLogsController.add(List.from(MockDb.savingsLogs));
      } else {
        timer.cancel();
      }
    });
    return _savingsLogsController.stream;
  }

  @override
  Future<void> addSavingsLog(SavingsLog log) async {
    MockDb.savingsLogs.add(log);
    _savingsLogsController.add(List.from(MockDb.savingsLogs));
  }

  @override
  Stream<SavingsRecommendation?> getPendingSavingsRecommendationStream(String date) {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_recsController.isClosed) {
        final rec = MockDb.savingsRecommendations.firstWhere(
          (r) => r.date == date && r.status == 'pending',
          orElse: () => SavingsRecommendation(date: date, suggestedSavings: 0, conversationalReason: "", status: "skipped"),
        );
        if (rec.status == 'pending') {
          _recsController.add(rec);
        } else {
          _recsController.add(null);
        }
      } else {
        timer.cancel();
      }
    });
    return _recsController.stream;
  }

  @override
  Future<void> updateSavingsRecommendationStatus(String date, String status, int? transferredAmount) async {
    final idx = MockDb.savingsRecommendations.indexWhere((r) => r.date == date);
    if (idx != -1) {
      final current = MockDb.savingsRecommendations[idx];
      MockDb.savingsRecommendations[idx] = SavingsRecommendation(
        date: current.date,
        suggestedSavings: current.suggestedSavings,
        conversationalReason: current.conversationalReason,
        status: status,
      );
    }
  }
}
