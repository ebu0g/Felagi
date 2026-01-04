import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../app/routes.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthController authController = AuthController();

void login() async {
  final email = emailController.text.trim();
  final password = passwordController.text;
  final navigator = Navigator.of(context);

  try {
    final role = await authController.login(
      email: email,
      password: password,
    );

    // Navigate based on role
    if (!mounted) return;
    
    if (role == 'Patient') {
      navigator.pushReplacementNamed(Routes.patientNav);
    } else if (role == 'Pharmacy') {
      navigator.pushReplacementNamed(Routes.pharmacyNav);
    }
  } catch (e) {
    // Show error dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(e.toString()),
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.forgotPassword);
                },
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 20),

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
