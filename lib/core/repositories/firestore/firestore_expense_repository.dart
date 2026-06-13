import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/expense_log.dart';
import '../expense_repository.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String businessId;

  FirestoreExpenseRepository({required this.businessId});

  String _getCollectionPath(String collectionName) {
    if (businessId == 'business_1') {
      return collectionName;
    } else {
      return 'businesses/$businessId/$collectionName';
    }
  }

  @override
  Stream<List<ExpenseLog>> getExpensesStream() {
    return _firestore.collection(_getCollectionPath('expenses')).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExpenseLog.fromJson(doc.data(), id: doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addExpense(ExpenseLog expense) async {
    final docId = "EXP_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection(_getCollectionPath('expenses')).doc(docId).set(expense.toJson());
  }

  @override
  Future<void> updateExpense(String expenseId, String itemName, double amount) async {
    await _firestore.collection(_getCollectionPath('expenses')).doc(expenseId).update({
      'itemName': itemName,
      'amount': amount,
    });
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection(_getCollectionPath('expenses')).doc(expenseId).delete();
  }

  @override
  Future<List<ExpenseLog>> getAllExpenses() async {
    final snapshot = await _firestore.collection(_getCollectionPath('expenses')).get();
    return snapshot.docs.map((doc) => ExpenseLog.fromJson(doc.data(), id: doc.id)).toList();
  }
}

