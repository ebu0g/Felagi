import 'package:flutter/material.dart';

class AdminController extends ChangeNotifier {
  final List<Map<String, dynamic>> _pharmacies = [
    {
      'name': 'Felagi Pharmacy',
      'location': 'Addis Ababa',
      'status': 'pending',
      'document': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
    },
    {
      'name': 'Green Health',
      'location': 'Bahir Dar',
      'status': 'pending',
      'document': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'
    },
    {
      'name': 'Medicure',
      'location': 'Adama',
      'status': 'pending',
      'document': 'Medicure_Doc.pdf'
    },
  ];

  List<Map<String, dynamic>> get pendingPharmacies =>
      _pharmacies.where((p) => p['status'] == 'pending').toList();

  void approvePharmacy(String name) {
    final index = _pharmacies.indexWhere((p) => p['name'] == name);
    if (index != -1) {
      _pharmacies[index]['status'] = 'approved';
      notifyListeners();
    }
  }

  void rejectPharmacy(String name) {
    final index = _pharmacies.indexWhere((p) => p['name'] == name);
    if (index != -1) {
      _pharmacies[index]['status'] = 'rejected';
      notifyListeners();
    }
  }

  // Admin info
  String adminName = "Main Admin";
  String adminEmail = "admin@example.com";
  String adminPhone = "+251900000000";

  // Update profile method
  void updateProfile(String name, String email, String phone) {
    adminName = name;
    adminEmail = email;
    adminPhone = phone;
    notifyListeners(); // notify UI about the change
  }


   List<String> admins = ['admin1@example.com', 'admin2@example.com'];

  void addAdmin(String email) {
    admins.add(email);
    notifyListeners();
  }

  void removeAdmin(String email) {
    admins.remove(email);
    notifyListeners();
  }
}
