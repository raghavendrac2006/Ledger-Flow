import 'dart:async';
import 'package:flutter/material.dart';

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
}

class DeliveryLog {
  final int serialNo;
  final String date;
  final DateTime dateTime;
  final String itemName;
  final String customerName;
  final double amount;
  final bool isPaid;

  DeliveryLog({
    required this.serialNo,
    required this.date,
    required this.dateTime,
    required this.itemName,
    required this.customerName,
    required this.amount,
    required this.isPaid,
  });
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
}

class LedgerState extends ChangeNotifier {
  LedgerState() {
    _prepopulateMockHistoricalData();
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
  final List<Customer> _customers = [
    Customer(name: "Ramchandra", type: "RETAIL", area: "Downtown", outstanding: 0.00, icon: Icons.person, location: "Sector 4, Main Market"),
    Customer(name: "Lachy", type: "WHOLESALE", area: "Westside", outstanding: 0.00, icon: Icons.person, location: "West Hub Center"),
    Customer(name: "Bava", type: "RETAIL", area: "Market Square", outstanding: 0.00, icon: Icons.person, location: "Stall 14, Market Square"),
    Customer(name: "Santosh", type: "CORPORATE", area: "Block 4", outstanding: 0.00, icon: Icons.person, location: "Block 4 Corporate Plaza"),
    Customer(name: "Murali pes", type: "MINI-MART", area: "East Side", outstanding: 0.00, icon: Icons.store, location: "East Cross Road"),
    Customer(name: "Supermarket pes", type: "WHOLESALE", area: "City Center", outstanding: 0.00, icon: Icons.shopping_cart, location: "Basement, City Mall"),
    Customer(name: "Bakery pes", type: "RETAIL", area: "High Street", outstanding: 0.00, icon: Icons.bakery_dining, location: "12 High Street"),
    Customer(name: "Down shop pes", type: "MINI-MART", area: "South Gate", outstanding: 0.00, icon: Icons.storefront, location: "Near South Gate Station"),
    Customer(name: "Milk", type: "DISTRIBUTION", area: "Dairy Hub", outstanding: 0.00, icon: Icons.local_drink, location: "Plot 42, Dairy Industrial Estate"),
    Customer(name: "Lakshmi puram", type: "AREA AGENT", area: "Lakshmi District", outstanding: 0.00, icon: Icons.location_on, location: "Area Agency Office"),
    Customer(name: "showkath", type: "RETAIL", area: "West Hub", outstanding: 0.00, icon: Icons.person, location: "West Street Corner"),
    Customer(name: "Factory", type: "MANUFACTURING", area: "Industrial Zone", outstanding: 0.00, icon: Icons.factory, location: "Shed 3B, Industrial Area"),
  ];
  List<Customer> get customers => _customers;

  void addCustomer({
    required String name,
    String type = "RETAIL",
    String area = "Custom Area",
  }) {
    final cleanName = name.trim();
    if (cleanName.isNotEmpty && !_customers.any((c) => c.name.toLowerCase() == cleanName.toLowerCase())) {
      _customers.add(
        Customer(
          name: cleanName,
          type: type,
          area: area,
          outstanding: 0.0,
          icon: Icons.person,
          location: "Added via Sales",
        ),
      );
      notifyListeners();
    }
  }

  // Transaction history for customer details page
  final Map<String, List<Transaction>> _customerTransactions = {};

  List<Transaction> getTransactionsForCustomer(String name) {
    return _customerTransactions[name] ?? [];
  }

  void deleteTransaction(String customerName, int index) {
    if (_customerTransactions.containsKey(customerName)) {
      final list = _customerTransactions[customerName];
      if (list != null && index < list.length) {
        final tx = list[index];
        
        // If it was UNPAID, reduce outstanding balance
        if (!tx.isPaid) {
          final customerIndex = _customers.indexWhere((c) => c.name == customerName);
          if (customerIndex != -1) {
            _customers[customerIndex].outstanding -= tx.amount;
            if (_customers[customerIndex].outstanding < 0) {
              _customers[customerIndex].outstanding = 0.0;
            }
          }
        }
        
        list.removeAt(index);
        
        // Also remove from global delivery logs to keep PDF and Summary matched
        _deliveryLogs.removeWhere((log) => 
          log.customerName == customerName && 
          log.amount == tx.amount && 
          log.isPaid == tx.isPaid
        );
        
        notifyListeners();
      }
    }
  }

  void editTransaction({
    required String customerName,
    required int index,
    required String newDetails,
    required double newAmount,
  }) {
    if (_customerTransactions.containsKey(customerName)) {
      final list = _customerTransactions[customerName];
      if (list != null && index < list.length) {
        final tx = list[index];
        final oldAmount = tx.amount;
        final wasPaid = tx.isPaid;
        
        // Recalculate outstanding balance difference
        if (!wasPaid) {
          final customerIndex = _customers.indexWhere((c) => c.name == customerName);
          if (customerIndex != -1) {
            _customers[customerIndex].outstanding -= oldAmount;
            _customers[customerIndex].outstanding += newAmount;
            if (_customers[customerIndex].outstanding < 0) {
              _customers[customerIndex].outstanding = 0.0;
            }
          }
        }
        
        tx.details = newDetails;
        tx.amount = newAmount;
        
        // Update corresponding global delivery log entry
        final logIndex = _deliveryLogs.indexWhere((log) => 
          log.customerName == customerName && 
          log.amount == oldAmount && 
          log.isPaid == wasPaid
        );
        if (logIndex != -1) {
          final oldLog = _deliveryLogs[logIndex];
          _deliveryLogs[logIndex] = DeliveryLog(
            serialNo: oldLog.serialNo,
            date: oldLog.date,
            dateTime: oldLog.dateTime,
            itemName: newDetails.replaceAll("1x ", ""),
            customerName: oldLog.customerName,
            amount: newAmount,
            isPaid: oldLog.isPaid,
          );
        }
        
        notifyListeners();
      }
    }
  }

  void markTransactionAsPaid(String customerName, int index) {
    final list = _customerTransactions[customerName];
    if (list != null && index < list.length) {
      final tx = list[index];
      if (!tx.isPaid) {
        tx.isPaid = true;
        // Reduce outstanding balance
        final customerIndex = _customers.indexWhere((c) => c.name == customerName);
        if (customerIndex != -1) {
          _customers[customerIndex].outstanding -= tx.amount;
          if (_customers[customerIndex].outstanding < 0) {
            _customers[customerIndex].outstanding = 0;
          }
        }
        notifyListeners();
      }
    }
  }

  void addDeliveryLog({
    required String customerName,
    required String itemName,
    required double amount,
    required bool isPaid,
  }) {
    final log = DeliveryLog(
      serialNo: _serialNumber,
      date: "${_deliveryDate.day} ${_getMonthName(_deliveryDate.month)} ${_deliveryDate.year}",
      dateTime: _deliveryDate,
      itemName: itemName,
      customerName: customerName,
      amount: amount,
      isPaid: isPaid,
    );
    _deliveryLogs.insert(0, log);
    
    // Add to outstanding if NOT PAID
    if (!isPaid) {
      final customerIndex = _customers.indexWhere((c) => c.name == customerName);
      if (customerIndex != -1) {
        _customers[customerIndex].outstanding += amount;
      }
      
      // Also add to transactions list
      if (!_customerTransactions.containsKey(customerName)) {
        _customerTransactions[customerName] = [];
      }
      _customerTransactions[customerName]!.insert(
        0,
        Transaction(
          date: "${_deliveryDate.day} ${_getMonthName(_deliveryDate.month).toUpperCase()} ${_deliveryDate.year}",
          details: "1x $itemName",
          amount: amount,
          isPaid: false,
        ),
      );
    } else {
      // Add to transactions list as paid
      if (!_customerTransactions.containsKey(customerName)) {
        _customerTransactions[customerName] = [];
      }
      _customerTransactions[customerName]!.insert(
        0,
        Transaction(
          date: "${_deliveryDate.day} ${_getMonthName(_deliveryDate.month).toUpperCase()} ${_deliveryDate.year}",
          details: "1x $itemName",
          amount: amount,
          isPaid: true,
        ),
      );
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

  // Prepopulate 30 days of mock sales for robust range export tests
  void _prepopulateMockHistoricalData() {
    // Left empty for a completely clean start as requested by the user
  }

  // 4. Expenditures Database
  final List<String> _expenseCategories = ["RICE", "Cylinders", "Transportation"];
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

  void addExpense({
    required String itemName,
    required String category,
    required double amount,
    required String date,
  }) {
    _expenses.insert(
      0,
      ExpenseLog(itemName: itemName, category: category, amount: amount, date: date),
    );
    notifyListeners();
  }

  // 5. Summary & Cloud Sync State
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _syncSuccessful = false;
  bool get syncSuccessful => _syncSuccessful;

  void triggerSync() {
    _isSyncing = true;
    notifyListeners();

    Timer(const Duration(seconds: 2), () {
      _isSyncing = false;
      _syncSuccessful = true;
      notifyListeners();
    });
  }

  void closeSyncOverlay() {
    _syncSuccessful = false;
    notifyListeners();
  }

  // Calculated Stats
  double get todaySales => _deliveryLogs.where((l) {
    // Today's logs
    final now = DateTime.now();
    return l.dateTime.day == now.day && 
           l.dateTime.month == now.month && 
           l.dateTime.year == now.year;
  }).fold(0.0, (sum, log) => sum + log.amount);

  int get todayDeliveriesCount => _deliveryLogs.where((l) {
    final now = DateTime.now();
    return l.dateTime.day == now.day && 
           l.dateTime.month == now.month && 
           l.dateTime.year == now.year;
  }).length;

  int get todayReturnsCount => 0;
}
