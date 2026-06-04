import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/delivery_log.dart';
import '../delivery_log_repository.dart';

class FirestoreDeliveryLogRepository implements DeliveryLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<DeliveryLog>> getDeliveryLogsStream() {
    return _firestore.collection('deliveryLogs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DeliveryLog.fromJson(doc.data(), id: doc.id);
      }).toList();
    });
  }

  @override
  Stream<Map<String, double>> getMonthlyStatsStream() {
    return _firestore.collection('monthlyStats').snapshots().map((snapshot) {
      final Map<String, double> stats = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final sales = (data['sales'] as num?)?.toDouble() ?? 0.0;
        stats[doc.id] = sales;
      }
      return stats;
    });
  }

  @override
  Future<void> addDeliveryLog(DeliveryLog log) async {
    final docId = log.isPayment 
        ? "PAY_${DateTime.now().millisecondsSinceEpoch}"
        : "LOG_${DateTime.now().millisecondsSinceEpoch}";
    await _firestore.collection('deliveryLogs').doc(docId).set(log.toJson());
  }

  @override
  Future<void> updateDeliveryLog(String logId, Map<String, dynamic> data) async {
    await _firestore.collection('deliveryLogs').doc(logId).update(data);
  }

  @override
  Future<void> deleteDeliveryLog(String logId) async {
    await _firestore.collection('deliveryLogs').doc(logId).delete();
  }

  @override
  Future<List<DeliveryLog>> getLogsForCustomer(String customerName) async {
    final snapshot = await _firestore.collection('deliveryLogs')
        .where('customerName', isEqualTo: customerName)
        .get();
    return snapshot.docs.map((doc) => DeliveryLog.fromJson(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<List<DeliveryLog>> getAllLogs() async {
    final snapshot = await _firestore.collection('deliveryLogs').get();
    return snapshot.docs.map((doc) => DeliveryLog.fromJson(doc.data(), id: doc.id)).toList();
  }

  @override
  Future<void> deleteLogBySerialNo(int serialNo) async {
    final query = await _firestore.collection('deliveryLogs')
        .where('serialNo', isEqualTo: serialNo)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }

  @override
  Future<void> updateLogBySerialNo(int serialNo, String newDetails, double newAmount) async {
    final query = await _firestore.collection('deliveryLogs')
        .where('serialNo', isEqualTo: serialNo)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update({
        'itemName': newDetails,
        'amount': newAmount,
      });
    }
  }

  @override
  Future<void> purgeLogsOlderThan(DateTime date) async {
    final snapshot = await _firestore.collection('deliveryLogs')
        .where('dateTime', isLessThan: date.toIso8601String())
        .get();
    if (snapshot.docs.isEmpty) return;

    final Map<String, List<DocumentSnapshot>> groupedLogs = {};
    for (var doc in snapshot.docs) {
      final dateTimeStr = doc.data()['dateTime'] as String?;
      if (dateTimeStr != null) {
        final dt = DateTime.tryParse(dateTimeStr);
        if (dt != null) {
          final monthKey = "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
          if (!groupedLogs.containsKey(monthKey)) {
            groupedLogs[monthKey] = [];
          }
          groupedLogs[monthKey]!.add(doc);
        }
      }
    }

    for (var entry in groupedLogs.entries) {
      final monthKey = entry.key;
      final logs = entry.value;

      double monthlySales = 0.0;
      for (var logDoc in logs) {
        final data = logDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          monthlySales += (data['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      await _firestore.collection('monthlyStats').doc(monthKey).set({
        'sales': FieldValue.increment(monthlySales),
        'deliveriesCount': FieldValue.increment(logs.length),
      }, SetOptions(merge: true));

      final batch = _firestore.batch();
      for (var logDoc in logs) {
        batch.delete(logDoc.reference);
      }
      await batch.commit();
    }
  }
}

