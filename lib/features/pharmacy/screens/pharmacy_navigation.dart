import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy.dart';
import 'pharmacy_home.dart';
import 'manage_stock.dart';
import 'Pharmacy_profile_screen.dart';

class PharmacyNavigation extends StatefulWidget {
  const PharmacyNavigation({super.key});

  @override
  State<PharmacyNavigation> createState() => _PharmacyNavigationState();
}

class _PharmacyNavigationState extends State<PharmacyNavigation> {
  int _currentIndex = 0;
  Pharmacy? _pharmacy;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPharmacy();
  }

  Future<void> _loadPharmacy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _pharmacy = Pharmacy(
            id: user.uid,
            name: data['fullName'] ?? '',
            address: data['address'] ?? '',
            phone: data['phone'] ?? '',
            medicines: [],
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const PharmacyHome();
      case 1:
        if (_pharmacy == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ManageStockScreen(pharmacy: _pharmacy!);
      case 2:
        return const PharmacyProfileScreen();
      default:
        return const PharmacyHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Manage Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

