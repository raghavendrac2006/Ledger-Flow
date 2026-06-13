import 'package:cloud_firestore/cloud_firestore.dart';
import '../settings_repository.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String businessId;

  FirestoreSettingsRepository({required this.businessId});

  String _getCollectionPath(String collectionName) {
    if (businessId == 'business_1') {
      return collectionName;
    } else {
      return 'businesses/$businessId/$collectionName';
    }
  }

  @override
  Stream<String> getGoogleSheetsUrlStream() {
    return _firestore.collection(_getCollectionPath('settings')).doc('googleSheets').snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['url'] as String? ?? '';
      }
      return '';
    });
  }

  @override
  Future<void> updateGoogleSheetsUrl(String url) async {
    await _firestore.collection(_getCollectionPath('settings')).doc('googleSheets').set({
      'url': url,
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<String>> getExpenseSuggestionsStream() {
    return _firestore.collection(_getCollectionPath('settings')).doc('expenseItems').snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return List<String>.from(snapshot.data()!['items'] ?? []);
      }
      return [];
    });
  }

  @override
  Future<void> updateExpenseSuggestions(List<String> suggestions) async {
    await _firestore.collection(_getCollectionPath('settings')).doc('expenseItems').set({
      'items': suggestions,
    }, SetOptions(merge: true));
  }
}

