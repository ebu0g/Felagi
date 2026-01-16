import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';

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
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      setState(() => isLoading = false);
      return;
    }

    final data = doc.data() ?? {};
    final fetchedName = (data['fullName'] ??
            data['full_name'] ??
            data['pharmacyName'] ??
            data['name'] ??
            '')
        .toString()
        .trim();
    final fetchedEmail = (data['email'] ?? '').toString().trim();
    final fetchedPhone = (data['phone'] ?? '').toString().trim();
    final fetchedAddress = (data['address'] ?? '').toString().trim();

    final providerEmailFull = user.providerData
        .map((p) => (p.email ?? '').trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final providerEmailPrefix = user.providerData
        .map((p) => (p.email ?? '').trim())
        .map((email) => email.contains('@') ? email.split('@').first : email)
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');

    final displayNameRaw = (user.displayName ?? '').trim();
    final displayNameIsGeneric = displayNameRaw.isEmpty ||
        displayNameRaw.toLowerCase().contains('pharmacy') ||
        displayNameRaw.toLowerCase().contains('hub');
    final fetchedNameIsGeneric = fetchedName.isEmpty ||
        fetchedName.toLowerCase().contains('pharmacy') ||
        fetchedName.toLowerCase().contains('hub');

    final safeFetchedName = fetchedNameIsGeneric ? '' : fetchedName;
    final emailFull = (user.email ?? '').trim();
    final emailPrefix =
        emailFull.contains('@') ? emailFull.split('@').first.trim() : emailFull;
    final fetchedEmailPrefix = fetchedEmail.contains('@')
        ? fetchedEmail.split('@').first.trim()
        : fetchedEmail;

    final resolvedName = <String>[
      safeFetchedName,
      fetchedEmailPrefix,
      emailPrefix,
      fetchedEmail,
      emailFull,
      providerEmailPrefix,
      providerEmailFull,
      displayNameIsGeneric ? '' : displayNameRaw,
      fetchedPhone,
      (user.phoneNumber ?? '').trim(),
      user.uid,
      'Pharmacy',
    ].firstWhere((v) => v.isNotEmpty, orElse: () => 'Pharmacy');

    debugPrint(
        'PharmacyProfile name resolve -> fetched="$fetchedName", fetchedGeneric=$fetchedNameIsGeneric, email="$fetchedEmail", authEmail="$emailFull", providerEmailFull="$providerEmailFull", providerEmailPrefix="$providerEmailPrefix", phone="$fetchedPhone"');

    final resolvedEmail = <String>[
      fetchedEmail,
      emailFull,
      providerEmailFull,
      providerEmailPrefix,
    ].firstWhere((v) => v.isNotEmpty, orElse: () => '');

    setState(() {
      name = resolvedName;
      email = resolvedEmail;
      phone = fetchedPhone.isNotEmpty
          ? fetchedPhone
          : (user.phoneNumber ?? '').trim();
      address = fetchedAddress;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🎨 Profile Header (Same as Patient)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    // 💊 Pharmacy Avatar
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.local_pharmacy,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name.isEmpty ? 'Pharmacy' : name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // 📋 Profile Info Card
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.local_pharmacy_outlined,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pharmacy Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.store, 'Pharmacy Name', name),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.email, 'Email', email),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.phone,
                              'Phone',
                              phone.isEmpty ? 'Not set' : phone,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.location_on,
                              'Address',
                              address.isEmpty ? 'Not set' : address,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✏️ Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            Routes.editPharmacyProfile,
                            arguments: {
                              'name': name,
                              'email': email,
                              'phone': phone,
                              'address': address,
                            },
                          );

                          if (result != null && result is Map<String, String>) {
                            final user = _auth.currentUser;
                            if (user != null) {
                              await _firestore
                                  .collection('users')
                                  .doc(user.uid)
                                  .update({
                                'fullName': result['name'],
                                'email': result['email'],
                                'phone': result['phone'],
                                'address': result['address'],
                              });
                            }
                            await loadPharmacyData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
