import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ledgerflow/core/models/owner_finance_model.dart';
import 'package:ledgerflow/core/repositories/owner_finance_repository.dart';

class FirestoreOwnerFinanceRepository implements OwnerFinanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String businessId;

  FirestoreOwnerFinanceRepository({required this.businessId});

  String _getCollectionPath(String collectionName) {
    if (businessId == 'business_1') {
      return collectionName;
    } else {
      return 'businesses/$businessId/$collectionName';
    }
  }

  @override
  Stream<OwnerLoanConfig?> getActiveLoanStream() {
    return _firestore
        .collection(_getCollectionPath('owner_loans'))
        .doc('default_owner_loan')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return OwnerLoanConfig.fromJson(snapshot.data()!);
    });
  }

  @override
  Future<void> updateNotes(String loanId, String notes) async {
    await _firestore.collection(_getCollectionPath('owner_loans')).doc(loanId).update({
      'notes': notes,
    });
  }

  @override
  Future<void> addRepayment(String loanId, RepaymentLog repayment) async {
    final loanRef = _firestore.collection(_getCollectionPath('owner_loans')).doc(loanId);
    final repaymentRef = loanRef.collection('repayments').doc(repayment.id);

    final batch = _firestore.batch();
    batch.set(repaymentRef, repayment.toJson());
    batch.update(loanRef, {
      'amountRepaid': FieldValue.increment(repayment.amountPaid),
    });
    await batch.commit();
  }

  @override
  Future<void> updateTotalBorrowed(String loanId, double totalBorrowed) async {
    await _firestore.collection(_getCollectionPath('owner_loans')).doc(loanId).update({
      'totalBorrowed': totalBorrowed,
    });
  }

  @override
  Stream<List<RepaymentLog>> getRepaymentsStream(String loanId) {
    return _firestore
        .collection(_getCollectionPath('owner_loans'))
        .doc(loanId)
        .collection('repayments')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => RepaymentLog.fromJson(doc.data())).toList();
      // Sort in memory descending by date
      list.sort((a, b) => b.repaymentDate.compareTo(a.repaymentDate));
      return list;
    });
  }

  @override
  Future<void> initDefaultLoanConfigIfEmpty() async {
    final docRef = _firestore.collection(_getCollectionPath('owner_loans')).doc('default_owner_loan');
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      final defaultLoan = OwnerLoanConfig(
        id: 'default_owner_loan',
        description: 'Owner Capital Fund',
        totalBorrowed: 0.0,
        amountRepaid: 0.0,
        notes: 'Workspace for owner business logs and notes. Start tracking installments below.',
        createdAt: DateTime.now(),
      );
      await docRef.set(defaultLoan.toJson());
    } else {
      // Auto-heal database: if it's currently matching the old default value of 150000.0, reset it to 0.0
      final data = snapshot.data();
      if (data != null) {
        final total = (data['totalBorrowed'] as num?)?.toDouble() ?? 0.0;
        if (total == 150000.0) {
          await docRef.update({'totalBorrowed': 0.0});
        }
      }
    }
  }

  @override
  Future<OwnerLoanConfig?> getActiveLoan() async {
    final snapshot = await _firestore
        .collection(_getCollectionPath('owner_loans'))
        .doc('default_owner_loan')
        .get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return OwnerLoanConfig.fromJson(snapshot.data()!);
  }

  @override
  Future<List<RepaymentLog>> getRepayments(String loanId) async {
    final snapshot = await _firestore
        .collection(_getCollectionPath('owner_loans'))
        .doc(loanId)
        .collection('repayments')
        .get();
    final list = snapshot.docs.map((doc) => RepaymentLog.fromJson(doc.data())).toList();
    // Sort in memory descending by date
    list.sort((a, b) => b.repaymentDate.compareTo(a.repaymentDate));
    return list;
  }

  @override
  Stream<List<SavingsLog>> getSavingsLogsStream() {
    return _firestore
        .collection(_getCollectionPath('savings_logs'))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => SavingsLog.fromJson(doc.data())).toList();
      // Sort descending by date
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  @override
  Future<void> addSavingsLog(SavingsLog log) async {
    await _firestore
        .collection(_getCollectionPath('savings_logs'))
        .doc(log.id)
        .set(log.toJson());
  }

  @override
  Stream<SavingsRecommendation?> getPendingSavingsRecommendationStream(String date) {
    return _firestore
        .collection(_getCollectionPath('savings_recommendations'))
        .doc(date)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final data = snapshot.data()!;
      final status = data['status'] ?? 'pending';
      if (status == 'pending') {
        return SavingsRecommendation.fromJson(data, snapshot.id);
      }
      return null;
    });
  }

  @override
  Future<void> updateSavingsRecommendationStatus(String date, String status, int? transferredAmount) async {
    final Map<String, dynamic> updates = {
      'status': status,
      'processed_at': DateTime.now().toIso8601String(),
    };
    if (transferredAmount != null) {
      updates['transferred_amount'] = transferredAmount;
    }
    await _firestore
        .collection(_getCollectionPath('savings_recommendations'))
        .doc(date)
        .update(updates);
  }
}

