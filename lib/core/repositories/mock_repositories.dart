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

Stream<T> _createMockStream<T>(StreamController<T> controller, T Function() getValue) {
  controller.onListen = () {
    Future.microtask(() {
      if (!controller.isClosed) {
        controller.add(getValue());
      }
    });
  };
  return controller.stream;
}

class MockDb {
  static final Map<String, List<Customer>> _customersMap = {
    'business_1': [
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
      Customer(
        name: "Milk",
        outstanding: 0.0,
        type: "RETAIL",
        area: "Dairy Circle",
        icon: Icons.local_cafe,
        location: "Dairy Circle, 2nd Cross",
      ),
    ],
    'business_2': [
      Customer(
        name: "Dummy Customer A (Business 2)",
        outstanding: 500.0,
        type: "RETAIL",
        area: "West End",
        icon: Icons.person,
        location: "West End Boulevard",
      ),
    ],
  };

  static final Map<String, List<DeliveryLog>> _deliveryLogsMap = {
    'business_1': [
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
    ],
    'business_2': [
      DeliveryLog(
        serialNo: 2001,
        customerName: "Dummy Customer A (Business 2)",
        itemName: "Nippat",
        amount: 500.0,
        isPaid: false,
        isPayment: false,
        associatedBagId: "BAG_BIZ2_1",
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        date: "12 Jun 2026",
      ),
    ],
  };

  static final Map<String, List<ExpenseLog>> _expensesMap = {
    'business_1': [
      ExpenseLog(
        expenseId: "EXP_1",
        amount: 150.0,
        itemName: "Diesel",
        category: "Fuel",
        associatedBagId: "BAG_1",
        date: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
      ),
    ],
    'business_2': [
      ExpenseLog(
        expenseId: "EXP_BIZ2_1",
        amount: 200.0,
        itemName: "Rent for Shop",
        category: "Rent",
        associatedBagId: "BAG_BIZ2_1",
        date: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
      ),
    ],
  };

  static final Map<String, List<RiceBag>> _riceBagsMap = {
    'business_1': [
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
    ],
    'business_2': [
      RiceBag(
        bagId: "BAG_BIZ2_1",
        bagNumber: 1,
        status: "Active",
        revenue: 500.0,
        expenses: 200.0,
        profit: 300.0,
        profitMargin: 60.0,
        startDate: "12 Jun 2026",
        endDate: "",
        totalKg: 10.0,
        remainingKg: 10.0,
        cost: 400.0,
      ),
    ],
  };

  static final Map<String, List<DailyUsage>> _dailyUsagesMap = {
    'business_1': [],
    'business_2': [],
  };

  static final Map<String, String> _googleSheetsUrlMap = {
    'business_1': "https://script.google.com/macros/s/dummy/exec",
    'business_2': "https://script.google.com/macros/s/dummy_biz2/exec",
  };

  static final Map<String, List<String>> _expenseSuggestionsMap = {
    'business_1': ["Diesel", "Labor", "Meals", "Repairs"],
    'business_2': ["Fuel", "Rent", "Salary"],
  };

