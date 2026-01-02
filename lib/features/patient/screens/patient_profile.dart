import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
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
    loadUserData();
  }

  Future<void> loadUserData() async {
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

  Future<void> refreshUserData() async {
    setState(() => isLoading = true);
    await loadUserData();
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
            // 👤 Profile Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFDFF2EA),
              child: Icon(
                Icons.person,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // User info
            Text('Name: $name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Email: $email', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Phone: $phone', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Address: $address', style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 30),

            // ✏️ Edit Profile Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.editPatientProfile,
                    arguments: {
                      'name': name,
                      'email': email,
                      'phone': phone,
                      'address': address,
                    },
                  );

                  if (result != null && result is Map<String, String>) {
                    // Update Firestore & refresh UI
                    final user = _auth.currentUser;
                    if (user != null) {
                      await _firestore.collection('users').doc(user.uid).update({
                        'fullName': result['name'],
                        'email': result['email'],
                        'phone': result['phone'],
                        'address': result['address'],
                      });
                    }
                    await refreshUserData();
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
