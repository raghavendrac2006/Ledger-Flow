enum WhatsAppDeliveryStatus {
  pending,
  sent,
  skipped,
}

class WhatsAppCustomerMessage {
  final String customerName;
  final String? phoneNumber;
  final double todayAmount;
  final bool isPaid;
  final String defaultMessage;
  String customMessage;
  WhatsAppDeliveryStatus status;

  WhatsAppCustomerMessage({
    required this.customerName,
    this.phoneNumber,
    required this.todayAmount,
    required this.isPaid,
    required this.defaultMessage,
    String? customMessage,
    this.status = WhatsAppDeliveryStatus.pending,
  }) : customMessage = customMessage ?? defaultMessage;

  String get finalMessage => customMessage.trim().isNotEmpty ? customMessage : defaultMessage;

  bool get hasValidPhone {
    if (phoneNumber == null) return false;
    final digits = phoneNumber!.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  WhatsAppCustomerMessage copyWith({
    String? customerName,
    String? phoneNumber,
    double? todayAmount,
    bool? isPaid,
    String? defaultMessage,
    String? customMessage,
    WhatsAppDeliveryStatus? status,
  }) {
    return WhatsAppCustomerMessage(
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      todayAmount: todayAmount ?? this.todayAmount,
      isPaid: isPaid ?? this.isPaid,
      defaultMessage: defaultMessage ?? this.defaultMessage,
      customMessage: customMessage ?? this.customMessage,
      status: status ?? this.status,
    );
  }
}
