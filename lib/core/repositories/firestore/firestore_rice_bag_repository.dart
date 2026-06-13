import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/rice_bag.dart';
import '../../models/daily_usage.dart';
import '../rice_bag_repository.dart';

class FirestoreRiceBagRepository implements RiceBagRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String businessId;

  FirestoreRiceBagRepository({required this.businessId});

  String _getCollectionPath(String collectionName) {
    if (businessId == 'business_1') {
      return collectionName;
    } else {
      return 'businesses/$businessId/$collectionName';
    }
  }

  @override
  Stream<List<RiceBag>> getRiceBagsStream() {
    return _firestore.collection(_getCollectionPath('riceBags')).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RiceBag.fromJson(doc.data(), id: doc.id);
      }).toList();
    });
  }

  @override
  Stream<List<DailyUsage>> getDailyUsagesStream() {
    return _firestore.collection(_getCollectionPath('dailyUsages')).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DailyUsage.fromJson(doc.data(), id: doc.id);
      }).toList();
    });
  }

  @override
  Future<void> saveRiceBag(RiceBag bag) async {
    await _firestore.collection(_getCollectionPath('riceBags')).doc(bag.bagId).set(bag.toJson());
  }

  @override
  Future<void> updateRiceBag(String bagId, Map<String, dynamic> data) async {
    await _firestore.collection(_getCollectionPath('riceBags')).doc(bagId).update(data);
  }

  @override
  Future<void> addDailyUsage(DailyUsage usage) async {
    await _firestore.collection(_getCollectionPath('dailyUsages')).doc(usage.usageId).set(usage.toJson());
  }

  @override
  Future<List<RiceBag>> getAllRiceBags() async {
    final snapshot = await _firestore.collection(_getCollectionPath('riceBags')).get();
    return snapshot.docs.map((doc) => RiceBag.fromJson(doc.data(), id: doc.id)).toList();
  }
}