  static final Map<String, OwnerLoanConfig> _loanConfigMap = {
    'business_1': OwnerLoanConfig(
      id: "default_owner_loan",
      description: "Owner Capital Fund",
      totalBorrowed: 50000.0,
      amountRepaid: 15000.0,
      notes: "Sandbox owner fund tracking notes.",
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    'business_2': OwnerLoanConfig(
      id: "default_owner_loan",
      description: "Owner Capital Fund (Biz 2)",
      totalBorrowed: 10000.0,
      amountRepaid: 0.0,
      notes: "Sandbox owner fund tracking notes for Business 2.",
      createdAt: DateTime.now(),
    ),
  };

  static final Map<String, List<RepaymentLog>> _repaymentsMap = {
    'business_1': [
      RepaymentLog(
        id: "REP_1",
        amountPaid: 15000.0,
        repaymentDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ],
    'business_2': [],
  };

  static final Map<String, List<SavingsLog>> _savingsLogsMap = {
    'business_1': [
      SavingsLog(
        id: "SAV_1",
        amount: 1000.0,
        type: "deposit",
        notes: "Initial sandbox savings log",
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
    'business_2': [],
  };

  static final Map<String, List<SavingsRecommendation>> _savingsRecommendationsMap = {
    'business_1': [],
    'business_2': [],
  };

  static List<Customer> getCustomers(String businessId) =>
      _customersMap.putIfAbsent(businessId, () => []);

  static List<DeliveryLog> getDeliveryLogs(String businessId) =>
      _deliveryLogsMap.putIfAbsent(businessId, () => []);

  static List<ExpenseLog> getExpenses(String businessId) =>
      _expensesMap.putIfAbsent(businessId, () => []);

  static List<RiceBag> getRiceBags(String businessId) =>
      _riceBagsMap.putIfAbsent(businessId, () => []);

  static List<DailyUsage> getDailyUsages(String businessId) =>
      _dailyUsagesMap.putIfAbsent(businessId, () => []);

  static String getGoogleSheetsUrl(String businessId) =>
      _googleSheetsUrlMap[businessId] ?? '';

  static void setGoogleSheetsUrl(String businessId, String url) =>
      _googleSheetsUrlMap[businessId] = url;

  static List<String> getExpenseSuggestions(String businessId) =>
      _expenseSuggestionsMap.putIfAbsent(businessId, () => []);

  static void setExpenseSuggestions(String businessId, List<String> suggs) =>
      _expenseSuggestionsMap[businessId] = suggs;

  static OwnerLoanConfig getLoanConfig(String businessId) =>
      _loanConfigMap.putIfAbsent(
          businessId,
          () => OwnerLoanConfig(
              id: "default_owner_loan",
              description: "Owner Capital Fund",
              totalBorrowed: 0.0,
              amountRepaid: 0.0,
              notes: "",
              createdAt: DateTime.now()));

  static void setLoanConfig(String businessId, OwnerLoanConfig config) =>
      _loanConfigMap[businessId] = config;

  static List<RepaymentLog> getRepayments(String businessId) =>
      _repaymentsMap.putIfAbsent(businessId, () => []);

  static List<SavingsLog> getSavingsLogs(String businessId) =>
      _savingsLogsMap.putIfAbsent(businessId, () => []);

  static List<SavingsRecommendation> getSavingsRecommendations(String businessId) =>
      _savingsRecommendationsMap.putIfAbsent(businessId, () => []);
}

class MockCustomerRepository implements CustomerRepository {
  final String businessId;
  final _controller = StreamController<List<Customer>>.broadcast();

  MockCustomerRepository({required this.businessId}) {
    _controller.add(List.from(MockDb.getCustomers(businessId)));
  }

  @override
  Stream<List<Customer>> getCustomersStream(IconData Function(String?) getIcon) {
    return _createMockStream(_controller, () => List.from(MockDb.getCustomers(businessId)));
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    MockDb.getCustomers(businessId).add(customer);
    _controller.add(List.from(MockDb.getCustomers(businessId)));
  }

  @override
  Future<void> updateCustomerOutstanding(String customerName, double amount) async {
    final list = MockDb.getCustomers(businessId);
    for (int i = 0; i < list.length; i++) {
      if (list[i].name.toLowerCase() == customerName.toLowerCase()) {
        list[i] = list[i].copyWith(outstanding: amount);
      }
    }
    _controller.add(List.from(list));
  }

  @override
  Future<void> saveCustomer(Customer customer) async {
    final list = MockDb.getCustomers(businessId);
    final idx = list.indexWhere((c) => c.name == customer.name);
    if (idx != -1) {
      list[idx] = customer;
    } else {
      list.add(customer);
    }
    _controller.add(List.from(list));
  }

  @override
  Future<void> deleteCustomer(String customerName) async {
    MockDb.getCustomers(businessId).removeWhere((c) => c.name == customerName);
    _controller.add(List.from(MockDb.getCustomers(businessId)));
  }

  @override
  Future<List<Customer>> getAllCustomers(IconData Function(String?) getIcon) async {
    return List.from(MockDb.getCustomers(businessId));
  }
}

class MockDeliveryLogRepository implements DeliveryLogRepository {
  final String businessId;
  final _controller = StreamController<List<DeliveryLog>>.broadcast();

  MockDeliveryLogRepository({required this.businessId}) {
    _controller.add(List.from(MockDb.getDeliveryLogs(businessId)));
  }

  @override
  Stream<List<DeliveryLog>> getDeliveryLogsStream() {
    return _createMockStream(_controller, () => List.from(MockDb.getDeliveryLogs(businessId)));
  }

  @override
  Stream<Map<String, double>> getMonthlyStatsStream() {
    final statsController = StreamController<Map<String, double>>.broadcast();
    statsController.add({});
    return statsController.stream;
  }

  @override
  Future<void> addDeliveryLog(DeliveryLog log) async {
    MockDb.getDeliveryLogs(businessId).add(log);
    _controller.add(List.from(MockDb.getDeliveryLogs(businessId)));
  }

  @override
  Future<void> updateDeliveryLog(String logId, Map<String, dynamic> data) async {
    final serial = int.tryParse(logId);
    if (serial != null) {
      final list = MockDb.getDeliveryLogs(businessId);
      final idx = list.indexWhere((l) => l.serialNo == serial);
      if (idx != -1) {
        final current = list[idx];
        list[idx] = DeliveryLog(
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
    _controller.add(List.from(MockDb.getDeliveryLogs(businessId)));
  }

  @override
  Future<void> deleteDeliveryLog(String logId) async {
    final serial = int.tryParse(logId);
    if (serial != null) {
      MockDb.getDeliveryLogs(businessId).removeWhere((l) => l.serialNo == serial);
    }
    _controller.add(List.from(MockDb.getDeliveryLogs(businessId)));
  }

  @override
  Future<List<DeliveryLog>> getLogsForCustomer(String customerName) async {
    return MockDb.getDeliveryLogs(businessId)
        .where((l) => l.customerName.toLowerCase() == customerName.toLowerCase())
        .toList();
  }

  @override
  Future<List<DeliveryLog>> getAllLogs() async {
    return List.from(MockDb.getDeliveryLogs(businessId));
  }

  @override
  Future<void> deleteLogBySerialNo(int serialNo) async {
    MockDb.getDeliveryLogs(businessId).removeWhere((l) => l.serialNo == serialNo);
    _controller.add(List.from(MockDb.getDeliveryLogs(businessId)));
  }

  @override
  Future<void> updateLogBySerialNo(int serialNo, String newDetails, double newAmount) async {
    final list = MockDb.getDeliveryLogs(businessId);
    final idx = list.indexWhere((l) => l.serialNo == serialNo);
    if (idx != -1) {
      final current = list[idx];
      list[idx] = DeliveryLog(
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
    _controller.add(List.from(list));
  }

  @override
  Future<void> purgeLogsOlderThan(DateTime date) async {
    // No-op in mock sandbox
  }
}

class MockExpenseRepository implements ExpenseRepository {
  final String businessId;
  final _controller = StreamController<List<ExpenseLog>>.broadcast();

  MockExpenseRepository({required this.businessId}) {
    _controller.add(List.from(MockDb.getExpenses(businessId)));
  }

  @override
  Stream<List<ExpenseLog>> getExpensesStream() {
    return _createMockStream(_controller, () => List.from(MockDb.getExpenses(businessId)));
  }

  @override
  Future<void> addExpense(ExpenseLog expense) async {
    MockDb.getExpenses(businessId).add(expense);
    _controller.add(List.from(MockDb.getExpenses(businessId)));
  }

  @override
  Future<void> updateExpense(String expenseId, String itemName, double amount) async {
    final list = MockDb.getExpenses(businessId);
    final idx = list.indexWhere((e) => e.expenseId == expenseId);
    if (idx != -1) {
      final current = list[idx];
      list[idx] = ExpenseLog(
        expenseId: current.expenseId,
        amount: amount,
        itemName: itemName,
        category: current.category,
        associatedBagId: current.associatedBagId,
        date: current.date,
      );
    }
    _controller.add(List.from(list));
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    MockDb.getExpenses(businessId).removeWhere((e) => e.expenseId == expenseId);
    _controller.add(List.from(MockDb.getExpenses(businessId)));
  }

  @override
  Future<List<ExpenseLog>> getAllExpenses() async {
    return List.from(MockDb.getExpenses(businessId));
  }
}

class MockRiceBagRepository implements RiceBagRepository {
  final String businessId;
  final _bagsController = StreamController<List<RiceBag>>.broadcast();
  final _usagesController = StreamController<List<DailyUsage>>.broadcast();

  MockRiceBagRepository({required this.businessId}) {
    _bagsController.add(List.from(MockDb.getRiceBags(businessId)));
    _usagesController.add(List.from(MockDb.getDailyUsages(businessId)));
  }

  @override
  Stream<List<RiceBag>> getRiceBagsStream() {
    return _createMockStream(_bagsController, () => List.from(MockDb.getRiceBags(businessId)));
  }

  @override
  Stream<List<DailyUsage>> getDailyUsagesStream() {
    return _createMockStream(_usagesController, () => List.from(MockDb.getDailyUsages(businessId)));
  }

  @override
  Future<void> saveRiceBag(RiceBag bag) async {
    final list = MockDb.getRiceBags(businessId);
    final idx = list.indexWhere((b) => b.bagId == bag.bagId);
    if (idx != -1) {
      list[idx] = bag;
    } else {
      list.add(bag);
    }
    _bagsController.add(List.from(list));
  }

  @override
  Future<void> updateRiceBag(String bagId, Map<String, dynamic> data) async {
    final list = MockDb.getRiceBags(businessId);
    final idx = list.indexWhere((b) => b.bagId == bagId);
    if (idx != -1) {
      final current = list[idx];
      list[idx] = current.copyWith(
        status: data['status'] ?? current.status,
        revenue: (data['revenue'] as num?)?.toDouble() ?? current.revenue,
        expenses: (data['expenses'] as num?)?.toDouble() ?? current.expenses,
        profit: (data['profit'] as num?)?.toDouble() ?? current.profit,
        profitMargin: (data['profitMargin'] as num?)?.toDouble() ?? current.profitMargin,
        endDate: data['endDate'] ?? current.endDate,
      );
    }
    _bagsController.add(List.from(list));
  }

  @override
  Future<void> addDailyUsage(DailyUsage usage) async {
    MockDb.getDailyUsages(businessId).add(usage);
    _usagesController.add(List.from(MockDb.getDailyUsages(businessId)));
  }

  @override
  Future<List<RiceBag>> getAllRiceBags() async {
    return List.from(MockDb.getRiceBags(businessId));
  }
}

class MockSettingsRepository implements SettingsRepository {
  final String businessId;
  final _urlController = StreamController<String>.broadcast();
  final _suggestionsController = StreamController<List<String>>.broadcast();

  MockSettingsRepository({required this.businessId}) {
    _urlController.add(MockDb.getGoogleSheetsUrl(businessId));
    _suggestionsController.add(List.from(MockDb.getExpenseSuggestions(businessId)));
  }

  @override
  Stream<String> getGoogleSheetsUrlStream() {
    return _createMockStream(_urlController, () => MockDb.getGoogleSheetsUrl(businessId));
  }

  @override
  Future<void> updateGoogleSheetsUrl(String url) async {
    MockDb.setGoogleSheetsUrl(businessId, url);
    _urlController.add(url);
  }

  @override
  Stream<List<String>> getExpenseSuggestionsStream() {
    return _createMockStream(_suggestionsController, () => List.from(MockDb.getExpenseSuggestions(businessId)));
  }

  @override
  Future<void> updateExpenseSuggestions(List<String> suggestions) async {
    MockDb.setExpenseSuggestions(businessId, suggestions);
    _suggestionsController.add(List.from(suggestions));
  }
}

class MockOwnerFinanceRepository implements OwnerFinanceRepository {
  final String businessId;
  final _loanController = StreamController<OwnerLoanConfig?>.broadcast();
  final _repaymentsController = StreamController<List<RepaymentLog>>.broadcast();
  final _savingsLogsController = StreamController<List<SavingsLog>>.broadcast();
  final _recsController = StreamController<SavingsRecommendation?>.broadcast();

  MockOwnerFinanceRepository({required this.businessId}) {
    _loanController.add(MockDb.getLoanConfig(businessId));
    _repaymentsController.add(List.from(MockDb.getRepayments(businessId)));
    _savingsLogsController.add(List.from(MockDb.getSavingsLogs(businessId)));
  }

  @override
  Stream<OwnerLoanConfig?> getActiveLoanStream() {
    return _createMockStream(_loanController, () => MockDb.getLoanConfig(businessId));
  }

  @override
  Future<void> updateNotes(String loanId, String notes) async {
    final current = MockDb.getLoanConfig(businessId);
    final updated = OwnerLoanConfig(
      id: current.id,
      description: current.description,
      totalBorrowed: current.totalBorrowed,
      amountRepaid: current.amountRepaid,
      notes: notes,
      createdAt: current.createdAt,
    );
    MockDb.setLoanConfig(businessId, updated);
    _loanController.add(updated);
  }

  @override
  Future<void> addRepayment(String loanId, RepaymentLog repayment) async {
    MockDb.getRepayments(businessId).add(repayment);
    final current = MockDb.getLoanConfig(businessId);
    final updated = OwnerLoanConfig(
      id: current.id,
      description: current.description,
      totalBorrowed: current.totalBorrowed,
      amountRepaid: current.amountRepaid + repayment.amountPaid,
      notes: current.notes,
      createdAt: current.createdAt,
    );
    MockDb.setLoanConfig(businessId, updated);
    _repaymentsController.add(List.from(MockDb.getRepayments(businessId)));
    _loanController.add(updated);
  }

  @override
  Future<void> updateTotalBorrowed(String loanId, double totalBorrowed) async {
    final current = MockDb.getLoanConfig(businessId);
    final updated = OwnerLoanConfig(
      id: current.id,
      description: current.description,
      totalBorrowed: totalBorrowed,
      amountRepaid: current.amountRepaid,
      notes: current.notes,
      createdAt: current.createdAt,
    );
    MockDb.setLoanConfig(businessId, updated);
    _loanController.add(updated);
  }

  @override
  Stream<List<RepaymentLog>> getRepaymentsStream(String loanId) {
    return _createMockStream(_repaymentsController, () => List.from(MockDb.getRepayments(businessId)));
  }

  @override
  Future<void> initDefaultLoanConfigIfEmpty() async {
    // Always initialized
  }

  @override
  Future<OwnerLoanConfig?> getActiveLoan() async {
    return MockDb.getLoanConfig(businessId);
  }

  @override
  Future<List<RepaymentLog>> getRepayments(String loanId) async {
    return List.from(MockDb.getRepayments(businessId));
  }

  @override
  Stream<List<SavingsLog>> getSavingsLogsStream() {
    return _createMockStream(_savingsLogsController, () => List.from(MockDb.getSavingsLogs(businessId)));
  }

  @override
  Future<void> addSavingsLog(SavingsLog log) async {
    MockDb.getSavingsLogs(businessId).add(log);
    _savingsLogsController.add(List.from(MockDb.getSavingsLogs(businessId)));
  }

  @override
  Stream<SavingsRecommendation?> getPendingSavingsRecommendationStream(String date) {
    return _createMockStream(_recsController, () {
      final list = MockDb.getSavingsRecommendations(businessId);
      final rec = list.firstWhere(
        (r) => r.date == date && r.status == 'pending',
        orElse: () => SavingsRecommendation(date: date, suggestedSavings: 0, conversationalReason: "", status: "skipped"),
      );
      return rec.status == 'pending' ? rec : null;
    });
  }

  @override
  Future<void> updateSavingsRecommendationStatus(String date, String status, int? transferredAmount) async {
    final list = MockDb.getSavingsRecommendations(businessId);
    final idx = list.indexWhere((r) => r.date == date);
    if (idx != -1) {
      final current = list[idx];
      list[idx] = SavingsRecommendation(
        date: current.date,
        suggestedSavings: current.suggestedSavings,
        conversationalReason: current.conversationalReason,
        status: status,
      );
    }
  }
}
