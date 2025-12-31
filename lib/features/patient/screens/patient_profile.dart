import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  State<PatientProfile> createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  // Temporary local data (later replace with Firebase)
  String name = 'Patient Name';
  String email = 'patient@email.com';
  String phone = '+251 900 000 000';

  @override
  Widget build(BuildContext context) {
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

            // 📛 Name
            Text(
              'Name: $name',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            // 📧 Email
            Text(
              'Email: $email',
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            // 📞 Phone
            Text(
              'Phone: $phone',
              style: const TextStyle(fontSize: 18),
            ),

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
                    },
                  );

                  if (result != null && result is Map<String, String>) {
                    setState(() {
                      name = result['name']!;
                      email = result['email']!;
                      phone = result['phone']!;
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
