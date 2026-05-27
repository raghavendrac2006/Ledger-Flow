import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String name;
  final String type;
  final String area;
  double outstanding;
  final IconData icon;
  final String location;
  final String status;

  Customer({
    required this.name,
    required this.type,
    required this.area,
    required this.outstanding,
    required this.icon,
    this.location = "Downtown Market",
    this.status = "Active Client",
  });
}

class Transaction {
  final String date;
  String details;
  double amount;
  bool isPaid;

  Transaction({
    required this.date,
    required this.details,
    required this.amount,
    required this.isPaid,
  });

  Map<String, dynamic> toJson() => {
    "date": date,
    "details": details,
    "amount": amount,
    "isPaid": isPaid,
  };
}

class DeliveryLog {
  final int serialNo;
  final String date;
  final DateTime dateTime;
  final String itemName;
  final String customerName;
  final double amount;
  final bool isPaid;
  String? associatedBagId;

  DeliveryLog({
    required this.serialNo,
    required this.date,
    required this.dateTime,
    required this.itemName,
    required this.customerName,
    required this.amount,
    required this.isPaid,
    this.associatedBagId,
  });

  Map<String, dynamic> toJson() => {
    "serialNo": serialNo,
    "date": date,
    "dateTime": dateTime.toIso8601String(),
    "itemName": itemName,
    "customerName": customerName,
    "amount": amount,
    "isPaid": isPaid,
  };
}

class ExpenseLog {
  final String itemName;
  final String category; // RICE, Cylinders, Transportation
  final double amount;
  final String date;

  ExpenseLog({
    required this.itemName,
    required this.category,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    "itemName": itemName,
    "category": category,
    "amount": amount,
    "date": date,
  };
}

class RiceBag {
  final String bagId;
  final double totalKg;
  double usedKg;
  double remainingKg;
  final String startDate;
  String? endDate;
  String status; // "Active" | "Completed"
  final double cost;

  RiceBag({
    required this.bagId,
    required this.totalKg,
    this.usedKg = 0.0,
    required this.remainingKg,
    required this.startDate,
    this.endDate,
    this.status = "Active",
    required this.cost,
  });

  Map<String, dynamic> toJson() => {
    "bagId": bagId,
    "totalKg": totalKg,
    "usedKg": usedKg,
    "remainingKg": remainingKg,
    "startDate": startDate,
    "endDate": endDate,
    "status": status,
    "cost": cost,
  };
}

class DailyUsage {
  final String usageId;
  final String bagId;
  final String date;
  final double usedKg;

  DailyUsage({
    required this.usageId,
    required this.bagId,
    required this.date,
    required this.usedKg,
  });

  Map<String, dynamic> toJson() => {
    "usageId": usageId,
    "bagId": bagId,
    "date": date,
    "usedKg": usedKg,
  };
}

class LedgerState extends ChangeNotifier {
  LedgerState() {
    _initFirestore();
  }

  // Firestore instances & stream subscriptions
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _customersSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _bagsSub;
  StreamSubscription? _usagesSub;
  StreamSubscription? _statsSub;

  final Map<String, double> _historicalMonthlySales = {};

  void _initFirestore() {
    debugPrint("--- INITIALIZING REAL-TIME CLOUD FIRESTORE ---");

    // 1. Seed Default Customers if Database is empty
    _seedDefaultCustomers();

    // 2. Run background 3-month auto-purge of old logs (while keeping monthly totals)
    runAutoPurge();

    // 3. Listen to Customers Collection
    _customersSub = _firestore.collection('customers').snapshots().listen(
      (snapshot) {
        _customers.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _customers.add(Customer(
            name: data['name'] ?? doc.id,
            type: data['type'] ?? 'RETAIL',
            area: data['area'] ?? '',
            outstanding: (data['outstanding'] as num?)?.toDouble() ?? 0.0,
            icon: _getCustomerIcon(data['type']),
            location: data['location'] ?? '',
          ));
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore customers stream error: $error");
      }
    );

    // 4. Listen to Delivery Logs Collection (Sorted locally in memory)
    _logsSub = _firestore.collection('deliveryLogs').snapshots().listen(
      (snapshot) {
        _deliveryLogs.clear();
        _customerTransactions.clear();

        int maxSerial = 1000;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final dateStr = data['date'] ?? '';
          final customerName = data['customerName'] ?? '';
          final itemName = data['itemName'] ?? '';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final isPaid = data['isPaid'] ?? false;
          final serialNo = data['serialNo'] as int? ?? 1001;
          final dateTime = DateTime.tryParse(data['dateTime'] ?? '') ?? DateTime.now();
          final bagId = data['associatedBagId'] as String?;

          if (serialNo > maxSerial) {
            maxSerial = serialNo;
          }

          final log = DeliveryLog(
            serialNo: serialNo,
            date: dateStr,
            dateTime: dateTime,
            itemName: itemName,
            customerName: customerName,
            amount: amount,
            isPaid: isPaid,
            associatedBagId: bagId,
          );
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
            details: "1x ${log.itemName}",
            amount: log.amount,
            isPaid: log.isPaid,
          ));
        }

