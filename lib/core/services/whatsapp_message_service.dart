import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppMessageService {
  /// Normalizes an Indian phone number:
  /// - Strips spaces, dashes, parentheses, plus signs.
  /// - If 10 digits starting with 6, 7, 8, 9, prepends 91.
  /// - If 11 digits starting with 0, replaces leading 0 with 91.
  /// - If 12 digits starting with 91, returns as is.
  /// Returns normalized digits (e.g. '919876543210') or null if invalid.
  static String? normalizeIndianPhoneNumber(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return '91$digits';
    } else if (digits.length == 11 && digits.startsWith('0')) {
      final sub = digits.substring(1);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(sub)) {
        return '91$sub';
      }
    } else if (digits.length == 12 && digits.startsWith('91')) {
      final sub = digits.substring(2);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(sub)) {
        return digits;
      }
    }

    return null;
  }

  /// Checks if phone number is a valid Indian mobile number.
  static bool isValidIndianPhoneNumber(String? raw) {
    return normalizeIndianPhoneNumber(raw) != null;
  }

  /// Formats amount in Indian currency format (e.g. ₹250 or ₹1,250.50).
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );
    return formatter.format(amount);
  }

  /// Generates a polite, personalized message for the customer.
  static String generateMessage({
    required String customerName,
    required double amount,
    required bool isPaid,
  }) {
    final formattedAmount = formatCurrency(amount);

    if (isPaid) {
      return "Hello $customerName, your delivery for today has been completed. "
          "The total amount is $formattedAmount, and the payment has been received. "
          "Thank you for your support!";
    } else {
      return "Hello $customerName, your delivery for today has been completed. "
          "The amount is $formattedAmount. The payment is currently pending. "
          "Kindly complete the payment when convenient. Thank you!";
    }
  }

  /// Constructs the official WhatsApp click-to-chat URL:
  /// `https://wa.me/<phone_number>?text=<encoded_message>`
  static String buildWhatsAppUrl(String normalizedPhone, String message) {
    final encodedMessage = Uri.encodeComponent(message);
    return "https://wa.me/$normalizedPhone?text=$encodedMessage";
  }

  /// Opens the native WhatsApp application with the prefilled message.
  /// Returns true if the URL could be launched.
  static Future<bool> launchWhatsApp({
    required String normalizedPhone,
    required String message,
  }) async {
    final urlString = buildWhatsAppUrl(normalizedPhone, message);
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
      
      // Fallback try with platformDefault
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint("WhatsAppMessageService: Failed to launch WhatsApp URL: $e");
      return false;
    }
  }
}
