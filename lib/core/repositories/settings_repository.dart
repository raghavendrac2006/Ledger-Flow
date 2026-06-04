abstract class SettingsRepository {
  Stream<String> getGoogleSheetsUrlStream();
  Future<void> updateGoogleSheetsUrl(String url);
  Stream<List<String>> getExpenseSuggestionsStream();
  Future<void> updateExpenseSuggestions(List<String> suggestions);
}
