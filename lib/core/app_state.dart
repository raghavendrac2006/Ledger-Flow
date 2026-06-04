import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String toSentenceCase(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.length == 1) return trimmed.toUpperCase();
  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}

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
  bool isPayment;

  Transaction({
    required this.date,
    required this.details,
    required this.amount,
    required this.isPaid,
    this.isPayment = false,
  });

  Map<String, dynamic> toJson() => {
    "date": date,
    "details": details,
    "amount": amount,
    "isPaid": isPaid,
    "isPayment": isPayment,
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
  bool isPayment;

  DeliveryLog({
    required this.serialNo,
    required this.date,
    required this.dateTime,
    required this.itemName,
    required this.customerName,
    required this.amount,
    required this.isPaid,
    this.associatedBagId,
    this.isPayment = false,
  });

  Map<String, dynamic> toJson() => {
    "serialNo": serialNo,
    "date": date,
    "dateTime": dateTime.toIso8601String(),
    "itemName": itemName,
    "customerName": customerName,
    "amount": amount,
    "isPaid": isPaid,
    "isPayment": isPayment,
  };
}

class ExpenseLog {
  final String? expenseId;
  final String itemName;
  final String category; // RICE, Cylinders, Transportation
  final double amount;
  final String date;
  final String? associatedBagId;

  ExpenseLog({
    this.expenseId,
    required this.itemName,
    required this.category,
    required this.amount,
    required this.date,
    this.associatedBagId,
  });

