import '../models/pharmacy.dart';
import '../models/medicine.dart';

class PharmacyController {
  static final PharmacyController _instance = PharmacyController._internal();
  factory PharmacyController() => _instance;
  PharmacyController._internal();

  // Search medicines across all pharmacies
  // Note: Medicine search is now handled via Firestore in search_results.dart
}
