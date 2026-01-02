import 'package:flutter/material.dart';
//import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../controllers/pharmacy_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class PharmacyDashboard extends StatelessWidget {
  const PharmacyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // only background behind the content
      appBar: AppBar(
        title: const Text('Pharmacy Dashboard'),
        backgroundColor: const Color(0xFF064420),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await AuthController().logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.home,
                (route) => false,
              );
            },
          ),
        ], 
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/images/pharmacy.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Welcome👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your Pharmacy Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            _dashboardButton(
              context,
              label: 'Add Medicine',
              route: Routes.addMedicine,
            ),
            
            const SizedBox(height: 16),
            _dashboardButton(
              context,
              label: 'Manage Stock',
              route: Routes.manageStock,
            ),

            const SizedBox(height: 16),
            _dashboardButton(
              context,
              label: 'Profile',
              route: Routes.pharmacyProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardButton(BuildContext context, {required String label, required String route}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // If navigating to manage stock or profile, provide a Pharmacy argument
          if (route == Routes.manageStock || route == Routes.pharmacyProfile) {
            final controller = PharmacyController();
            if (controller.pharmacies.isNotEmpty) {
              Navigator.pushNamed(context, route, arguments: controller.pharmacies.first);
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No pharmacies available')),
              );
              return;
            }
          }

          Navigator.pushNamed(context, route);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF064420),
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
