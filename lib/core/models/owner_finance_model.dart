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

class SavingsLog {
  final String id;
  final double amount;
  final String type;
  final String notes;
  final DateTime date;

  SavingsLog({
    required this.id,
    required this.amount,
    required this.type,
    required this.notes,
    required this.date,
  });

  factory SavingsLog.fromJson(Map<String, dynamic> json) {
    return SavingsLog(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'deposit',
      notes: json['notes'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }
}

class SavingsRecommendation {
  final String date;
  final int suggestedSavings;
  final String conversationalReason;
  final String status;

  SavingsRecommendation({
    required this.date,
    required this.suggestedSavings,
    required this.conversationalReason,
    required this.status,
  });

  factory SavingsRecommendation.fromJson(Map<String, dynamic> json, String date) {
    return SavingsRecommendation(
      date: date,
      suggestedSavings: (json['suggested_savings'] as num?)?.toInt() ?? 0,
      conversationalReason: json['conversational_reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suggested_savings': suggestedSavings,
      'conversational_reason': conversationalReason,
      'status': status,
    };
  }
}


