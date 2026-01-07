import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ================= Controllers =================
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController documentLinkController = TextEditingController();

  // ================= State =================
  String selectedRole = 'Patient'; // ✅ MUST match dropdown value

  final AuthController authController = AuthController();

  // ================= Dispose =================
  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    documentLinkController.dispose();
    super.dispose();
  }

// ================= Register =================
  void register() async {
    if (selectedRole == 'Pharmacy' &&
        documentLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide your Google Drive document link.')),
      );
      return;
    }

    if (selectedRole == 'Pharmacy' &&
        !documentLinkController.text.contains('drive.google.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a valid Google Drive link.')),
      );
      return;
    }

    //final messenger = ScaffoldMessenger.of(context);

    try {
      await authController.register(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
        role: selectedRole,
        documentLink: selectedRole == 'Pharmacy'
            ? documentLinkController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );

      Navigator.pop(context); // back to login
    } on FirebaseAuthException catch (e) {
      // Show a friendly error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Registration failed'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CustomTextField(
              hintText: 'Full Name',
              controller: fullNameController,
            ),
            const SizedBox(height: 15),

            CustomTextField(hintText: 'Email', controller: emailController),
            const SizedBox(height: 15),

            CustomTextField(
              hintText: 'Password',
              obscureText: true,
              controller: passwordController,
            ),
            const SizedBox(height: 15),

            CustomTextField(hintText: 'Phone', controller: phoneController),
            const SizedBox(height: 15),

            CustomTextField(hintText: 'Address', controller: addressController),
            const SizedBox(height: 20),

            // ================= Role Selector =================
            Row(
              children: [
                const Text('Role:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'Patient', child: Text('Patient')),
                    DropdownMenuItem(
                      value: 'Pharmacy',
                      child: Text('Pharmacy'),
                    ),
                    DropdownMenuItem(
                      value: 'Admin',
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                      documentLinkController
                          .clear(); // reset doc link when role changes
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= Pharmacy Document Link =================
            if (selectedRole == 'Pharmacy')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Drive Document Link',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hintText:
                        'Paste your Google Drive link here (e.g., https://drive.google.com/...)',
                    controller: documentLinkController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📌 Make sure the link is shareable (anyone with the link can view)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 30),

            CustomButton(text: 'Register', onPressed: register),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
