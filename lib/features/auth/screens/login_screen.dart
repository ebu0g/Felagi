import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../app/routes.dart';
import '../controllers/auth_controller.dart';
import '../../../core/widgets/app_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthController authController = AuthController();
  bool _obscurePassword = true;

  Future<void> signInWithGoogle() async {
    final navigator = Navigator.of(context);
    try {
      final role = await authController.signInWithGoogle(promptChooser: true);
      if (!mounted) return;

      if (role == 'Patient') {
        navigator.pushReplacementNamed(Routes.patientNav);
      } else if (role == 'Pharmacy') {
        navigator.pushReplacementNamed(Routes.pharmacyNav);
      } else if (role == 'Admin') {
        navigator.pushReplacementNamed(Routes.adminNav);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, title: 'Google Sign-in Failed', error: e);
    }
  }

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
      } else if (role == 'Admin') {
        navigator.pushReplacementNamed(Routes.adminNav);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('[REJECTED]')) {
        // Prompt the pharmacy to write an appeal message to admin
        final textCtrl = TextEditingController();
        final sent = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Account Rejected'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Your pharmacy was rejected. You can send a message to the admin to request a re-review.'),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message to admin',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final text = textCtrl.text.trim();
                    if (text.isNotEmpty) {
                      await authController.submitAppealMessage(text);
                    }
                    Navigator.of(ctx).pop(true);
                  } catch (err) {
                    Navigator.of(ctx).pop(false);
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (sent == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your message was sent to the admin.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        await showErrorDialog(context, title: 'Login Failed', error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Login',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                      'Login to continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      hintText: 'Email',
                      controller: emailController,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      hintText: 'Password',
                      obscureText: _obscurePassword,
                      controller: passwordController,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.forgotPassword);
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 5),
                    CustomButton(
                      text: 'Login',
                      onPressed: login,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.login, color: AppColors.primary),
                        label: const Text(
                          'Sign in with Google',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: signInWithGoogle,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.register);
                        },
                        child:
                            const Text("Don't have an account? Create account"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
