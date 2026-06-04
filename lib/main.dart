import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/app_state.dart';
import 'core/repositories/firestore/firestore_customer_repository.dart';
import 'core/repositories/firestore/firestore_delivery_log_repository.dart';
import 'core/repositories/firestore/firestore_expense_repository.dart';
import 'core/repositories/firestore/firestore_rice_bag_repository.dart';
import 'core/repositories/firestore/firestore_settings_repository.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LedgerState(
            customerRepository: FirestoreCustomerRepository(),
            deliveryLogRepository: FirestoreDeliveryLogRepository(),
            expenseRepository: FirestoreExpenseRepository(),
            riceBagRepository: FirestoreRiceBagRepository(),
            settingsRepository: FirestoreSettingsRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Sales Tracking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeShell(),
      ),
    );
  }
}
