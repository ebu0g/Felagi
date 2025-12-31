import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../app/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Mock user data
  final List<Map<String, String>> mockUsers = [
    {'email': 'admin@felagi.com', 'password': 'admin123', 'role': 'admin'},
    {'email': 'patient@felagi.com', 'password': 'patient123', 'role': 'patient'},
    {'email': 'pharmacy@felagi.com', 'password': 'pharmacy123', 'role': 'pharmacy'},
  ];

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    final user = mockUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      switch (user['role']) {
        case 'admin':
          Navigator.pushReplacementNamed(context, Routes.adminDashboard);
          break;
        case 'patient':
          Navigator.pushReplacementNamed(context, Routes.patientNav);
          break;
        case 'pharmacy':
          Navigator.pushReplacementNamed(context, Routes.pharmacyDashboard);
          break;
      }
    } else {
      // Show invalid login dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
          content: const Text('Invalid email or password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Felagi Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Welcome to Felagi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 30),

            CustomTextField(
              hintText: 'Email',
              controller: emailController,
            ),
            const SizedBox(height: 15),

            CustomTextField(
              hintText: 'Password',
              obscureText: true,
              controller: passwordController,
            ),
            const SizedBox(height: 30),

            CustomButton(
              text: 'Login',
              onPressed: login,
            ),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.register);
              },
              child: const Text("Don't have an account? Create account"),
            )
          ],
        ),
      ),
    );
  }
}
