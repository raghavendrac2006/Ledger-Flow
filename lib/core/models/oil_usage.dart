class OilUsage {
  final String? usageId;
  final double liters;
  final String date;
  final String? notes;
  final String? associatedBagId;

  OilUsage({
    this.usageId,
    required this.liters,
    required this.date,
    this.notes,
    this.associatedBagId,
  });

  OilUsage copyWith({
    String? usageId,
    double? liters,
    String? date,
    String? notes,
    String? associatedBagId,
  }) {
    return OilUsage(
      usageId: usageId ?? this.usageId,
      liters: liters ?? this.liters,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      associatedBagId: associatedBagId ?? this.associatedBagId,
    );
  }

  factory OilUsage.fromJson(Map<String, dynamic> json, {String? id}) {
    return OilUsage(
      usageId: id ?? json['usageId'],
      liters: (json['liters'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? '',
      notes: json['notes'] as String?,
      associatedBagId: json['associatedBagId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "liters": liters,
      "date": date,
      "notes": notes,
      if (associatedBagId != null) "associatedBagId": associatedBagId,
    };
  }
}
