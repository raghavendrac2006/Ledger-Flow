import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import 'models/customer.dart';
import 'models/transaction.dart';
import 'models/delivery_log.dart';
import 'models/expense_log.dart';
import 'models/rice_bag.dart';
import 'models/daily_usage.dart';

import 'repositories/customer_repository.dart';
import 'repositories/delivery_log_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/rice_bag_repository.dart';
import 'repositories/settings_repository.dart';
import 'package:ledgerflow/core/models/owner_finance_model.dart';
import 'package:ledgerflow/core/repositories/owner_finance_repository.dart';

String toSentenceCase(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.length == 1) return trimmed.toUpperCase();
  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}

class LedgerState extends ChangeNotifier {
  final String businessId;
  final Function(String) onBusinessChanged;
  final CustomerRepository customerRepository;
  final DeliveryLogRepository deliveryLogRepository;
  final ExpenseRepository expenseRepository;
  final RiceBagRepository riceBagRepository;
  final SettingsRepository settingsRepository;
  final OwnerFinanceRepository ownerFinanceRepository;
  final bool isMockMode;

  LedgerState({
    required this.businessId,
    required this.onBusinessChanged,
    required this.customerRepository,
    required this.deliveryLogRepository,
    required this.expenseRepository,
    required this.riceBagRepository,
    required this.settingsRepository,
    required this.ownerFinanceRepository,
    this.isMockMode = false,
  }) {
    _initFirestore();
    runSentenceCaseMigration();
    // Safety timer to prevent getting stuck in loading state forever
    Timer(const Duration(seconds: 4), () {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  String _getCollectionPath(String collectionName) {
    if (businessId == 'business_1') {
      return collectionName;
    } else {
      return 'businesses/$businessId/$collectionName';
    }
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  final Set<String> _loadedStreams = {};

  void _onStreamLoaded(String streamName) {
    if (_isLoading) {
      _loadedStreams.add(streamName);
      if (_loadedStreams.containsAll(['customers', 'logs', 'expenses', 'bags', 'usages'])) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Firestore stream subscriptions
  StreamSubscription? _customersSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _bagsSub;
  StreamSubscription? _usagesSub;
  StreamSubscription? _statsSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _expenseSuggestionsSub;
  StreamSubscription? _ownerLoanSub;
  StreamSubscription? _ownerRepaymentsSub;
  StreamSubscription? _savingsLogsSub;
  StreamSubscription? _savingsRecommendationSub;
  SavingsRecommendation? _pendingRecommendation;
  SavingsRecommendation? get pendingRecommendation => _pendingRecommendation;

  final Map<String, double> _historicalMonthlySales = {};

  OwnerLoanConfig? _activeLoan;
  OwnerLoanConfig? get activeLoan => _activeLoan;

  final List<RepaymentLog> _repaymentLogs = [];
  List<RepaymentLog> get repaymentLogs => _repaymentLogs;

  final List<SavingsLog> _savingsLogs = [];
  List<SavingsLog> get savingsLogs => _savingsLogs;

  double get totalSavings {
    return _savingsLogs.fold(0.0, (accumulated, log) => accumulated + log.amount);
  }

  void _initFirestore() {
    debugPrint("--- INITIALIZING REAL-TIME CLOUD FIRESTORE ---");

    ownerFinanceRepository.initDefaultLoanConfigIfEmpty().then((_) {
      _ownerLoanSub = ownerFinanceRepository.getActiveLoanStream().listen(
        (loan) {
          _activeLoan = loan;
          notifyListeners();
          
          if (loan != null) {
            _ownerRepaymentsSub?.cancel();
            _ownerRepaymentsSub = ownerFinanceRepository.getRepaymentsStream(loan.id).listen(
              (repayments) {
                _repaymentLogs.clear();
                _repaymentLogs.addAll(repayments);
                notifyListeners();
              },
              onError: (error) {
                debugPrint("Firestore owner repayments stream error: $error");
              }
            );
          }
        },
        onError: (error) {
          debugPrint("Firestore owner loan stream error: $error");
        }
      );

      _savingsLogsSub = ownerFinanceRepository.getSavingsLogsStream().listen(
        (logs) {
          _savingsLogs.clear();
          _savingsLogs.addAll(logs);
          notifyListeners();
        },
        onError: (error) {
          debugPrint("Firestore savings logs stream error: $error");
        }
      );
    });

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayDateStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    _savingsRecommendationSub = ownerFinanceRepository
        .getPendingSavingsRecommendationStream(yesterdayDateStr)
        .listen(
      (recommendation) {
        _pendingRecommendation = recommendation;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore savings recommendations stream error: $error");
      }
    );

    _checkAndGenerateSavingsRecommendation(yesterdayDateStr);


    // 1. Seed Default Customers if Database is empty
    _seedDefaultCustomers();

    // 2. Run background 3-month auto-purge of old logs (while keeping monthly totals)
    runAutoPurge();

    // 3. Listen to Customers Collection
    _customersSub = customerRepository.getCustomersStream(_getCustomerIcon).listen(
      (snapshot) {
        _customers.clear();
        _customers.addAll(snapshot);
        _onStreamLoaded('customers');
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore customers stream error: $error");
        _onStreamLoaded('customers'); // don't block load on errors
      }
    );

    // 4. Listen to Delivery Logs Collection (Sorted locally in memory)
    _logsSub = deliveryLogRepository.getDeliveryLogsStream().listen(
      (snapshot) {
        _deliveryLogs.clear();
        _customerTransactions.clear();

        int maxSerial = 1000;

        for (var log in snapshot) {
          if (log.serialNo > maxSerial) {
            maxSerial = log.serialNo;
          }
          _deliveryLogs.add(log);
        }

        // Sort in memory by dateTime descending
        _deliveryLogs.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Rebuild customer transaction lists based on sorted logs
        for (var log in _deliveryLogs) {
          if (!_customerTransactions.containsKey(log.customerName)) {
            _customerTransactions[log.customerName] = [];
          }
          _customerTransactions[log.customerName]!.add(Transaction(
            date: log.date.toUpperCase(),
            details: log.isPayment ? log.itemName : "1x ${log.itemName}",
            amount: log.amount,
            isPaid: log.isPaid,
            isPayment: log.isPayment,
          ));
        }

        // Self-healing serial number
        _serialNumber = maxSerial + 1;
        _onStreamLoaded('logs');
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore deliveryLogs stream error: $error");
        _onStreamLoaded('logs');
      }
    );

    // 5. Listen to Expenses Collection (Sorted locally in memory)
    _expensesSub = expenseRepository.getExpensesStream().listen(
      (snapshot) {
        _expenses.clear();
        _expenses.addAll(snapshot);
        // Sort in memory by date descending
        _expenses.sort((a, b) => b.date.compareTo(a.date));
        _onStreamLoaded('expenses');
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore expenses stream error: $error");
        _onStreamLoaded('expenses');
      }
    );

    // 6. Listen to Rice Bags Collection (Sorted locally in memory)
    _bagsSub = riceBagRepository.getRiceBagsStream().listen(
      (snapshot) {
        _riceBags.clear();
        _riceBags.addAll(snapshot);
        // Sort in memory by startDate descending
        _riceBags.sort((a, b) => b.startDate.compareTo(a.startDate));
        _onStreamLoaded('bags');
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore riceBags stream error: $error");
        _onStreamLoaded('bags');
      }
    );

    // 7. Listen to Daily Usages Collection
    _usagesSub = riceBagRepository.getDailyUsagesStream().listen(
      (snapshot) {
        _dailyUsages.clear();
        _dailyUsages.addAll(snapshot);
        _onStreamLoaded('usages');
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore dailyUsages stream error: $error");
        _onStreamLoaded('usages');
      }
    );

    // 8. Listen to Historical Monthly Sales aggregates
    _statsSub = deliveryLogRepository.getMonthlyStatsStream().listen(
      (snapshot) {
        _historicalMonthlySales.clear();
        _historicalMonthlySales.addAll(snapshot);
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore monthlyStats stream error: $error");
      }
    );

    // 9. Listen to Settings Collection (specifically the googleSheets document)
    _settingsSub = settingsRepository.getGoogleSheetsUrlStream().listen(
      (url) async {
        if (url.isNotEmpty) {
          _googleSheetsUrl = url;
          notifyListeners();
        } else {
          // Document does not exist yet. Seed it with the default URL.
          try {
            await settingsRepository.updateGoogleSheetsUrl(_googleSheetsUrl);
          } catch (e) {
            debugPrint("Failed to seed default settings URL: $e");
          }
        }
      },
      onError: (error) {
        debugPrint("Firestore settings stream error: $error");
      }
    );

    // 10. Listen to Expense Suggestions list document
    _expenseSuggestionsSub = settingsRepository.getExpenseSuggestionsStream().listen(
      (list) async {
        if (list.isNotEmpty) {
          _expenseSuggestions = list;
          notifyListeners();
        } else {
          // Document does not exist yet. Seed it with the default items list.
          final defaultItems = [
            "Gas Cylinder Commercial",
            "Gas Cylinder Domestic",
            "Petrol for Scooter",
            "Diesel for Auto",
            "Salt bag",
            "Vehicle Repair",
            "Delivery Box Roll",
            "Thread pack",
          ];
          try {
            await settingsRepository.updateExpenseSuggestions(defaultItems);
          } catch (e) {
            debugPrint("Failed to seed default expense items: $e");
          }
        }
      },
      onError: (error) {
        debugPrint("Firestore expenseItems stream error: $error");
      }
    );
  }

  // Clean default seeding data to avoid empty screens initially
  Future<void> _seedDefaultCustomers() async {
    final list = await customerRepository.getAllCustomers(_getCustomerIcon);
    if (list.isEmpty) {
      debugPrint("Database empty. Seeding default customers...");
      final defaultList = [
        {"name": "Ramchandra", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Lachy", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Bava", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Santosh", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Murali pes", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Supermarket pes", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Bakery pes", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Down shop pes", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Milk", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Lakshmi puram", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "showkath", "type": "", "area": "", "outstanding": 0.0, "location": ""},
        {"name": "Factory", "type": "", "area": "", "outstanding": 0.0, "location": ""},
      ];

      for (var c in defaultList) {
        await customerRepository.addCustomer(Customer(
          name: c['name'] as String,
          type: c['type'] as String,
          area: c['area'] as String,
          outstanding: c['outstanding'] as double,
          icon: _getCustomerIcon(c['type'] as String),
          location: c['location'] as String,
        ));
      }
    }
  }

  // 3-Month Auto-Purge Retention
  Future<void> runAutoPurge() async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      await deliveryLogRepository.purgeLogsOlderThan(ninetyDaysAgo);
    } catch (e) {
      debugPrint("Auto-purge failed: $e");
    }
  }

  // Getters for dynamic Revenue Section
  Map<String, double> get _revenueByDate {
    final Map<String, double> map = {};
    for (var log in _deliveryLogs) {
      if (!log.isPayment) {
        final dateKey = DateFormat('yyyy-MM-dd').format(log.dateTime);
        map[dateKey] = (map[dateKey] ?? 0.0) + log.amount;
      }
    }
    return map;
  }

  List<String> get _sortedActiveDates {
    final map = _revenueByDate;
    return map.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  double get latestActiveRevenue {
    final dates = _sortedActiveDates;
    if (dates.isEmpty) return 0.0;
    return _revenueByDate[dates.first] ?? 0.0;
  }

  double get previousActiveRevenue {
    final dates = _sortedActiveDates;
    if (dates.length < 2) return 0.0;
    return _revenueByDate[dates[1]] ?? 0.0;
  }

  String get latestActiveDateLabel {
    final dates = _sortedActiveDates;
    if (dates.isEmpty) return "Today";
    return _formatFriendlyDateLabel(dates.first);
  }

  String get previousActiveDateLabel {
    final dates = _sortedActiveDates;
    if (dates.length < 2) return "Yesterday";
    return _formatFriendlyDateLabel(dates[1]);
  }

  String _formatFriendlyDateLabel(String dateStr) {
    try {
      final parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final compareDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      
      if (compareDate == today) {
        return "Today";
      } else if (compareDate == yesterday) {
        return "Yesterday";
      } else {
        return DateFormat('d MMM').format(compareDate);
      }
    } catch (_) {
      return dateStr;
    }
  }

  int get latestActiveDeliveriesCount {
    final dates = _sortedActiveDates;
    if (dates.isEmpty) return 0;
    final latestDateStr = dates.first;
    return _deliveryLogs.where((l) {
      if (l.isPayment) return false;
      final logDateStr = DateFormat('yyyy-MM-dd').format(l.dateTime);
      return logDateStr == latestDateStr;
    }).length;
  }

  List<String> get lastThreeActiveDates {
    final Set<String> dates = {};
    for (var log in _deliveryLogs) {
      dates.add(DateFormat('yyyy-MM-dd').format(log.dateTime));
    }
    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
    return sorted.length > 3 ? sorted.sublist(0, 3) : sorted;
  }

  List<DeliveryLog> get filteredDeliveryLogsForSummary {
    final activeDates = lastThreeActiveDates;
    return _deliveryLogs.where((log) {
      final dateStr = DateFormat('yyyy-MM-dd').format(log.dateTime);
      return activeDates.contains(dateStr);
    }).toList();
  }

  // Helper method to assign proper category icons
  IconData _getCustomerIcon(String? type) {
    switch (type?.toUpperCase()) {
      case "RETAIL":
        return Icons.person;
      case "WHOLESALE":
        return Icons.shopping_cart;
      case "CORPORATE":
        return Icons.business;
      case "MINI-MART":
        return Icons.store;
      case "BAKERY":
        return Icons.bakery_dining;
      case "DISTRIBUTION":
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }

  @override
  void dispose() {
    _customersSub?.cancel();
    _logsSub?.cancel();
    _expensesSub?.cancel();
    _bagsSub?.cancel();
    _usagesSub?.cancel();
    _statsSub?.cancel();
    _settingsSub?.cancel();
    _expenseSuggestionsSub?.cancel();
    _ownerLoanSub?.cancel();
    _ownerRepaymentsSub?.cancel();
    _savingsLogsSub?.cancel();
    _savingsRecommendationSub?.cancel();
    super.dispose();
  }

  // 1. Setup State
  DateTime _deliveryDate = DateTime.now();
  DateTime get deliveryDate => _deliveryDate;
  
  void setDeliveryDate(DateTime date) {
    _deliveryDate = date;
    notifyListeners();
  }

  final List<Map<String, dynamic>> _setupItems = [
    {
      "name": "1 ₹ Chakli",
      "subtitle": "Standard Bag",
      "icon": Icons.cookie,
      "isSelected": false,
    },
    {
      "name": "₹5 Chakli",
      "subtitle": "Large Bag",
      "icon": Icons.bakery_dining,
      "isSelected": false,
    },
    {
      "name": "Nippat",
      "subtitle": "Crispy Snack",
      "icon": Icons.shopping_basket,
      "isSelected": false,
    },
  ];
  List<Map<String, dynamic>> get setupItems => _setupItems;

  void addSetupItem({
    required String name,
    required String subtitle,
    required IconData icon,
  }) {
    _setupItems.add({
      "name": name,
      "subtitle": subtitle,
      "icon": icon,
      "isSelected": true, // Automatically select it for today's active rounds
    });
    notifyListeners();
  }

  void toggleSetupItem(int index) {
    _setupItems[index]["isSelected"] = !_setupItems[index]["isSelected"];
    notifyListeners();
  }

  bool get isStartRoundsEnabled =>
      _setupItems.any((item) => item["isSelected"] == true);

  // Active items determined after "Start Rounds"
  List<String> _activeRoundsItems = [];
  List<String> get activeRoundsItems => _activeRoundsItems;
  
  String _currentLoggingItem = "₹5 Chakli";
  String get currentLoggingItem => _currentLoggingItem;

  void setCurrentLoggingItem(String item) {
    _currentLoggingItem = item;
    notifyListeners();
  }

  bool _roundsStarted = false;
  bool get roundsStarted => _roundsStarted;

  void startRounds() {
    _activeRoundsItems = _setupItems
        .where((item) => item["isSelected"] == true)
        .map<String>((item) => item["name"] as String)
        .toList();
    if (_activeRoundsItems.isNotEmpty) {
      _currentLoggingItem = _activeRoundsItems.first;
    }
    _roundsStarted = true;
    notifyListeners();
  }

  void resetRounds() {
    _roundsStarted = false;
    for (var item in _setupItems) {
      item["isSelected"] = false;
    }
    _activeRoundsItems.clear();
    notifyListeners();
  }

  // 2. Sales / Delivery Logging State
  int _serialNumber = 1001;
  int get serialNumber => _serialNumber;

  final List<DeliveryLog> _deliveryLogs = [];
  List<DeliveryLog> get deliveryLogs => _deliveryLogs;

  // 3. Customers Database
  final List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  Future<void> addCustomer({
    required String name,
    String type = "RETAIL",
    String area = "Custom Area",
  }) async {
    final cleanName = toSentenceCase(name);
    if (cleanName.isNotEmpty) {
      // Prevent overwriting outstanding balances for existing customers due to input race conditions
      final bool alreadyExists = _customers.any((c) => c.name.toLowerCase() == cleanName.toLowerCase());
      if (alreadyExists) {
        debugPrint("addCustomer: Customer '$cleanName' already exists. Skipping write to prevent overwriting balance.");
        return;
      }

      await customerRepository.addCustomer(Customer(
        name: cleanName,
        type: type,
        area: area,
        outstanding: 0.0,
        icon: _getCustomerIcon(type),
        location: "Added via Sales",
        status: "Active Client",
      ));
    }
  }

  // Transaction history for customer details page
  final Map<String, List<Transaction>> _customerTransactions = {};

  List<Transaction> getTransactionsForCustomer(String name) {
    return _customerTransactions[name] ?? [];
  }

  Future<void> deleteTransaction(String customerName, int index) async {
    if (_customerTransactions.containsKey(customerName)) {
      final list = _customerTransactions[customerName];
      if (list != null && index < list.length) {
        final tx = list[index];
        
        final logsList = await deliveryLogRepository.getLogsForCustomer(customerName);
        final match = logsList.firstWhere(
          (log) => log.amount == tx.amount && 
                   log.isPaid == tx.isPaid && 
                   log.isPayment == tx.isPayment,
          orElse: () => throw Exception("Log not found"),
        );
        
        if (match.logId != null) {
          await deliveryLogRepository.deleteDeliveryLog(match.logId!);
        }

        // Adjust outstanding balance
        if (tx.isPayment) {
          await customerRepository.updateCustomerOutstanding(customerName, tx.amount);
        } else if (!tx.isPaid) {
          await customerRepository.updateCustomerOutstanding(customerName, -tx.amount);
        }
      }
    }
  }

  Future<void> editTransaction({
    required String customerName,
    required int index,
    required String newDetails,
    required double newAmount,
  }) async {
    if (_customerTransactions.containsKey(customerName)) {
      final list = _customerTransactions[customerName];
      if (list != null && index < list.length) {
        final tx = list[index];
        final oldAmount = tx.amount;
        final wasPaid = tx.isPaid;
        
        final logsList = await deliveryLogRepository.getLogsForCustomer(customerName);
        final match = logsList.firstWhere(
          (log) => log.amount == oldAmount && 
                   log.isPaid == wasPaid && 
                   log.isPayment == tx.isPayment,
          orElse: () => throw Exception("Log not found"),
        );

        if (match.logId != null) {
          await deliveryLogRepository.updateDeliveryLog(match.logId!, {
            'itemName': tx.isPayment ? newDetails : newDetails.replaceAll("1x ", ""),
            'amount': newAmount,
          });
        }

        // Recalculate outstanding balance difference
        if (tx.isPayment) {
          final diff = oldAmount - newAmount;
          await customerRepository.updateCustomerOutstanding(customerName, diff);
        } else if (!wasPaid) {
          final diff = newAmount - oldAmount;
          await customerRepository.updateCustomerOutstanding(customerName, diff);
        }
      }
    }
  }

  Future<void> markTransactionAsPaid(String customerName, int index) async {
    final list = _customerTransactions[customerName];
    if (list != null && index < list.length) {
      final tx = list[index];
      if (!tx.isPaid) {
        final logsList = await deliveryLogRepository.getLogsForCustomer(customerName);
        final match = logsList.firstWhere(
          (log) => log.amount == tx.amount && !log.isPaid,
          orElse: () => throw Exception("Log not found"),
        );
        
        if (match.logId != null) {
          await deliveryLogRepository.updateDeliveryLog(match.logId!, {
            'isPaid': true,
          });
        }

        // Reduce outstanding balance
        await customerRepository.updateCustomerOutstanding(customerName, -tx.amount);
      }
    }
  }

  Future<void> addDeliveryLog({
    required String customerName,
    required String itemName,
    required double amount,
    required bool isPaid,
  }) async {
    final cleanCustomer = toSentenceCase(customerName);
    final cleanItem = toSentenceCase(itemName);
    final activeBag = activeRiceBag;
    final dateStr = "${_deliveryDate.day} ${_getMonthName(_deliveryDate.month)} ${_deliveryDate.year}";

    await deliveryLogRepository.addDeliveryLog(DeliveryLog(
      serialNo: _serialNumber,
      date: dateStr,
      dateTime: _deliveryDate,
      itemName: cleanItem,
      customerName: cleanCustomer,
      amount: amount,
      isPaid: isPaid,
      associatedBagId: activeBag?.bagId,
      isPayment: false,
    ));

    // Increment customer outstanding if unpaid
    if (!isPaid) {
      await customerRepository.updateCustomerOutstanding(cleanCustomer, amount);
    }

    _serialNumber++;
    notifyListeners();
  }

  Future<void> recordCustomerPayment({
    required String customerName,
    required double amount,
    required DateTime date,
  }) async {
    final cleanCustomer = toSentenceCase(customerName);
    final dateStr = "${date.day} ${_getMonthName(date.month)} ${date.year}";

    await deliveryLogRepository.addDeliveryLog(DeliveryLog(
      serialNo: _serialNumber,
      date: dateStr,
      dateTime: date,
      itemName: "Cash Collected",
      customerName: cleanCustomer,
      amount: amount,
      isPaid: true,
      associatedBagId: null,
      isPayment: true,
    ));

    // Reduce customer outstanding balance
    await customerRepository.updateCustomerOutstanding(cleanCustomer, -amount);

    _serialNumber++;
    notifyListeners();
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  // 4. Expenditures Database
  List<String> _expenseSuggestions = [];
  List<String> get expenseSuggestions => _expenseSuggestions;

  Future<void> addExpenseSuggestion(String itemName) async {
    final cleanItemName = toSentenceCase(itemName);
    if (cleanItemName.isNotEmpty && !_expenseSuggestions.contains(cleanItemName)) {
      _expenseSuggestions.add(cleanItemName);
      _expenseSuggestions = _expenseSuggestions.map((e) => toSentenceCase(e)).toSet().toList();
      notifyListeners();
      try {
        await settingsRepository.updateExpenseSuggestions(_expenseSuggestions);
      } catch (e) {
        debugPrint("Error saving expense item to settings: $e");
      }
    }
  }

  final List<String> _expenseCategories = ["Cylinders", "Transportation"];
  List<String> get expenseCategories => _expenseCategories;

  void addExpenseCategory(String category) {
    final cleanCategory = category.trim();
    if (cleanCategory.isNotEmpty && !_expenseCategories.any((c) => c.toLowerCase() == cleanCategory.toLowerCase())) {
      _expenseCategories.add(cleanCategory);
      notifyListeners();
    }
  }

  void deleteExpenseCategory(String category) {
    _expenseCategories.remove(category);
    notifyListeners();
  }

  final List<ExpenseLog> _expenses = [];
  List<ExpenseLog> get expenses => _expenses;

  double get totalExpenditure => _expenses.fold(0.0, (prev, exp) => prev + exp.amount);

  double get riceExpenditure => _expenses
      .where((e) => e.category == "RICE")
      .fold(0.0, (prev, exp) => prev + exp.amount);

  double get cylindersExpenditure => _expenses
      .where((e) => e.category == "Cylinders")
      .fold(0.0, (prev, exp) => prev + exp.amount);

  double get transportExpenditure => _expenses
      .where((e) => e.category == "Transportation")
      .fold(0.0, (prev, exp) => prev + exp.amount);

  Future<void> addExpense({
    required String itemName,
    required String category,
    required double amount,
    required String date,
    double totalKg = 0.0,
  }) async {
    final cleanItemName = toSentenceCase(itemName);
    final activeBag = activeRiceBag;

    await expenseRepository.addExpense(ExpenseLog(
      itemName: cleanItemName,
      category: category,
      amount: amount,
      date: date,
      associatedBagId: activeBag?.bagId,
    ));
  }

  Future<void> updateExpense({
    required String expenseId,
    required String newItemName,
    required double newAmount,
  }) async {
    final casedName = toSentenceCase(newItemName);
    try {
      await expenseRepository.updateExpense(expenseId, casedName, newAmount);
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating expense: $e");
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await expenseRepository.deleteExpense(expenseId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting expense: $e");
    }
  }

  // 5. Summary & Cloud Sync State
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _syncSuccessful = false;
  bool get syncSuccessful => _syncSuccessful;

  String _googleSheetsUrl = "https://script.google.com/macros/s/AKfycbxvY0IoblgOGgVXTssxC7aYnTN0q5_W7-hkjtgLPI7595Ro5Ur0dmCEMQIb7DAqL9ZMYg/exec";
  String get googleSheetsUrl => _googleSheetsUrl;

  Future<void> setGoogleSheetsUrl(String url) async {
    final cleanUrl = url.trim();
    _googleSheetsUrl = cleanUrl;
    notifyListeners();
    try {
      await settingsRepository.updateGoogleSheetsUrl(cleanUrl);
    } catch (e) {
      debugPrint("Error saving Sheets URL: $e");
    }
  }

  // Rice Flour Bag Tracking State
  final List<RiceBag> _riceBags = [];
  List<RiceBag> get riceBags => _riceBags;

  final List<DailyUsage> _dailyUsages = [];
  List<DailyUsage> get dailyUsages => _dailyUsages;

  // Active bag getter
  RiceBag? get activeRiceBag {
    try {
      return _riceBags.firstWhere((bag) => bag.status == "Active");
    } catch (_) {
      return null;
    }
  }

  // Previous completed bag getter
  RiceBag? get previousCompletedRiceBag {
    try {
      final completed = _riceBags.where((bag) => bag.status == "Completed").toList();
      if (completed.isNotEmpty) {
        return completed.first;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _completeBag(RiceBag bag, String endDate, Map<String, dynamic> additionalUpdates) async {
    final revenue = _deliveryLogs
        .where((log) => !log.isPayment && log.associatedBagId == bag.bagId)
        .fold(0.0, (total, log) => total + log.amount);

    DateTime? startDate;
    try {
      startDate = DateFormat('dd MMMM yyyy').parse(bag.startDate);
    } catch (_) {}

    final expenses = _expenses.where((exp) {
      if (exp.associatedBagId == bag.bagId) return true;
      if (exp.associatedBagId != null) return false;
      if (startDate != null) {
        try {
          final expDate = DateTime.parse(exp.date);
          return expDate.isAfter(startDate.subtract(const Duration(days: 1)));
        } catch (_) {}
      }
      return false;
    }).fold(0.0, (total, exp) => total + exp.amount);

    final profit = revenue - expenses;
    final profitMargin = revenue <= 0.0 ? 0.0 : (profit / revenue) * 100.0;

    int? bagNum = bag.bagNumber;
    if (bagNum == null) {
      final sortedBags = List<RiceBag>.from(_riceBags)
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      final idx = sortedBags.indexWhere((b) => b.bagId == bag.bagId);
      bagNum = idx != -1 ? idx + 1 : 1;
    }

    final updatedBag = bag.copyWith(
      status: 'Completed',
      endDate: endDate,
      revenue: revenue,
      expenses: expenses,
      profit: profit,
      profitMargin: profitMargin,
      bagNumber: bagNum,
      usedKg: additionalUpdates['usedKg'],
      remainingKg: additionalUpdates['remainingKg'],
    );
    await riceBagRepository.saveRiceBag(updatedBag);
  }

  Future<void> addRiceFlourBag({
    required double totalKg,
    required double cost,
    required String date,
  }) async {
    // 1. Mark previous active bags completed with final financials saved
    for (var bag in _riceBags) {
      if (bag.status == "Active") {
        await _completeBag(bag, date, {});
      }
    }

    // 2. Determine bag number
    int nextBagNum = 1;
    if (_riceBags.isNotEmpty) {
      final nums = _riceBags.map((b) => b.bagNumber ?? 0).toList();
      final maxNum = nums.isEmpty ? 0 : nums.fold<int>(0, (maxVal, element) => element > maxVal ? element : maxVal);
      nextBagNum = maxNum + 1;
    }

    // 3. Instantiate new active bag
    final bagId = "BAG_${DateTime.now().millisecondsSinceEpoch}";
    await riceBagRepository.saveRiceBag(RiceBag(
      bagId: bagId,
      totalKg: totalKg,
      usedKg: 0.0,
      remainingKg: totalKg,
      startDate: date,
      status: 'Active',
      cost: cost,
      bagNumber: nextBagNum,
    ));
  }

  Future<void> addDailyUsage({
    required double usedKg,
    required String date,
  }) async {
    final activeBag = activeRiceBag;
    if (activeBag == null) return;

    final usageId = "USE_${DateTime.now().millisecondsSinceEpoch}";
    await riceBagRepository.addDailyUsage(DailyUsage(
      usageId: usageId,
      bagId: activeBag.bagId,
      date: date,
      usedKg: usedKg,
    ));
    final newUsed = activeBag.usedKg + usedKg;
    final newRemaining = activeBag.remainingKg - usedKg;

    final updatedBag = activeBag.copyWith(
      usedKg: newUsed,
      remainingKg: newRemaining < 0.0 ? 0.0 : newRemaining,
      status: 'Active',
    );
    await riceBagRepository.saveRiceBag(updatedBag);
  }

  Future<void> closeAndStartNewBag({
    required double totalKg,
    required String date,
  }) async {
    // Complete active bag
    final activeBag = activeRiceBag;
    if (activeBag != null) {
      await _completeBag(activeBag, date, {});
    }

    // Determine bag number
    int nextBagNum = 1;
    if (_riceBags.isNotEmpty) {
      final nums = _riceBags.map((b) => b.bagNumber ?? 0).toList();
      final maxNum = nums.isEmpty ? 0 : nums.fold<int>(0, (maxVal, element) => element > maxVal ? element : maxVal);
      nextBagNum = maxNum + 1;
    }

    // Start a new bag with zero cost
    final bagId = "BAG_${DateTime.now().millisecondsSinceEpoch}";
    await riceBagRepository.saveRiceBag(RiceBag(
      bagId: bagId,
      totalKg: totalKg,
      usedKg: 0.0,
      remainingKg: totalKg,
      startDate: date,
      status: 'Active',
      cost: 0.0,
      bagNumber: nextBagNum,
    ));
  }

  int getBagNumber(RiceBag bag) {
    if (bag.bagNumber != null) return bag.bagNumber!;
    final sortedBags = List<RiceBag>.from(_riceBags)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final idx = sortedBags.indexWhere((b) => b.bagId == bag.bagId);
    return idx != -1 ? idx + 1 : 1;
  }

  double getBagRevenue(RiceBag bag) {
    if (bag.status == "Active") return currentBagRevenue;
    if (bag.revenue != null) return bag.revenue!;
    return _deliveryLogs
        .where((log) => !log.isPayment && log.associatedBagId == bag.bagId)
        .fold(0.0, (total, log) => total + log.amount);
  }

  double getBagExpenses(RiceBag bag) {
    if (bag.status == "Active") return currentBagExpenses;
    if (bag.expenses != null) return bag.expenses!;
    
    DateTime? startDate;
    try {
      startDate = DateFormat('dd MMMM yyyy').parse(bag.startDate);
    } catch (_) {}

    return _expenses.where((exp) {
      if (exp.associatedBagId == bag.bagId) return true;
      if (exp.associatedBagId != null) return false;
      if (startDate != null) {
        try {
          final expDate = DateTime.parse(exp.date);
          return expDate.isAfter(startDate.subtract(const Duration(days: 1)));
        } catch (_) {}
      }
      return false;
    }).fold(0.0, (total, exp) => total + exp.amount);
  }

  double getBagProfit(RiceBag bag) {
    if (bag.status == "Active") return currentBagProfit;
    if (bag.profit != null) return bag.profit!;
    return getBagRevenue(bag) - getBagExpenses(bag);
  }

  double getBagProfitMargin(RiceBag bag) {
    if (bag.status == "Active") return currentBagProfitMargin;
    if (bag.profitMargin != null) return bag.profitMargin!;
    final rev = getBagRevenue(bag);
    if (rev <= 0.0) return 0.0;
    return (getBagProfit(bag) / rev) * 100;
  }

  double get currentBagEarnings {
    final activeBag = activeRiceBag;
    if (activeBag == null) return 0.0;
    return _deliveryLogs
        .where((log) => log.associatedBagId == activeBag.bagId)
        .fold(0.0, (total, log) => total + log.amount);
  }

  double get previousBagEarnings {
    final prevBag = previousCompletedRiceBag;
    if (prevBag == null) return 0.0;
    return _deliveryLogs
        .where((log) => log.associatedBagId == prevBag.bagId)
        .fold(0.0, (total, log) => total + log.amount);
  }

  // Profit & Financial Overview - Active Bag (Current Bag)
  double get currentBagRevenue {
    final activeBag = activeRiceBag;
    if (activeBag == null) return 0.0;
    return _deliveryLogs
        .where((log) => !log.isPayment && log.associatedBagId == activeBag.bagId)
        .fold(0.0, (total, log) => total + log.amount);
  }

  double get currentBagExpenses {
    final activeBag = activeRiceBag;
    if (activeBag == null) return 0.0;

    DateTime? startDate;
    try {
      startDate = DateFormat('dd MMMM yyyy').parse(activeBag.startDate);
    } catch (_) {}

    return _expenses.where((exp) {
      if (exp.associatedBagId == activeBag.bagId) return true;
      if (exp.associatedBagId != null) return false; // Assigned to another bag explicitly
      if (startDate != null) {
        try {
          final expDate = DateTime.parse(exp.date);
          return expDate.isAfter(startDate.subtract(const Duration(days: 1)));
        } catch (_) {}
      }
      return false;
    }).fold(0.0, (total, exp) => total + exp.amount);
  }

  List<ExpenseLog> get currentBagExpensesList {
    final activeBag = activeRiceBag;
    if (activeBag == null) return [];

    DateTime? startDate;
    try {
      startDate = DateFormat('dd MMMM yyyy').parse(activeBag.startDate);
    } catch (_) {}

    return _expenses.where((exp) {
      if (exp.associatedBagId == activeBag.bagId) return true;
      if (exp.associatedBagId != null) return false; // Assigned to another bag explicitly
      if (startDate != null) {
        try {
          final expDate = DateTime.parse(exp.date);
          return expDate.isAfter(startDate.subtract(const Duration(days: 1)));
        } catch (_) {}
      }
      return false;
    }).toList();
  }

  List<ExpenseLog> getExpensesForBag(RiceBag bag) {
    if (bag.status == "Active") return currentBagExpensesList;

    DateTime? startDate;
    try {
      startDate = DateFormat('dd MMMM yyyy').parse(bag.startDate);
    } catch (_) {}

    DateTime? endDate;
    if (bag.endDate != null) {
      try {
        endDate = DateFormat('dd MMMM yyyy').parse(bag.endDate!);
      } catch (_) {}
    }

    return _expenses.where((exp) {
      if (exp.associatedBagId == bag.bagId) return true;
      if (exp.associatedBagId != null) return false;

      if (startDate != null) {
        try {
          final expDate = DateTime.parse(exp.date);
          final isAfterStart = expDate.isAfter(startDate.subtract(const Duration(days: 1)));
          if (endDate != null) {
            final isBeforeEnd = expDate.isBefore(endDate.add(const Duration(days: 1)));
            return isAfterStart && isBeforeEnd;
          }
          return isAfterStart;
        } catch (_) {}
      }
      return false;
    }).toList();
  }

  double get currentBagProfit => currentBagRevenue - currentBagExpenses;

  double get currentBagProfitMargin {
    final rev = currentBagRevenue;
    if (rev <= 0.0) return 0.0;
    return (currentBagProfit / rev) * 100;
  }

  // Profit & Financial Overview - Lifetime (Overall Business)
  double get overallRevenue {
    return _deliveryLogs
        .where((log) => !log.isPayment)
        .fold(0.0, (total, log) => total + log.amount);
  }

  double get overallExpenses {
    return _expenses.fold(0.0, (total, exp) => total + exp.amount);
  }

  double get overallProfit => overallRevenue - overallExpenses;

  double get overallProfitMargin {
    final rev = overallRevenue;
    if (rev <= 0.0) return 0.0;
    return (overallProfit / rev) * 100;
  }

  // Dynamic monthly sales trend aggregator
  List<Map<String, dynamic>> getChartData() {
    final List<Map<String, dynamic>> chart = [];
    final monthAbbreviations = ["JUN", "JUL", "AUG", "SEP", "OCT", "NOV"];
    
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = monthAbbreviations[(date.month - 1) % monthAbbreviations.length];
      final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      
      double activeSales = _deliveryLogs.where((log) {
        return !log.isPayment && log.dateTime.year == date.year && log.dateTime.month == date.month;
      }).fold(0.0, (total, log) => total + log.amount);
      
      double historicalSales = _historicalMonthlySales[monthKey] ?? 0.0;

      chart.add({
        "month": monthName,
        "sales": activeSales + historicalSales,
      });
    }
    return chart;
  }

  Future<bool> triggerSync() async {
    debugPrint("--- STARTING GOOGLE SHEETS BACKUP EXPORT ---");
    debugPrint("Sheets URL target: $_googleSheetsUrl");

    if (_googleSheetsUrl.isEmpty) {
      _isSyncing = true;
      _syncSuccessful = false;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
      _isSyncing = false;
      _syncSuccessful = true;
      notifyListeners();
      return true;
    }

    _isSyncing = true;
    _syncSuccessful = false;
    notifyListeners();

    try {
      final payload = {
        "action": "syncAll",
        "X-Auth-Token": const String.fromEnvironment('SHEETS_SECRET_TOKEN'),
        "deliveryLogs": _deliveryLogs.map((log) => log.toJson()).toList(),
        "expenses": _expenses.map((exp) => exp.toJson()).toList(),
        "riceBags": _riceBags.map((bag) => bag.toJson()).toList(),
        "savingsLogs": _savingsLogs.map((log) => log.toJson()).toList(),
      };

      final bodyData = json.encode(payload);
      http.Response response;

      if (kIsWeb) {
        response = await http.post(
          Uri.parse(_googleSheetsUrl),
          headers: {
            "Content-Type": "application/json",
            "X-Auth-Token": const String.fromEnvironment('SHEETS_SECRET_TOKEN'),
          },
          body: bodyData,
        );
      } else {
        var targetUrl = _googleSheetsUrl;
        final client = http.Client();

        var request = http.Request('POST', Uri.parse(targetUrl))
          ..headers['Content-Type'] = 'application/json'
          ..headers['X-Auth-Token'] = const String.fromEnvironment('SHEETS_SECRET_TOKEN')
          ..body = bodyData
          ..followRedirects = false;

        var streamedResponse = await client.send(request);
        response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307 || response.statusCode == 308 || response.statusCode == 303) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl != null) {
            var redirectRequest = http.Request('POST', Uri.parse(redirectUrl))
              ..headers['Content-Type'] = 'application/json'
              ..headers['X-Auth-Token'] = const String.fromEnvironment('SHEETS_SECRET_TOKEN')
              ..body = bodyData;

            var redirectStreamed = await client.send(redirectRequest);
            response = await http.Response.fromStream(redirectStreamed);
          }
        }
      }

      _isSyncing = false;
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData["status"] == "success") {
          _syncSuccessful = true;
          notifyListeners();
          return true;
        }
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  void closeSyncOverlay() {
    _syncSuccessful = false;
    notifyListeners();
  }

  // Delete transaction globally by its unique Serial Number
  Future<void> deleteTransactionBySerialNo(int serialNo) async {
    try {
      final log = _deliveryLogs.firstWhere((l) => l.serialNo == serialNo);
      
      // Delete from repository
      await deliveryLogRepository.deleteLogBySerialNo(serialNo);

      // Adjust outstanding balance
      if (log.isPayment) {
        await customerRepository.updateCustomerOutstanding(log.customerName, log.amount);
      } else if (!log.isPaid) {
        await customerRepository.updateCustomerOutstanding(log.customerName, -log.amount);
      }
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
    }
  }

  // Edit transaction globally by its unique Serial Number
  Future<void> editTransactionBySerialNo(int serialNo, String newDetails, double newAmount) async {
    try {
      final log = _deliveryLogs.firstWhere((l) => l.serialNo == serialNo);
      final oldAmount = log.amount;

      // Update in repository
      await deliveryLogRepository.updateLogBySerialNo(serialNo, newDetails, newAmount);

      // Adjust outstanding balance difference
      if (log.isPayment) {
        final diff = oldAmount - newAmount;
        await customerRepository.updateCustomerOutstanding(log.customerName, diff);
      } else if (!log.isPaid) {
        final diff = newAmount - oldAmount;
        await customerRepository.updateCustomerOutstanding(log.customerName, diff);
      }
    } catch (e) {
      debugPrint("Error editing transaction: $e");
    }
  }

  // Startup Database Sentence Case Migration script
  Future<void> runSentenceCaseMigration() async {
    debugPrint("--- STARTING DATABASE SENTENCE CASE MIGRATION ---");
    try {
      // 1. Migrate settings/expenseItems suggestions
      final rawItems = await settingsRepository.getExpenseSuggestionsStream().first;
      if (rawItems.isNotEmpty) {
        final migratedSuggestions = rawItems
            .map((item) => toSentenceCase(item))
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
        await settingsRepository.updateExpenseSuggestions(migratedSuggestions);
        debugPrint("Migrated expense suggestions: $migratedSuggestions");
      }

      // 2. Migrate customers collection (and consolidate duplicates)
      final customersList = await customerRepository.getAllCustomers(_getCustomerIcon);
      final Map<String, List<Customer>> groupedCustomers = {};
      for (var doc in customersList) {
        final name = doc.name;
        final casedName = toSentenceCase(name);
        if (casedName.isNotEmpty) {
          if (!groupedCustomers.containsKey(casedName)) {
            groupedCustomers[casedName] = [];
          }
          groupedCustomers[casedName]!.add(doc);
        }
      }

      for (var entry in groupedCustomers.entries) {
        final casedName = entry.key;
        final docs = entry.value;

        // Sum outstanding balance
        double totalOutstanding = 0.0;
        for (var doc in docs) {
          totalOutstanding += doc.outstanding;
        }

        // Get template fields from first document
        final first = docs.first;
        final type = first.type;
        final area = first.area;
        final location = first.location;

        // Write the consolidated sentence-cased customer
        await customerRepository.saveCustomer(Customer(
          name: casedName,
          type: type,
          area: area,
          outstanding: totalOutstanding,
          icon: _getCustomerIcon(type),
          location: location,
        ));

        // Delete old customer docs if they were cased differently, and update their logs
        for (var doc in docs) {
          if (doc.name != casedName) {
            // Find and update delivery logs
            final logsList = await deliveryLogRepository.getLogsForCustomer(doc.name);
            
            for (var log in logsList) {
              if (log.logId != null) {
                await deliveryLogRepository.updateDeliveryLog(log.logId!, {'customerName': casedName});
              }
            }

            // Delete old customer doc
            await customerRepository.deleteCustomer(doc.name);
          }
        }
      }
      debugPrint("Migrated customers collection successfully.");

      // 3. Migrate deliveryLogs (itemName & customerName case correction)
      final logsList = await deliveryLogRepository.getAllLogs();
      for (var log in logsList) {
        final currentCustomerName = log.customerName;
        final currentItemName = log.itemName;
        
        final casedCustomer = toSentenceCase(currentCustomerName);
        final casedItem = (currentItemName.toLowerCase() == "cash collected") 
            ? "Cash Collected" 
            : toSentenceCase(currentItemName);

        if (casedCustomer != currentCustomerName || casedItem != currentItemName) {
          if (log.logId != null) {
            await deliveryLogRepository.updateDeliveryLog(log.logId!, {
              'customerName': casedCustomer,
              'itemName': casedItem,
            });
          }
        }
      }
      debugPrint("Migrated delivery logs successfully.");

      // 4. Migrate expenses collection (itemName case correction)
      final expensesList = await expenseRepository.getAllExpenses();
      for (var doc in expensesList) {
        final currentItemName = doc.itemName;
        final casedItemName = toSentenceCase(currentItemName);
        if (casedItemName != currentItemName) {
          if (doc.expenseId != null) {
            await expenseRepository.updateExpense(
              doc.expenseId!,
              casedItemName,
              doc.amount,
            );
          }
        }
      }
      debugPrint("Migrated expenses successfully.");

    } catch (e) {
      debugPrint("Error running sentence case migration: $e");
    }
  }

  // Calculated Stats
  double get todaySales => _deliveryLogs.where((l) {
    final now = DateTime.now();
    return !l.isPayment &&
           l.dateTime.day == now.day && 
           l.dateTime.month == now.month && 
           l.dateTime.year == now.year;
  }).fold(0.0, (total, log) => total + log.amount);

  int get todayDeliveriesCount => _deliveryLogs.where((l) {
    final now = DateTime.now();
    return !l.isPayment &&
           l.dateTime.day == now.day && 
           l.dateTime.month == now.month && 
           l.dateTime.year == now.year;
  }).length;

  int get todayReturnsCount => 0;

  Future<void> updateOwnerLoanNotes(String notes) async {
    if (_activeLoan != null) {
      await ownerFinanceRepository.updateNotes(_activeLoan!.id, notes);
    }
  }

  Future<void> addOwnerRepayment(double amount) async {
    if (_activeLoan != null && amount > 0.0) {
      final repayment = RepaymentLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amountPaid: amount,
        repaymentDate: DateTime.now(),
      );
      await ownerFinanceRepository.addRepayment(_activeLoan!.id, repayment);
    }
  }

  Future<void> updateOwnerLoanTotalBorrowed(double total) async {
    if (_activeLoan != null) {
      await ownerFinanceRepository.updateTotalBorrowed(_activeLoan!.id, total);
    }
  }

  Future<void> addSavingsDeposit(double amount) async {
    if (amount > 0.0) {
      final log = SavingsLog(
        id: "SAV_${DateTime.now().millisecondsSinceEpoch}",
        amount: amount,
        type: 'deposit',
        notes: 'Deposit to Savings',
        date: DateTime.now(),
      );
      await ownerFinanceRepository.addSavingsLog(log);
    }
  }

  Future<void> addSavingsWithdrawal(double amount, String notes) async {
    if (amount > 0.0) {
      final log = SavingsLog(
        id: "SAV_${DateTime.now().millisecondsSinceEpoch}",
        amount: -amount,
        type: 'withdrawal',
        notes: notes.trim().isEmpty ? 'Withdrawal from Savings' : notes.trim(),
        date: DateTime.now(),
      );
      await ownerFinanceRepository.addSavingsLog(log);
    }
  }

  Future<void> executeSavingsTransfer(String docId, int amount) async {
    final doubleAmount = amount.toDouble();
    if (doubleAmount > 0.0) {
      final log = SavingsLog(
        id: "SAV_REC_$docId",
        amount: doubleAmount,
        type: 'deposit',
        notes: 'Transfer from Daily Surplus Recommendation',
        date: DateTime.now(),
      );
      await ownerFinanceRepository.addSavingsLog(log);
    }

    await ownerFinanceRepository.updateSavingsRecommendationStatus(
      docId,
      'transferred',
      amount,
    );
  }

  Future<void> skipSavingsRecommendation(String docId) async {
    await ownerFinanceRepository.updateSavingsRecommendationStatus(
      docId,
      'skipped',
      null,
    );
  }

  Future<void> _checkAndGenerateSavingsRecommendation(String yesterdayDateStr) async {
    if (isMockMode) {
      debugPrint("Mock mode: Skipping background Firestore savings recommendation check.");
      return;
    }
    try {
      // 1. Check if recommendation document already exists in Firestore
      final docSnap = await FirebaseFirestore.instance
          .collection(_getCollectionPath('savings_recommendations'))
          .doc(yesterdayDateStr)
          .get();

      if (docSnap.exists) {
        debugPrint("Savings recommendation for $yesterdayDateStr already exists in Firestore.");
        return;
      }

      debugPrint("Savings recommendation for $yesterdayDateStr not found. Generating in foreground...");

      // 2. Fetch payload details for yesterday
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
      final yesterdayEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);

      final String startIso = yesterdayStart.toIso8601String();
      final String endIso = yesterdayEnd.toIso8601String();

      final logsSnapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('deliveryLogs'))
          .where('dateTime', isGreaterThanOrEqualTo: startIso)
          .where('dateTime', isLessThanOrEqualTo: endIso)
          .get();

      final expensesSnapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('expenses'))
          .where('date', isEqualTo: yesterdayDateStr)
          .get();

      // 3. Aggregate Cash flow
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
            .collection(_getCollectionPath('settings'))
            .doc('financeSettings')
            .get();
        if (settingsDoc.exists && settingsDoc.data() != null) {
          final data = settingsDoc.data()!;
          minSavingsPct = (data['min_savings_pct'] as num?)?.toInt() ?? 2;
          maxSavingsPct = (data['max_savings_pct'] as num?)?.toInt() ?? 7;
        }
      } catch (e) {
        debugPrint("Could not fetch remote finance settings in foreground: $e. Using default 2% to 7%.");
      }

      // 4. Generate with Gemini
      const String key = String.fromEnvironment('GEMINI_API_KEY');
      if (key.isEmpty) {
        debugPrint("Foreground Advisor Error: GEMINI_API_KEY is empty.");
        return;
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: key,
      );

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
        debugPrint("Failed to parse foreground savings advisor JSON: $e");
      }

      await FirebaseFirestore.instance
          .collection(_getCollectionPath('savings_recommendations'))
          .doc(yesterdayDateStr)
          .set({
        'date': yesterdayDateStr,
        'suggested_savings': suggestedSavings,
        'conversational_reason': conversationalReason,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint("Foreground generated recommendation for $yesterdayDateStr successfully saved to Firestore.");
    } catch (e) {
      debugPrint("Foreground advisor loop execution failed: $e");
    }
  }
}



