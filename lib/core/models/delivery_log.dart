class DeliveryLog {
  final String? logId;
  final int serialNo;
  final String date;
  final DateTime dateTime;
  final String itemName;
  final String customerName;
  final double amount;
  final bool isPaid;
  final String? associatedBagId;
  final bool isPayment;

  DeliveryLog({
    this.logId,
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

  DeliveryLog copyWith({
    String? logId,
    int? serialNo,
    String? date,
    DateTime? dateTime,
    String? itemName,
    String? customerName,
    double? amount,
    bool? isPaid,
    String? associatedBagId,
    bool? isPayment,
  }) {
    return DeliveryLog(
      logId: logId ?? this.logId,
      serialNo: serialNo ?? this.serialNo,
      date: date ?? this.date,
      dateTime: dateTime ?? this.dateTime,
      itemName: itemName ?? this.itemName,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      associatedBagId: associatedBagId ?? this.associatedBagId,
      isPayment: isPayment ?? this.isPayment,
    );
  }

  factory DeliveryLog.fromJson(Map<String, dynamic> json, {String? id}) {
    return DeliveryLog(
      logId: id ?? json['logId'],
      serialNo: json['serialNo'] as int? ?? 0,
      date: json['date'] ?? '',
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      itemName: json['itemName'] ?? '',
      customerName: json['customerName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] ?? false,
      associatedBagId: json['associatedBagId'] as String?,
      isPayment: json['isPayment'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "serialNo": serialNo,
      "date": date,
      "dateTime": dateTime.toIso8601String(),
      "itemName": itemName,
      "customerName": customerName,
      "amount": amount,
      "isPaid": isPaid,
      "associatedBagId": associatedBagId,
      "isPayment": isPayment,
    };
  }
}

