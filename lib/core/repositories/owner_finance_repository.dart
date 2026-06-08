import 'package:stitch_daily_delivery_ledger/core/models/owner_finance_model.dart';

abstract class OwnerFinanceRepository {
  Stream<OwnerLoanConfig?> getActiveLoanStream();
  Future<void> updateNotes(String loanId, String notes);
  Future<void> addRepayment(String loanId, RepaymentLog repayment);
  Future<void> updateTotalBorrowed(String loanId, double totalBorrowed);
  Stream<List<RepaymentLog>> getRepaymentsStream(String loanId);
  Future<void> initDefaultLoanConfigIfEmpty();

  Future<OwnerLoanConfig?> getActiveLoan();
  Future<List<RepaymentLog>> getRepayments(String loanId);

  Stream<List<SavingsLog>> getSavingsLogsStream();
  Future<void> addSavingsLog(SavingsLog log);
}

