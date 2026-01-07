import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(pharmacy['name'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${pharmacy['email'] ?? 'No email'}'),
            Text('Phone: ${pharmacy['phone'] ?? 'No phone'}'),
            Text('Location: ${pharmacy['location'] ?? 'Unknown'}'),
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
        child: Text('No pharmacies in this category'),
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
          appBar: AppBar(
            title: const Text('Admin - Pharmacies'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(context, adminCtrl.pendingPharmacies),
              _buildTabContent(context, adminCtrl.approvedPharmacies),
              _buildTabContent(context, adminCtrl.rejectedPharmacies),
            ],
          ),
        );
      },
    );
  }
}
