class OwnerLoanConfig {
  final String id;
  final String description;
  final double totalBorrowed;
  final double amountRepaid;
  final String notes;
  final DateTime createdAt;

  OwnerLoanConfig({
    required this.id,
    required this.description,
    required this.totalBorrowed,
    required this.amountRepaid,
    required this.notes,
    required this.createdAt,
  });

  double get remainingBalance => totalBorrowed - amountRepaid;

  factory OwnerLoanConfig.fromJson(Map<String, dynamic> json) {
    return OwnerLoanConfig(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      totalBorrowed: (json['totalBorrowed'] as num?)?.toDouble() ?? 0.0,
      amountRepaid: (json['amountRepaid'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'totalBorrowed': totalBorrowed,
      'amountRepaid': amountRepaid,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  OwnerLoanConfig copyWith({
    String? id,
    String? description,
    double? totalBorrowed,
    double? amountRepaid,
    String? notes,
    DateTime? createdAt,
  }) {
    return OwnerLoanConfig(
      id: id ?? this.id,
      description: description ?? this.description,
      totalBorrowed: totalBorrowed ?? this.totalBorrowed,
      amountRepaid: amountRepaid ?? this.amountRepaid,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RepaymentLog {
  final String id;
  final double amountPaid;
  final DateTime repaymentDate;

  RepaymentLog({
    required this.id,
    required this.amountPaid,
    required this.repaymentDate,
  });

  factory RepaymentLog.fromJson(Map<String, dynamic> json) {
    return RepaymentLog(
      id: json['id'] as String? ?? '',
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      repaymentDate: json['repaymentDate'] != null
          ? DateTime.parse(json['repaymentDate'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountPaid': amountPaid,
      'repaymentDate': repaymentDate.toIso8601String(),
    };
  }
}
