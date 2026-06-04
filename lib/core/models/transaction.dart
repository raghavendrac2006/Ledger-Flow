class Transaction {
  final String date;
  final String details;
  final double amount;
  final bool isPaid;
  final bool isPayment;

  Transaction({
    required this.date,
    required this.details,
    required this.amount,
    required this.isPaid,
    this.isPayment = false,
  });

  Transaction copyWith({
    String? date,
    String? details,
    double? amount,
    bool? isPaid,
    bool? isPayment,
  }) {
    return Transaction(
      date: date ?? this.date,
      details: details ?? this.details,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      isPayment: isPayment ?? this.isPayment,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['date'] ?? '',
      details: json['details'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] ?? false,
      isPayment: json['isPayment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "details": details,
      "amount": amount,
      "isPaid": isPaid,
      "isPayment": isPayment,
    };
  }
}

