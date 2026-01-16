import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/colors.dart';

import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../app/routes.dart';
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

  bool _obscurePassword = true;

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
      await showErrorDialog(context,
          title: 'Missing Document',
          error: 'Please provide your Google Drive document link.');
      return;
    }

    if (selectedRole == 'Pharmacy' &&
        !documentLinkController.text.contains('drive.google.com')) {
      await showErrorDialog(context,
          title: 'Invalid Link',
          error: 'Please provide a valid Google Drive link.');
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

      // Inform the user that a verification email was sent
      await showInfoDialog(context,
          title: 'Verify your email',
          message:
              'A verification email has been sent. Please verify your email before logging in.');

      if (!mounted) return;
      // Ensure the newly created (but unverified) user is signed out so
      // the app doesn't treat them as an authenticated user.
      try {
        await authController.logout();
      } catch (_) {}

      Navigator.pop(context); // back to login
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      await showErrorDialog(context,
          title: 'Registration Failed', error: e.message ?? e);
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, title: 'Registration Failed', error: e);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Felagi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create your account to continue',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  hintText: 'Full Name',
                  controller: fullNameController,
                ),
                const SizedBox(height: 14),

                CustomTextField(hintText: 'Email', controller: emailController),
                const SizedBox(height: 14),

                CustomTextField(
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  controller: passwordController,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextField(hintText: 'Phone', controller: phoneController),
                const SizedBox(height: 14),

                CustomTextField(
                    hintText: 'Address', controller: addressController),
                const SizedBox(height: 18),

                // ================= Role Selector =================
                const Text(
                  'Role',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: 'Patient', child: Text('Patient')),
                      DropdownMenuItem(
                        value: 'Pharmacy',
                        child: Text('Pharmacy'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                        documentLinkController.clear();
                      });
                    },
                  ),
                ),

                const SizedBox(height: 18),

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
                        'Make sure the link is shareable (anyone with the link can view).',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                CustomButton(text: 'Register', onPressed: register),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    Routes.login,
                  ),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
