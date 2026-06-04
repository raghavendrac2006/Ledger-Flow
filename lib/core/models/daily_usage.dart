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

  DailyUsage copyWith({
    String? usageId,
    String? bagId,
    String? date,
    double? usedKg,
  }) {
    return DailyUsage(
      usageId: usageId ?? this.usageId,
      bagId: bagId ?? this.bagId,
      date: date ?? this.date,
      usedKg: usedKg ?? this.usedKg,
    );
  }

  factory DailyUsage.fromJson(Map<String, dynamic> json, {String? id}) {
    return DailyUsage(
      usageId: id ?? json['usageId'] ?? '',
      bagId: json['bagId'] ?? '',
      date: json['date'] ?? '',
      usedKg: (json['usedKg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "usageId": usageId,
      "bagId": bagId,
      "date": date,
      "usedKg": usedKg,
    };
  }
}

