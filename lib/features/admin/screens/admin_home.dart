import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showApproveDialog(
      BuildContext context, AdminController controller, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Pharmacy'),
        content: const Text('Are you sure you want to approve this pharmacy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.approvePharmacy(uid);
              Navigator.pop(ctx);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, AdminController controller, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Pharmacy'),
        content: const Text(
            'Are you sure you want to reject this pharmacy? They will not be able to log in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.rejectPharmacy(uid);
              Navigator.pop(ctx);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(
      BuildContext context, Map<String, dynamic> pharmacy) {
    final controller = Provider.of<AdminController>(context, listen: false);
    final documentUrl = pharmacy['document'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          pharmacy['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Email: ${pharmacy['email'] ?? 'No email'}',
                style: const TextStyle(fontSize: 13)),
            Text('Phone: ${pharmacy['phone'] ?? 'No phone'}',
                style: const TextStyle(fontSize: 13)),
            Text('Location: ${pharmacy['location'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (documentUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.description, color: Colors.blue),
                tooltip: 'View Document',
                onPressed: () async {
                  if (await canLaunchUrlString(documentUrl)) {
                    await launchUrlString(documentUrl);
                  }
                },
              ),
            if (pharmacy['status'] != 'approved')
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Approve',
                onPressed: () =>
                    _showApproveDialog(context, controller, pharmacy['uid']),
              ),
            if (pharmacy['status'] != 'rejected')
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: 'Reject',
                onPressed: () =>
                    _showRejectDialog(context, controller, pharmacy['uid']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
      BuildContext context, List<Map<String, dynamic>> pharmacies) {
    if (pharmacies.isEmpty) {
      return const Center(
        child: Text(
          'No pharmacies in this category',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: pharmacies.length,
      itemBuilder: (ctx, index) => _buildPharmacyCard(ctx, pharmacies[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, adminCtrl, _) {
        return Scaffold(
          backgroundColor: Colors.grey[200],
          body: Column(
            children: [
              // Gradient Header with Logout
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          'Manage pharmacies',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.black),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await AuthController().logout();
                        if (mounted) {
                          navigator.pushNamedAndRemoveUntil(
                            Routes.home,
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

Expanded(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),

        const SizedBox(height: 12),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(context, adminCtrl.pendingPharmacies),
              _buildTabContent(context, adminCtrl.approvedPharmacies),
              _buildTabContent(context, adminCtrl.rejectedPharmacies),
            ],
          ),
        ),
      ],
    ),
  ),
),


              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
