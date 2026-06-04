import '../models/rice_bag.dart';
import '../models/daily_usage.dart';

abstract class RiceBagRepository {
  Stream<List<RiceBag>> getRiceBagsStream();
  Stream<List<DailyUsage>> getDailyUsagesStream();
  Future<void> saveRiceBag(RiceBag bag);
  Future<void> updateRiceBag(String bagId, Map<String, dynamic> data);
  Future<void> addDailyUsage(DailyUsage usage);
  Future<List<RiceBag>> getAllRiceBags();
}
