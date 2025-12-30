import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // whole background grey
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🎨 Gradient Header with Logout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Find your medicine easily',
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black),
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
                  const SizedBox(height: 20),

                  // 🔍 Search bar
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.searchMedicine);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            'Search medicine by name',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 💊 Popular Medicines
                  const Text(
                    'Popular Medicines',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _medicineCard(context, 'Paracetamol', Icons.medication),
                        _medicineCard(context, 'Amoxicillin', Icons.medical_services),
                        _medicineCard(context, 'Ibuprofen', Icons.local_hospital),
                        _medicineCard(context, 'Vitamin C', Icons.health_and_safety),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 📦 Order History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.orderHistory);
                        },
                        child: const Text('View all'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _orderHistoryTile(
                    context,
                    'Paracetamol',
                    '2 packs • Delivered',
                    Icons.check_circle,
                  ),

                  _orderHistoryTile(
                    context,
                    'Amoxicillin',
                    '1 pack • Pending',
                    Icons.access_time,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💊 Medicine Card
  Widget _medicineCard(BuildContext context, String name, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.searchResults,
          arguments: name,
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // 📦 Order History Tile
  Widget _orderHistoryTile(
      BuildContext context, String medicine, String status, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(medicine),
        subtitle: Text(status),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.orderDetails,
            arguments: {
              'medicine': medicine,
              'status': status,
            },
          );
        },
      ),
    );
  }
}
