import '../models/expense_log.dart';

abstract class ExpenseRepository {
  Stream<List<ExpenseLog>> getExpensesStream();
  Future<void> addExpense(ExpenseLog expense);
  Future<void> updateExpense(String expenseId, String itemName, double amount);
  Future<void> deleteExpense(String expenseId);
  Future<List<ExpenseLog>> getAllExpenses();
}

