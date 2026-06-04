import '../models/delivery_log.dart';

abstract class DeliveryLogRepository {
  Stream<List<DeliveryLog>> getDeliveryLogsStream();
  Stream<Map<String, double>> getMonthlyStatsStream();
  Future<void> addDeliveryLog(DeliveryLog log);
  Future<void> updateDeliveryLog(String logId, Map<String, dynamic> data);
  Future<void> deleteDeliveryLog(String logId);
  Future<List<DeliveryLog>> getLogsForCustomer(String customerName);
  Future<List<DeliveryLog>> getAllLogs();
  Future<void> deleteLogBySerialNo(int serialNo);
  Future<void> updateLogBySerialNo(int serialNo, String newDetails, double newAmount);
  Future<void> purgeLogsOlderThan(DateTime date);
}
