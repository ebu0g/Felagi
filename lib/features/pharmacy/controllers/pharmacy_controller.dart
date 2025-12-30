import '../models/pharmacy.dart';
import '../models/medicine.dart';

class PharmacyController {
  static final PharmacyController _instance = PharmacyController._internal();
  factory PharmacyController() => _instance;
  PharmacyController._internal();

  final List<Pharmacy> pharmacies = [
    Pharmacy(
      name: 'City Pharmacy',
      address: 'Bole, Addis Ababa',
      phone: '0911000001',
      medicines: [
        Medicine(name: 'Paracetamol', price: 20.0, quantity: 15),
        Medicine(name: 'Amoxicillin', price: 50.0, quantity: 8),
      ],
    ),
    Pharmacy(
      name: 'Health Plus Pharmacy',
      address: 'Piassa, Addis Ababa',
      phone: '0911000002',
      medicines: [
        Medicine(name: 'Ibuprofen', price: 30.0, quantity: 10),
        Medicine(name: 'Amoxicillin', price: 55.0, quantity: 5),
      ],
    ),
  ];

  // Search medicines across all pharmacies
  List<Map<String, dynamic>> searchMedicines(String query) {
    List<Map<String, dynamic>> results = [];
    for (var pharmacy in pharmacies) {
      for (var med in pharmacy.medicines) {
        if (med.quantity > 0 &&
            med.name.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'pharmacy': pharmacy, // Pharmacy object
            'medicine': med,      // Medicine object
          });
        }
      }
    }
    return results;
  }

  // Get medicines for a specific pharmacy
  List<Medicine> getMedicinesByPharmacy(String pharmacyName) {
    final pharmacy = pharmacies.firstWhere(
      (p) => p.name == pharmacyName,
      orElse: () => Pharmacy(name: '', address: '', phone: '', medicines: []),
    );
    return pharmacy.medicines;
  }

  // Add medicine to a specific pharmacy
  void addMedicine(String pharmacyName, Medicine medicine) {
    final pharmacy = pharmacies.firstWhere((p) => p.name == pharmacyName);
    pharmacy.medicines.add(medicine);
  }

  // Edit medicine in a specific pharmacy
  void editMedicine(String pharmacyName, String medicineName,
      {String? newName, double? newPrice, int? newQuantity}) {
    final pharmacy = pharmacies.firstWhere((p) => p.name == pharmacyName);
    final med = pharmacy.medicines.firstWhere((m) => m.name == medicineName);

    if (newName != null) med.name = newName;
    if (newPrice != null) med.price = newPrice;
    if (newQuantity != null) med.quantity = newQuantity;
  }

  // Delete medicine from a pharmacy
  void deleteMedicine(String pharmacyName, String medicineName) {
    final pharmacy = pharmacies.firstWhere((p) => p.name == pharmacyName);
    pharmacy.medicines.removeWhere((m) => m.name == medicineName);
  }
}