  Map<String, dynamic> toJson() => {
    "itemName": itemName,
    "category": category,
    "amount": amount,
    "date": date,
    "associatedBagId": associatedBagId,
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
  final int? bagNumber;
  final double? revenue;
  final double? expenses;
  final double? profit;
  final double? profitMargin;

  RiceBag({
    required this.bagId,
    required this.totalKg,
    this.usedKg = 0.0,
    required this.remainingKg,
    required this.startDate,
    this.endDate,
    this.status = "Active",
    required this.cost,
    this.bagNumber,
    this.revenue,
    this.expenses,
    this.profit,
    this.profitMargin,
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
    "bagNumber": bagNumber,
    "revenue": revenue,
    "expenses": expenses,
    "profit": profit,
    "profitMargin": profitMargin,
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
    runSentenceCaseMigration();
  }

  // Firestore instances & stream subscriptions
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _customersSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _bagsSub;
  StreamSubscription? _usagesSub;
  StreamSubscription? _statsSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _expenseSuggestionsSub;

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
          final isPayment = data['isPayment'] ?? false;

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
            isPayment: isPayment,
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
            details: log.isPayment ? log.itemName : "1x ${log.itemName}",
            amount: log.amount,
            isPaid: log.isPaid,
            isPayment: log.isPayment,
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
            expenseId: doc.id,
            itemName: data['itemName'] ?? '',
            category: data['category'] ?? '',
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            date: data['date'] ?? '',
            associatedBagId: data['associatedBagId'] as String?,
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
            bagNumber: data['bagNumber'] as int?,
            revenue: (data['revenue'] as num?)?.toDouble(),
            expenses: (data['expenses'] as num?)?.toDouble(),
            profit: (data['profit'] as num?)?.toDouble(),
            profitMargin: (data['profitMargin'] as num?)?.toDouble(),
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

    // 9. Listen to Settings Collection (specifically the googleSheets document)
    _settingsSub = _firestore.collection('settings').doc('googleSheets').snapshots().listen(
      (snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final url = data['url'] as String?;
          if (url != null && url.isNotEmpty) {
            _googleSheetsUrl = url;
            notifyListeners();
          }
        } else {
          // Document does not exist yet. Seed it with the default URL.
          try {
            await _firestore.collection('settings').doc('googleSheets').set({
              'url': _googleSheetsUrl,
            });
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
    _expenseSuggestionsSub = _firestore.collection('settings').doc('expenseItems').snapshots().listen(
      (snapshot) async {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final list = List<String>.from(data['items'] ?? []);
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
            await _firestore.collection('settings').doc('expenseItems').set({
              'items': defaultItems,
            });
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

  Future<void> runSentenceCaseMigration() async {
    debugPrint("--- STARTING DATABASE SENTENCE CASE MIGRATION ---");
    try {
      // 1. Migrate settings/expenseItems suggestions
      final suggestionsDoc = await _firestore.collection('settings').doc('expenseItems').get();
      if (suggestionsDoc.exists && suggestionsDoc.data() != null) {
        final data = suggestionsDoc.data()!;
        final rawItems = List<String>.from(data['items'] ?? []);
        final migratedSuggestions = rawItems
            .map((item) => toSentenceCase(item))
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
        await _firestore.collection('settings').doc('expenseItems').set({
          'items': migratedSuggestions,
        });
        debugPrint("Migrated expense suggestions: $migratedSuggestions");
      }

      // 2. Migrate customers collection (and consolidate duplicates)
      final customersSnapshot = await _firestore.collection('customers').get();
      final Map<String, List<DocumentSnapshot>> groupedCustomers = {};
      for (var doc in customersSnapshot.docs) {
        final name = doc.data()['name'] as String? ?? doc.id;
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
          totalOutstanding += (doc.data() as Map<String, dynamic>?)?['outstanding'] as num? ?? 0.0;
        }

        // Get template fields from first document
        final firstData = docs.first.data() as Map<String, dynamic>;
        final type = firstData['type'] ?? 'RETAIL';
        final area = firstData['area'] ?? '';
        final location = firstData['location'] ?? '';

        // Write the consolidated sentence-cased customer
        await _firestore.collection('customers').doc(casedName).set({
          'name': casedName,
          'type': type,
          'area': area,
          'outstanding': totalOutstanding,
          'location': location,
        });

        // Delete old customer docs if they were cased differently, and update their logs
        for (var doc in docs) {
          if (doc.id != casedName) {
            // Find and update delivery logs
            final logsSnapshot = await _firestore.collection('deliveryLogs')
                .where('customerName', isEqualTo: doc.id)
                .get();
            
            final batch = _firestore.batch();
            for (var logDoc in logsSnapshot.docs) {
              batch.update(logDoc.reference, {'customerName': casedName});
            }
            await batch.commit();

            // Delete old customer doc
            await doc.reference.delete();
          }
        }
      }
      debugPrint("Migrated customers collection successfully.");

      // 3. Migrate deliveryLogs (itemName & customerName case correction)
      final logsSnapshot = await _firestore.collection('deliveryLogs').get();
      final logsBatch = _firestore.batch();
      int logsBatchCount = 0;
      for (var doc in logsSnapshot.docs) {
        final data = doc.data();
        final currentCustomerName = data['customerName'] as String? ?? '';
        final currentItemName = data['itemName'] as String? ?? '';
        
        final casedCustomer = toSentenceCase(currentCustomerName);
        final casedItem = (currentItemName.toLowerCase() == "cash collected") 
            ? "Cash Collected" 
            : toSentenceCase(currentItemName);

        if (casedCustomer != currentCustomerName || casedItem != currentItemName) {
          logsBatch.update(doc.reference, {
            'customerName': casedCustomer,
            'itemName': casedItem,
          });
          logsBatchCount++;
          if (logsBatchCount >= 400) {
            await logsBatch.commit();
            logsBatchCount = 0;
          }
        }
      }
      if (logsBatchCount > 0) {
        await logsBatch.commit();
      }
      debugPrint("Migrated delivery logs successfully.");

      // 4. Migrate expenses collection (itemName case correction)
      final expensesSnapshot = await _firestore.collection('expenses').get();
      final expensesBatch = _firestore.batch();
      int expensesBatchCount = 0;
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final currentItemName = data['itemName'] as String? ?? '';
        final casedItemName = toSentenceCase(currentItemName);
        if (casedItemName != currentItemName) {
          expensesBatch.update(doc.reference, {
            'itemName': casedItemName,
          });
          expensesBatchCount++;
          if (expensesBatchCount >= 400) {
            await expensesBatch.commit();
            expensesBatchCount = 0;
          }
        }
      }
      if (expensesBatchCount > 0) {
        await expensesBatch.commit();
      }
      debugPrint("Migrated expenses successfully.");

    } catch (e) {
      debugPrint("Error running sentence case migration: $e");
    }
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
    _settingsSub?.cancel();
    _expenseSuggestionsSub?.cancel();
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
            .where('isPayment', isEqualTo: tx.isPayment)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.delete();
        }

        // Adjust outstanding balance
        if (tx.isPayment) {
          // Deleting a payment increases the customer's outstanding balance
          await _firestore.collection('customers').doc(customerName).update({
            'outstanding': FieldValue.increment(tx.amount),
          });
        } else if (!tx.isPaid) {
          // Deleting an unpaid sale reduces the customer's outstanding balance
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
            .where('isPayment', isEqualTo: tx.isPayment)
            .limit(1)
            .get();
        
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'itemName': tx.isPayment ? newDetails : newDetails.replaceAll("1x ", ""),
            'amount': newAmount,
          });
        }

        // Recalculate outstanding balance difference
        if (tx.isPayment) {
          // Editing a payment: if new payment amount is higher, outstanding balance decreases
          final diff = oldAmount - newAmount;
          await _firestore.collection('customers').doc(customerName).update({
            'outstanding': FieldValue.increment(diff),
          });
        } else if (!wasPaid) {
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
    final cleanCustomer = toSentenceCase(customerName);
    final cleanItem = toSentenceCase(itemName);
    final activeBag = activeRiceBag;
    final docId = "LOG_${DateTime.now().millisecondsSinceEpoch}";
    final dateStr = "${_deliveryDate.day} ${_getMonthName(_deliveryDate.month)} ${_deliveryDate.year}";

    // 1. Save log to Firestore
    await _firestore.collection('deliveryLogs').doc(docId).set({
      'serialNo': _serialNumber,
      'date': dateStr,
      'dateTime': _deliveryDate.toIso8601String(),
      'itemName': cleanItem,
      'customerName': cleanCustomer,
      'amount': amount,
      'isPaid': isPaid,
      'associatedBagId': activeBag?.bagId,
    });

    // 2. Increment customer outstanding if unpaid
    if (!isPaid) {
      await _firestore.collection('customers').doc(cleanCustomer).update({
        'outstanding': FieldValue.increment(amount),
      });
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
    final docId = "PAY_${DateTime.now().millisecondsSinceEpoch}";
    final dateStr = "${date.day} ${_getMonthName(date.month)} ${date.year}";

    // 1. Save payment log to Firestore
    await _firestore.collection('deliveryLogs').doc(docId).set({
      'serialNo': _serialNumber,
      'date': dateStr,
      'dateTime': date.toIso8601String(),
      'itemName': "Cash Collected",
      'customerName': cleanCustomer,
      'amount': amount,
      'isPaid': true,
      'isPayment': true,
      'associatedBagId': null,
    });

    // 2. Reduce customer outstanding balance
    await _firestore.collection('customers').doc(cleanCustomer).update({
      'outstanding': FieldValue.increment(-amount),
    });

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
        await _firestore.collection('settings').doc('expenseItems').set({
          'items': _expenseSuggestions,
        });
      } catch (e) {
        debugPrint("Error saving expense item to Firestore: $e");
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
    final docId = "EXP_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection('expenses').doc(docId).set({
      'itemName': cleanItemName,
      'category': category,
      'amount': amount,
      'date': date,
      'associatedBagId': activeBag?.bagId,
    });
    
    if (category == "Rice Flour" && totalKg > 0.0) {
      await addRiceFlourBag(totalKg: totalKg, cost: amount, date: date);
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required String newItemName,
    required double newAmount,
  }) async {
    final casedName = toSentenceCase(newItemName);
    try {
      await _firestore.collection('expenses').doc(expenseId).update({
        'itemName': casedName,
        'amount': newAmount,
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating expense: $e");
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
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
      await _firestore.collection('settings').doc('googleSheets').set({'url': cleanUrl});
    } catch (e) {
      debugPrint("Error saving Sheets URL to Firestore: $e");
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
    // Dynamic calculations for the bag right before completion
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

    final updates = {
      'status': 'Completed',
      'endDate': endDate,
      'revenue': revenue,
      'expenses': expenses,
      'profit': profit,
      'profitMargin': profitMargin,
      'bagNumber': bagNum,
      ...additionalUpdates,
    };
    await _firestore.collection('riceBags').doc(bag.bagId).update(updates);
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
    await _firestore.collection('riceBags').doc(bagId).set({
      'totalKg': totalKg,
      'usedKg': 0.0,
      'remainingKg': totalKg,
      'startDate': date,
      'status': 'Active',
      'cost': cost,
      'bagNumber': nextBagNum,
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

    if (newRemaining <= 0.0) {
      await _completeBag(activeBag, date, {
        'usedKg': newUsed,
        'remainingKg': 0.0,
      });
    } else {
      await _firestore.collection('riceBags').doc(activeBag.bagId).update({
        'usedKg': newUsed,
        'remainingKg': newRemaining,
        'status': 'Active',
      });
    }
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
    await _firestore.collection('riceBags').doc(bagId).set({
      'totalKg': totalKg,
      'usedKg': 0.0,
      'remainingKg': totalKg,
      'startDate': date,
      'status': 'Active',
      'cost': 0.0,
      'bagNumber': nextBagNum,
    });
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
        final isPayment = data['isPayment'] as bool? ?? false;

        // Delete from Firestore
        await doc.reference.delete();

        // Adjust outstanding balance
        if (customerName != null) {
          if (isPayment) {
            await _firestore.collection('customers').doc(customerName).update({
              'outstanding': FieldValue.increment(amount),
            });
          } else if (!isPaid) {
            await _firestore.collection('customers').doc(customerName).update({
              'outstanding': FieldValue.increment(-amount),
            });
          }
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
        final isPayment = data['isPayment'] as bool? ?? false;

        // Update in Firestore
        await doc.reference.update({
          'itemName': newDetails,
          'amount': newAmount,
        });

        // Adjust outstanding balance difference
        if (customerName != null) {
          if (isPayment) {
            final diff = oldAmount - newAmount;
            await _firestore.collection('customers').doc(customerName).update({
              'outstanding': FieldValue.increment(diff),
            });
          } else if (!isPaid) {
            final diff = newAmount - oldAmount;
            await _firestore.collection('customers').doc(customerName).update({
              'outstanding': FieldValue.increment(diff),
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error editing transaction: $e");
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
}
