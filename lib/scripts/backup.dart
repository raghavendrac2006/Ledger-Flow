// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const MaterialApp(home: BackupScreen()));
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  String _status = 'Starting backup automatically...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runBackup();
    });
  }

  Future<void> runBackup() async {
    try {
      setState(() { _status = 'Fetching collections...'; });
      print("Starting backup...");
      final firestore = FirebaseFirestore.instance;
      final Map<String, dynamic> backupData = {};
      
      final collections = ['customers', 'deliveryLogs', 'expenses', 'riceBags', 'dailyUsages'];
      
      for (final col in collections) {
        print("Fetching $col...");
        final rootSnap = await firestore.collection(col).get();
        final List<dynamic> docs = rootSnap.docs.map((d) => d.data()).toList();
        
        final b1Snap = await firestore.collection('businesses/business_1/$col').get();
        final List<dynamic> b1Docs = b1Snap.docs.map((d) => d.data()).toList();
        
        backupData[col] = {
          'root': docs,
          'business_1': b1Docs,
        };
      }
      
      setState(() { _status = 'Saving to file...'; });
      final file = File('a:\\stitch_daily_delivery_ledger\\ledgerflow_backup.json');
      await file.writeAsString(jsonEncode(backupData));
      
      print("BACKUP_SUCCESS: ${file.path}");
      setState(() { _status = 'Backup saved successfully to ${file.path}!\nYou can close this window.'; });
    } catch (e) {
      print("BACKUP_ERROR: $e");
      setState(() { _status = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_status, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
