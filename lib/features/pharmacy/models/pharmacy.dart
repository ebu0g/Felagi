import 'medicine.dart';

class Pharmacy {
  String name;
  String address;
  String phone;
  List<Medicine> medicines;

  Pharmacy({
    required this.name,
    required this.address,
    required this.phone,
    required this.medicines,
  });
}
