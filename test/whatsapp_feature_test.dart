import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerflow/core/models/whatsapp_message_model.dart';
import 'package:ledgerflow/core/services/whatsapp_message_service.dart';
import 'package:ledgerflow/screens/whatsapp_message_preview_screen.dart';

void main() {
  group('WhatsAppMessageService Unit Tests', () {
    test('Normalizes valid 10-digit Indian phone numbers', () {
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('9876543210'), equals('919876543210'));
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('8123456789'), equals('918123456789'));
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('7012345678'), equals('917012345678'));
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('6300123456'), equals('916300123456'));
    });

    test('Handles formatting characters, spaces, and prefixes', () {
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('+91 98765 43210'), equals('919876543210'));
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('91-98765-43210'), equals('919876543210'));
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('(0) 9876543210'), equals('919876543210'));
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('09876543210'), equals('919876543210'));
    });

    test('Rejects invalid phone numbers', () {
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('12345'), isNull);
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('1234567890'), isNull); // Starts with 1
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber(''), isNull);
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber(null), isNull);
      expect(WhatsAppMessageService.normalizeIndianPhoneNumber('abcdefghij'), isNull);
    });

    test('Generates polite message for paid customer', () {
      final msg = WhatsAppMessageService.generateMessage(
        customerName: 'Ravi',
        amount: 250,
        isPaid: true,
      );

      expect(msg, contains('Hello Ravi'));
      expect(msg, contains('250'));
      expect(msg, contains('payment has been received'));
      expect(msg, contains('Thank you for your support'));
    });

    test('Generates polite reminder message for pending customer', () {
      final msg = WhatsAppMessageService.generateMessage(
        customerName: 'Suresh',
        amount: 350,
        isPaid: false,
      );

      expect(msg, contains('Hello Suresh'));
      expect(msg, contains('350'));
      expect(msg, contains('payment is currently pending'));
      expect(msg, contains('Kindly complete the payment'));
    });

    test('Constructs valid WhatsApp click-to-chat URL with percent encoding', () {
      final url = WhatsAppMessageService.buildWhatsAppUrl('919876543210', 'Hello Ravi, total is ₹250!');
      expect(url.startsWith('https://wa.me/919876543210?text='), isTrue);
      expect(url.contains('Hello%20Ravi'), isTrue);
      // Ensure spaces and ₹ are encoded
      expect(url.contains(' '), isFalse);
    });
  });

  group('WhatsAppCustomerMessage Model Tests', () {
    test('Default message is used when custom message is empty', () {
      final item = WhatsAppCustomerMessage(
        customerName: 'Anwar Store',
        todayAmount: 500,
        isPaid: true,
        defaultMessage: 'Default Hello',
        customMessage: '',
      );

      expect(item.finalMessage, equals('Default Hello'));
    });

    test('Custom message overrides default when provided', () {
      final item = WhatsAppCustomerMessage(
        customerName: 'Anwar Store',
        todayAmount: 500,
        isPaid: true,
        defaultMessage: 'Default Hello',
        customMessage: 'Custom Special Greeting',
      );

      expect(item.finalMessage, equals('Custom Special Greeting'));
    });
  });

  group('WhatsAppMessagePreviewScreen Widget Tests', () {
    testWidgets('Renders message preview list and allows dispatch view toggle', (WidgetTester tester) async {
      final messages = [
        WhatsAppCustomerMessage(
          customerName: 'Ravi',
          phoneNumber: '9876543210',
          todayAmount: 250,
          isPaid: true,
          defaultMessage: 'Hello Ravi, delivery complete ₹250',
        ),
        WhatsAppCustomerMessage(
          customerName: 'Suresh',
          phoneNumber: null,
          todayAmount: 350,
          isPaid: false,
          defaultMessage: 'Hello Suresh, delivery complete ₹350 pending',
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: WhatsAppMessagePreviewScreen(messages: messages),
      ));

      expect(find.text('MESSAGE PREVIEW & EDIT'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('Suresh'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('MISSING PHONE'), findsOneWidget);

      // Tap start dispatch button
      await tester.tap(find.text('START WHATSAPP DISPATCH (2 CUSTOMERS)'));
      await tester.pumpAndSettle();

      // Should be in dispatch view
      expect(find.text('SENDING TO WHATSAPP'), findsOneWidget);
      expect(find.text('CUSTOMER 1 OF 2'), findsOneWidget);
      expect(find.text('OPEN IN WHATSAPP'), findsOneWidget);
      expect(find.text('MARK AS SENT'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      // Mark first as sent
      await tester.tap(find.text('MARK AS SENT'));
      await tester.pumpAndSettle();

      // Should advance to customer 2 of 2
      expect(find.text('CUSTOMER 2 OF 2'), findsOneWidget);
      expect(find.text('Phone Number Missing!'), findsOneWidget);
    });
  });
}
