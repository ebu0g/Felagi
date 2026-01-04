class PatientController {
  List<String> recentSearches = [];

  void addSearch(String medicine) {
    if (!recentSearches.contains(medicine)) {
      recentSearches.insert(0, medicine);
    }
  }

  void removeSearch(String medicine) {
    recentSearches.remove(medicine);
  }

  List<Map<String, dynamic>> searchPharmacies(String medicine) {
    // Search is handled via Firestore in search_results.dart
    return [];
  }
}