        // Self-healing serial number
        _serialNumber = maxSerial + 1;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore deliveryLogs stream error: $error");
      }
    );

    // 5. Listen to Expenses Collection (Sorted locally in memory)
    _expensesSub = _firestore.collection('expenses').snapshots().listen(
      (snapshot) {
        _expenses.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _expenses.add(ExpenseLog(
            itemName: data['itemName'] ?? '',
            category: data['category'] ?? '',
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            date: data['date'] ?? '',
          ));
        }
        // Sort in memory by date descending
        _expenses.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore expenses stream error: $error");
      }
    );

    // 6. Listen to Rice Bags Collection (Sorted locally in memory)
    _bagsSub = _firestore.collection('riceBags').snapshots().listen(
      (snapshot) {
        _riceBags.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _riceBags.add(RiceBag(
            bagId: doc.id,
            totalKg: (data['totalKg'] as num?)?.toDouble() ?? 0.0,
            usedKg: (data['usedKg'] as num?)?.toDouble() ?? 0.0,
            remainingKg: (data['remainingKg'] as num?)?.toDouble() ?? 0.0,
            startDate: data['startDate'] ?? '',
            endDate: data['endDate'],
            status: data['status'] ?? 'Active',
            cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
          ));
        }
        // Sort in memory by startDate descending
        _riceBags.sort((a, b) => b.startDate.compareTo(a.startDate));
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore riceBags stream error: $error");
      }
    );

    // 7. Listen to Daily Usages Collection
    _usagesSub = _firestore.collection('dailyUsages').snapshots().listen(
      (snapshot) {
        _dailyUsages.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _dailyUsages.add(DailyUsage(
            usageId: doc.id,
            bagId: data['bagId'] ?? '',
            date: data['date'] ?? '',
            usedKg: (data['usedKg'] as num?)?.toDouble() ?? 0.0,
          ));
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore dailyUsages stream error: $error");
      }
    );

    // 8. Listen to Historical Monthly Sales aggregates
    _statsSub = _firestore.collection('monthlyStats').snapshots().listen(
      (snapshot) {
        _historicalMonthlySales.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final sales = (data['sales'] as num?)?.toDouble() ?? 0.0;
          _historicalMonthlySales[doc.id] = sales;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore monthlyStats stream error: $error");
      }
    );
  }

  // Clean default seeding data to avoid empty screens initially
  Future<void> _seedDefaultCustomers() async {
    final snapshot = await _firestore.collection('customers').limit(1).get();
    if (snapshot.docs.isEmpty) {
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
        await _firestore.collection('customers').doc(c['name'] as String).set({
          'name': c['name'],
          'type': c['type'],
          'area': c['area'],
          'outstanding': c['outstanding'],
          'location': c['location'],
        });
      }
    }
  }

  // 3-Month Auto-Purge Retention: Deletes detailed logs older than 90 days, increments monthly sales summary
  Future<void> runAutoPurge() async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      final snapshot = await _firestore.collection('deliveryLogs')
          .where('dateTime', isLessThan: ninetyDaysAgo.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) return;

      debugPrint("--- RUNNING AUTO-PURGE RETENTION ON ${snapshot.docs.length} DETAILED TRANSACTION LOGS ---");

      final Map<String, List<DocumentSnapshot>> groupedLogs = {};
      for (var doc in snapshot.docs) {
        final dateTimeStr = doc.data()['dateTime'] as String?;
        if (dateTimeStr != null) {
          final dt = DateTime.tryParse(dateTimeStr);
          if (dt != null) {
            final monthKey = "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
            if (!groupedLogs.containsKey(monthKey)) {
              groupedLogs[monthKey] = [];
            }
            groupedLogs[monthKey]!.add(doc);
          }
        }
      }

      for (var entry in groupedLogs.entries) {
        final monthKey = entry.key;
        final logs = entry.value;

        double monthlySales = 0.0;
        for (var logDoc in logs) {
          final data = logDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            monthlySales += (data['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }

        // Increment monthly total sales document securely in Firestore
        await _firestore.collection('monthlyStats').doc(monthKey).set({
          'sales': FieldValue.increment(monthlySales),
          'deliveriesCount': FieldValue.increment(logs.length),
        }, SetOptions(merge: true));

        // Delete individual logs
        final batch = _firestore.batch();
        for (var logDoc in logs) {
          batch.delete(logDoc.reference);
        }
        await batch.commit();
      }

      debugPrint("--- AUTO-PURGE COMPLETED SUCCESSFULLY ---");
    } catch (e) {
      debugPrint("Auto-purge failed: $e");
    }
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
      "name": "2 ₹ Chakli",
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
    final cleanName = name.trim();
    if (cleanName.isNotEmpty) {
      await _firestore.collection('customers').doc(cleanName).set({
        'name': cleanName,
        'type': type,
        'area': area,
        'outstanding': 0.0,
        'location': "Added via Sales",
      });
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
        
        // Find matching document in Firestore
        final query = await _firestore.collection('deliveryLogs')
            .where('customerName', isEqualTo: customerName)
            .where('amount', isEqualTo: tx.amount)
            .where('isPaid', isEqualTo: tx.isPaid)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.delete();
        }

        // Reduce outstanding balance if UNPAID
        if (!tx.isPaid) {
          await _firestore.collection('customers').doc(customerName).update({
            'outstanding': FieldValue.increment(-tx.amount),
          });
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
        
        // Find matching document in Firestore
        final query = await _firestore.collection('deliveryLogs')
            .where('customerName', isEqualTo: customerName)
            .where('amount', isEqualTo: oldAmount)
            .where('isPaid', isEqualTo: wasPaid)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'itemName': newDetails.replaceAll("1x ", ""),
            'amount': newAmount,
          });
        }

        // Recalculate outstanding balance difference
        if (!wasPaid) {
          final diff = newAmount - oldAmount;
          await _firestore.collection('customers').doc(customerName).update({
            'outstanding': FieldValue.increment(diff),
          });
        }
      }
    }
  }

  Future<void> markTransactionAsPaid(String customerName, int index) async {
    final list = _customerTransactions[customerName];
    if (list != null && index < list.length) {
      final tx = list[index];
      if (!tx.isPaid) {
        // Find in Firestore
        final query = await _firestore.collection('deliveryLogs')
            .where('customerName', isEqualTo: customerName)
            .where('amount', isEqualTo: tx.amount)
            .where('isPaid', isEqualTo: false)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'isPaid': true,
          });
        }

        // Reduce outstanding balance
        await _firestore.collection('customers').doc(customerName).update({
          'outstanding': FieldValue.increment(-tx.amount),
        });
      }
    }
  }

  Future<void> addDeliveryLog({
    required String customerName,
    required String itemName,
    required double amount,
    required bool isPaid,
  }) async {
    final activeBag = activeRiceBag;
    final docId = "LOG_${DateTime.now().millisecondsSinceEpoch}";
    final dateStr = "${_deliveryDate.day} ${_getMonthName(_deliveryDate.month)} ${_deliveryDate.year}";

    // 1. Save log to Firestore
    await _firestore.collection('deliveryLogs').doc(docId).set({
      'serialNo': _serialNumber,
      'date': dateStr,
      'dateTime': _deliveryDate.toIso8601String(),
      'itemName': itemName,
      'customerName': customerName,
      'amount': amount,
      'isPaid': isPaid,
      'associatedBagId': activeBag?.bagId,
    });

    // 2. Increment customer outstanding if unpaid
    if (!isPaid) {
      await _firestore.collection('customers').doc(customerName).update({
        'outstanding': FieldValue.increment(amount),
      });
    }

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
    final docId = "EXP_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection('expenses').doc(docId).set({
      'itemName': itemName,
      'category': category,
      'amount': amount,
      'date': date,
    });
    
    if (category == "Rice Flour" && totalKg > 0.0) {
      await addRiceFlourBag(totalKg: totalKg, cost: amount, date: date);
    }
  }

  // 5. Summary & Cloud Sync State
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _syncSuccessful = false;
  bool get syncSuccessful => _syncSuccessful;

  String _googleSheetsUrl = "https://script.google.com/macros/s/AKfycbzFfKWeB7lmNtbqPTwKuz0m58DcQRqRpWaxDNbk4LQEcsLcmV_pY4l-MbHnIfOQ7CTWvA/exec";
  String get googleSheetsUrl => _googleSheetsUrl;

  void setGoogleSheetsUrl(String url) {
    _googleSheetsUrl = url.trim();
    notifyListeners();
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

  Future<void> addRiceFlourBag({
    required double totalKg,
    required double cost,
    required String date,
  }) async {
    // 1. Mark previous active bags completed
    for (var bag in _riceBags) {
      if (bag.status == "Active") {
        await _firestore.collection('riceBags').doc(bag.bagId).update({
          'status': 'Completed',
          'endDate': date,
        });
      }
    }

    // 2. Instantiate new active bag
    final bagId = "BAG_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection('riceBags').doc(bagId).set({
      'totalKg': totalKg,
      'usedKg': 0.0,
      'remainingKg': totalKg,
      'startDate': date,
      'status': 'Active',
      'cost': cost,
    });
  }

  Future<void> addDailyUsage({
    required double usedKg,
    required String date,
  }) async {
    final activeBag = activeRiceBag;
    if (activeBag == null) return;

    final usageId = "USE_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection('dailyUsages').doc(usageId).set({
      'bagId': activeBag.bagId,
      'date': date,
      'usedKg': usedKg,
    });

    final newUsed = activeBag.usedKg + usedKg;
    final newRemaining = activeBag.remainingKg - usedKg;
    final status = newRemaining <= 0.0 ? 'Completed' : 'Active';
    final endDate = newRemaining <= 0.0 ? date : null;

    final Map<String, dynamic> updates = {
      'usedKg': newUsed,
      'remainingKg': newRemaining < 0.0 ? 0.0 : newRemaining,
      'status': status,
    };
    if (endDate != null) {
      updates['endDate'] = endDate;
    }

    await _firestore.collection('riceBags').doc(activeBag.bagId).update(updates);
  }

  Future<void> closeAndStartNewBag({
    required double totalKg,
    required String date,
  }) async {
    // Complete active bag
    final activeBag = activeRiceBag;
    if (activeBag != null) {
      await _firestore.collection('riceBags').doc(activeBag.bagId).update({
        'status': 'Completed',
        'endDate': date,
      });
    }

    // Start a new bag with zero cost
    final bagId = "BAG_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection('riceBags').doc(bagId).set({
      'totalKg': totalKg,
      'usedKg': 0.0,
      'remainingKg': totalKg,
      'startDate': date,
      'status': 'Active',
      'cost': 0.0,
    });
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
        return log.dateTime.year == date.year && log.dateTime.month == date.month;
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
        "deliveryLogs": _deliveryLogs.map((log) => log.toJson()).toList(),
        "expenses": _expenses.map((exp) => exp.toJson()).toList(),
        "riceBags": _riceBags.map((bag) => bag.toJson()).toList(),
      };

      final bodyData = json.encode(payload);
      http.Response response;

      if (kIsWeb) {
        response = await http.post(
          Uri.parse(_googleSheetsUrl),
          headers: {"Content-Type": "application/json"},
          body: bodyData,
        );
      } else {
        var targetUrl = _googleSheetsUrl;
        final client = http.Client();

        var request = http.Request('POST', Uri.parse(targetUrl))
          ..headers['Content-Type'] = 'application/json'
          ..body = bodyData
          ..followRedirects = false;

        var streamedResponse = await client.send(request);
        response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307 || response.statusCode == 308 || response.statusCode == 303) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl != null) {
            var redirectRequest = http.Request('POST', Uri.parse(redirectUrl))
              ..headers['Content-Type'] = 'application/json'
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
      final query = await _firestore.collection('deliveryLogs')
          .where('serialNo', isEqualTo: serialNo)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final customerName = data['customerName'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final isPaid = data['isPaid'] as bool? ?? false;

        // Delete from Firestore
        await doc.reference.delete();

        // If unpaid, reduce customer's outstanding balance
        if (!isPaid && customerName != null) {
          await _firestore.collection('customers').doc(customerName).update({
            'outstanding': FieldValue.increment(-amount),
          });
        }
      }
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
    }
  }

  // Edit transaction globally by its unique Serial Number
  Future<void> editTransactionBySerialNo(int serialNo, String newDetails, double newAmount) async {
    try {
      final query = await _firestore.collection('deliveryLogs')
          .where('serialNo', isEqualTo: serialNo)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final customerName = data['customerName'] as String?;
        final oldAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final isPaid = data['isPaid'] as bool? ?? false;

        // Update in Firestore
        await doc.reference.update({
          'itemName': newDetails,
          'amount': newAmount,
        });

        // If unpaid, adjust customer's outstanding balance difference
        if (!isPaid && customerName != null) {
          final diff = newAmount - oldAmount;
          await _firestore.collection('customers').doc(customerName).update({
            'outstanding': FieldValue.increment(diff),
          });
        }
      }
    } catch (e) {
      debugPrint("Error editing transaction: $e");
    }
  }

  // Calculated Stats
  double get todaySales => _deliveryLogs.where((l) {
    final now = DateTime.now();
    return l.dateTime.day == now.day && 
           l.dateTime.month == now.month && 
           l.dateTime.year == now.year;
  }).fold(0.0, (total, log) => total + log.amount);

  int get todayDeliveriesCount => _deliveryLogs.where((l) {
    final now = DateTime.now();
    return l.dateTime.day == now.day && 
           l.dateTime.month == now.month && 
           l.dateTime.year == now.year;
  }).length;

  int get todayReturnsCount => 0;
}
