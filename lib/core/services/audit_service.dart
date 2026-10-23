import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/audit_log.dart';
import 'auth_service.dart';

/// Logs every user action to Firestore for complete audit trail.
class AuditService {
  final String businessId;
  final AuthService authService;

  AuditService({required this.businessId, required this.authService});

  String _getCollectionPath(String collectionName) {
    if (businessId == 'business_1') {
      return collectionName;
    } else {
      return 'businesses/$businessId/$collectionName';
    }
  }

  /// Log an action to audit trail
  Future<void> log({
    required String action,
    required String details,
    String? targetType,
    String? targetId,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection(_getCollectionPath('audit_logs'))
          .doc();

      final entry = AuditLog(
        id: docRef.id,
        userId: authService.currentUserId,
        userName: authService.currentUserName,
        userRole: authService.currentUserRole,
        action: action,
        details: details,
        targetType: targetType,
        targetId: targetId,
        timestamp: DateTime.now(),
      );

      await docRef.set(entry.toMap());
    } catch (e) {
      debugPrint('Audit log error: $e');
    }
  }

  /// Get recent audit logs (paginated)
  Future<List<AuditLog>> getRecentLogs({int limit = 50}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('audit_logs'))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLog.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for a specific user
  Future<List<AuditLog>> getLogsForUser(String userId, {int limit = 50}) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('audit_logs'))
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AuditLog.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for today (for worker activity dashboard)
  Future<List<AuditLog>> getTodaysLogs() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      final snapshot = await FirebaseFirestore.instance
          .collection(_getCollectionPath('audit_logs'))
          .where('timestamp', isGreaterThanOrEqualTo: todayStart.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AuditLog.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching today\'s audit logs: $e');
      return [];
    }
  }

  /// Get worker activity summary for today
  Future<Map<String, Map<String, int>>> getWorkerActivitySummary() async {
    final logs = await getTodaysLogs();
    final Map<String, Map<String, int>> summary = {};

    for (final log in logs) {
      if (!summary.containsKey(log.userName)) {
        summary[log.userName] = {};
      }
      final actionLabel = log.actionLabel;
      summary[log.userName]![actionLabel] = 
          (summary[log.userName]![actionLabel] ?? 0) + 1;
    }

    return summary;
  }
}
