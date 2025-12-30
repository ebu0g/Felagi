// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';
import '../models/pharmacy.dart';

class PharmacyProfileScreen extends StatefulWidget {
  final Pharmacy pharmacy;

  const PharmacyProfileScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  late Pharmacy pharmacy;

  @override
  void initState() {
    super.initState();
    pharmacy = widget.pharmacy;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pharmacy Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
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
            Text(
              'Name: ${pharmacy.name}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Address: ${pharmacy.address}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Phone: ${pharmacy.phone}',
              style: const TextStyle(fontSize: 18),
            ),
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
                      'name': pharmacy.name,
                      'address': pharmacy.address,
                      'phone': pharmacy.phone,
                    },
                  );

                  if (result != null && result is Map<String, String>) {
                    setState(() {
                      pharmacy.name = result['name']!;
                      pharmacy.address = result['address']!;
                      pharmacy.phone = result['phone']!;
                    });
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

// (removed duplicate ignore and self-export left over from rename attempts)
