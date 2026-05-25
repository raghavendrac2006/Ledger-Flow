import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_daily_delivery_ledger/main.dart';
import 'package:stitch_daily_delivery_ledger/screens/setup_screen.dart';
import 'package:stitch_daily_delivery_ledger/screens/sales_entry_screen.dart';

void main() {
  testWidgets('App loads and renders Route Initialization setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('ROUTE INITIALIZATION'), findsOneWidget);
    expect(find.descendant(of: find.byType(SetupScreen), matching: find.text('Daily Setup')), findsOneWidget);
  });

  testWidgets('Sales entry dropdown selection fills textfield and moves focus', (WidgetTester tester) async {
    // Set larger screen size so the setup screen buttons are visible without scrolling
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());

    // 1. In SetupScreen, select at least one item and click start rounds
    // Toggle the first item selection
    await tester.tap(find.text('2 ₹ Chakli'));
    await tester.pumpAndSettle();

    // Tap "START ROUNDS"
    await tester.tap(find.text('START ROUNDS'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Now we should be on the main app screen (which loads SalesEntryScreen as active screen)
    expect(find.byType(SalesEntryScreen), findsOneWidget);

    // 2. Tap on the Customer search TextField and enter text "mi"
    final searchFieldFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == 'Search or enter new shop name...',
    );
    expect(searchFieldFinder, findsOneWidget);

    await tester.tap(searchFieldFinder);
    await tester.pumpAndSettle();

    await tester.enterText(searchFieldFinder, 'mi');
    await tester.pumpAndSettle();

    // 3. Verify suggestions dropdown is shown and has "Milk"
    expect(find.text('Milk'), findsOneWidget);

    // 4. Tap the suggestion "Milk"
    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();

    // 5. Verify the Customer TextField now contains "Milk"
    final textField = tester.widget<TextField>(searchFieldFinder);
    expect(textField.controller?.text, equals('Milk'));
  });
}
