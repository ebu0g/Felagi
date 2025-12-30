import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // whole background grey
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===== Dashboard Header =====
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF064420).withValues(alpha: 0.7), // header color
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.black, // logout in grey
                        ),
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Routes.home,
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ===== Dashboard Buttons =====
            _dashboardButton(
              context,
              label: 'Approve Pharmacies',
              route: Routes.approvePharmacy,
            ),
            const SizedBox(height: 16),
            _dashboardButton(
              context,
              label: 'Manage Admins',
              route: Routes.manageAdmins,
            ),
            const SizedBox(height: 16),
            _dashboardButton(
              context,
              label: 'Profile',
              route: Routes.settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardButton(BuildContext context,
      {required String label, required String route}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, route),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
