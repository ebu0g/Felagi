import 'medicine.dart';

class Pharmacy {
  String id; // ✅ Firestore document ID
  String name;
  String address;
  String phone;
  List<Medicine> medicines;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.medicines,
  });
}
