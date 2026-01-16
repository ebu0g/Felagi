import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final AuthController authController = AuthController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Basic email validation
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authController.resetPassword(email: email);

      if (!mounted) return;

      // Show success dialog with helpful tips
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset Email Sent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We have sent a password reset link to:\n$email',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Please check:'),
                const SizedBox(height: 8),
                const Text('• Your inbox (emails may take 1-5 minutes)'),
                const Text('• Your spam/junk folder'),
                const Text('• That this email is registered in the app'),
                const SizedBox(height: 8),
                const Text(
                  'If you don\'t see the email, please check the above and try again.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to login screen
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show error dialog with more helpful messages
      String errorMessage = e.toString();
      if (errorMessage.contains('user-not-found') ||
          errorMessage.contains('invalid-email')) {
        errorMessage =
            'This email address is not registered. Please check your email or create an account.';
      } else if (errorMessage.contains('network')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 30),
            const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your email address and we will send you a link to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              hintText: 'Email',
              controller: emailController,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: 'Send Reset Link',
                    onPressed: _resetPassword,
                  ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
