class RiceBag {
  final String bagId;
  final String flourType;
  final double totalKg;
  final double usedKg;
  final double remainingKg;
  final String startDate;
  final String? endDate;
  final String status; // "Active" | "Completed"
  final double cost;
  final int? bagNumber;
  final double? revenue;
  final double? expenses;
  final double? profit;
  final double? profitMargin;
  final double? lpgCylinderKg;

  RiceBag({
    required this.bagId,
    this.flourType = "₹1 Rice Flour",
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
    this.lpgCylinderKg,
  });

  RiceBag copyWith({
    String? bagId,
    String? flourType,
    double? totalKg,
    double? usedKg,
    double? remainingKg,
    String? startDate,
    String? endDate,
    String? status,
    double? cost,
    int? bagNumber,
    double? revenue,
    double? expenses,
    double? profit,
    double? profitMargin,
    double? lpgCylinderKg,
  }) {
    return RiceBag(
      bagId: bagId ?? this.bagId,
      flourType: flourType ?? this.flourType,
      totalKg: totalKg ?? this.totalKg,
      usedKg: usedKg ?? this.usedKg,
      remainingKg: remainingKg ?? this.remainingKg,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      bagNumber: bagNumber ?? this.bagNumber,
      revenue: revenue ?? this.revenue,
      expenses: expenses ?? this.expenses,
      profit: profit ?? this.profit,
      profitMargin: profitMargin ?? this.profitMargin,
      lpgCylinderKg: lpgCylinderKg ?? this.lpgCylinderKg,
    );
  }

  factory RiceBag.fromJson(Map<String, dynamic> json, {String? id}) {
    return RiceBag(
      bagId: id ?? json['bagId'] ?? '',
      flourType: json['flourType'] ?? '₹1 Rice Flour',
      totalKg: (json['totalKg'] as num?)?.toDouble() ?? 0.0,
      usedKg: (json['usedKg'] as num?)?.toDouble() ?? 0.0,
      remainingKg: (json['remainingKg'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      status: json['status'] ?? 'Active',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      bagNumber: json['bagNumber'] as int?,
      revenue: (json['revenue'] as num?)?.toDouble(),
      expenses: (json['expenses'] as num?)?.toDouble(),
      profit: (json['profit'] as num?)?.toDouble(),
      profitMargin: (json['profitMargin'] as num?)?.toDouble(),
      lpgCylinderKg: (json['lpgCylinderKg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "bagId": bagId,
      "flourType": flourType,
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
      "lpgCylinderKg": lpgCylinderKg,
    };
  }
}

