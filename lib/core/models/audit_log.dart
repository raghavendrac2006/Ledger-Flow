class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String userRole; // 'admin' or 'worker'
  final String action; // e.g., 'sale_added', 'customer_deleted', 'expense_edited'
  final String details; // human-readable description
  final String? targetType; // e.g., 'customer', 'expense', 'delivery_log'
  final String? targetId; // Firestore doc ID of the target
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.details,
    this.targetType,
    this.targetId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'action': action,
      'details': details,
      'targetType': targetType,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(String id, Map<String, dynamic> map) {
    return AuditLog(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? 'worker',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      targetType: map['targetType'],
      targetId: map['targetId'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }

  /// Human-readable action label
  String get actionLabel {
    switch (action) {
      case 'sale_added': return 'Added Sale';
      case 'sale_deleted': return 'Deleted Sale';
      case 'sale_edited': return 'Edited Sale';
      case 'customer_added': return 'Added Customer';
      case 'customer_deleted': return 'Deleted Customer';
      case 'customer_edited': return 'Edited Customer';
      case 'expense_added': return 'Added Expense';
      case 'expense_deleted': return 'Deleted Expense';
      case 'expense_edited': return 'Edited Expense';
      case 'payment_toggled': return 'Payment Status Changed';
      case 'flour_started': return 'Started New Flour Bag';
      case 'flour_updated': return 'Updated Flour Status';
      case 'data_wiped': return 'Data Wiped';
      case 'data_deleted_range': return 'Deleted Data Range';
      case 'worker_created': return 'Worker Created';
      case 'worker_disabled': return 'Worker Disabled';
      case 'worker_enabled': return 'Worker Enabled';
      case 'worker_password_reset': return 'Worker Password Reset';
      case 'settings_changed': return 'Settings Changed';
      case 'login': return 'Logged In';
      case 'logout': return 'Logged Out';
      case 'oil_logged': return 'Oil Usage Logged';
      case 'backup_created': return 'Backup Created';
      default: return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Icon for the action
  String get actionIcon {
    if (action.contains('delete') || action.contains('wipe')) return '🗑️';
    if (action.contains('add') || action.contains('create')) return '➕';
    if (action.contains('edit') || action.contains('toggle') || action.contains('change')) return '✏️';
    if (action.contains('login')) return '🔑';
    if (action.contains('logout')) return '🚪';
    if (action.contains('worker')) return '👤';
    return '📋';
  }
}
