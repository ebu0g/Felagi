import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPharmacyData();
  }

  Future<void> loadPharmacyData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          name = doc['fullName'] ?? '';
          email = doc['email'] ?? '';
          phone = doc['phone'] ?? '';
          address = doc['address'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  Future<void> refreshPharmacyData() async {
    setState(() => isLoading = true);
    await loadPharmacyData();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFDFF2EA),
              child: Icon(
                Icons.local_pharmacy,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            Text('Name: $name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Address: $address', style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.editPharmacyProfile,
                    arguments: {
                      'name': name,
                      'phone': phone,
                      'address': address,
                    },
                  );

                  if (result != null && result is Map<String, String>) {
                    final user = _auth.currentUser;
                    if (user != null) {
                      await _firestore.collection('users').doc(user.uid).update({
                        'fullName': result['name'],
                        'phone': result['phone'],
                        'address': result['address'],
                      });
                    }
                    await refreshPharmacyData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
