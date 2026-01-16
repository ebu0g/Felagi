import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../app/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              const SizedBox(height: 16),

              // App Name
              Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              // Login Button
              CustomButton(
                text: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.login);
                },
              ),

              const SizedBox(height: 16),

              // Sign Up Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.register);
                },
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
