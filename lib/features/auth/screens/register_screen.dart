import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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

  // ================= State =================
  String selectedRole = 'Patient'; // ✅ MUST match dropdown value
  PlatformFile? uploadedDocument;

  final AuthController authController = AuthController();

  // ================= Dispose =================
  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // ================= Pick PDF =================
  Future<void> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // ✅ PDF only
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        uploadedDocument = result.files.first;
      });
    }
  }

  // ================= Register =================
  void register() async {
    if (selectedRole == 'Pharmacy' && uploadedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your legal document (PDF).'),
        ),
      );
      return;
    }
    // Capture messenger before the async call to avoid using context across
    // an async gap. Also check `mounted` before using context after await.
    final messenger = ScaffoldMessenger.of(context);

    await authController.register(
      fullName: fullNameController.text,
      email: emailController.text,
      password: passwordController.text,
      phone: phoneController.text,
      address: addressController.text,
      role: selectedRole,
      documentPath: uploadedDocument?.path,
    );

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Registration successful!')),
    );

    Navigator.pop(context); // 🔙 Back to login
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
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                      uploadedDocument = null; // reset doc when role changes
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= Pharmacy Document =================
            if (selectedRole == 'Pharmacy')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: pickDocument,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Legal Document (PDF)'),
                  ),
                  const SizedBox(height: 8),
                  if (uploadedDocument != null)
                    Text(
                      'Selected: ${uploadedDocument!.name}',
                      style: const TextStyle(color: AppColors.primary),
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
