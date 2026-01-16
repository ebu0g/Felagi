import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<Map<String, dynamic>?>? _adminDataFuture;

  @override
  void initState() {
    super.initState();
    _adminDataFuture = _fetchAdminData();
  }

  Future<Map<String, dynamic>?> _fetchAdminData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<Map<String, dynamic>?> _ensureAdminFuture() {
    _adminDataFuture ??= _fetchAdminData();
    return _adminDataFuture!;
  }

  String _resolveAdminName(Map<String, dynamic>? data) {
    final rawName = (data?['fullName'] ??
            data?['full_name'] ??
            data?['pharmacyName'] ??
            data?['name'] ??
            '')
        .toString()
        .trim();

    final looksGeneric =
        rawName.isEmpty || rawName.toLowerCase().contains('admin');
    return looksGeneric ? 'Admin' : rawName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF064420).withValues(alpha: 0.7),
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
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _ensureAdminFuture(),
                        builder: (context, snapshot) {
                          final displayName = snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? 'Loading...'
                              : _resolveAdminName(snapshot.data);
                          return Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.black,
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
