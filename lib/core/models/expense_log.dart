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

  ExpenseLog copyWith({
    String? expenseId,
    String? itemName,
    String? category,
    double? amount,
    String? date,
    String? associatedBagId,
  }) {
    return ExpenseLog(
      expenseId: expenseId ?? this.expenseId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      associatedBagId: associatedBagId ?? this.associatedBagId,
    );
  }

  factory ExpenseLog.fromJson(Map<String, dynamic> json, {String? id}) {
    return ExpenseLog(
      expenseId: id ?? json['expenseId'],
      itemName: json['itemName'] ?? '',
      category: json['category'] ?? 'General',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? '',
      associatedBagId: json['associatedBagId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "itemName": itemName,
      "category": category,
      "amount": amount,
      "date": date,
      "associatedBagId": associatedBagId,
    };
  }
}

