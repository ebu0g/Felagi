import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/constants/colors.dart';
import '../controllers/admin_controller.dart';

class ManagePharmaciesScreen extends StatefulWidget {
  const ManagePharmaciesScreen({super.key});

  @override
  State<ManagePharmaciesScreen> createState() => _ManagePharmaciesScreenState();
}

class _ManagePharmaciesScreenState extends State<ManagePharmaciesScreen> {
  String _filter = 'Pending';

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, adminCtrl, _) {
        final filtered = _filter == 'Pending'
            ? adminCtrl.pendingPharmacies
            : _filter == 'Approved'
                ? adminCtrl.approvedPharmacies
                : adminCtrl.rejectedPharmacies;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in ['Pending', 'Approved', 'Rejected'])
                        ChoiceChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.14),
                          labelStyle: TextStyle(
                            color: _filter == f
                                ? AppColors.primary
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard(
                        label: 'Pending',
                        value: adminCtrl.pendingPharmacies.length,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        label: 'Approved',
                        value: adminCtrl.approvedPharmacies.length,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        label: 'Rejected',
                        value: adminCtrl.rejectedPharmacies.length,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildList(adminCtrl, filtered),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(
      AdminController controller, List<Map<String, dynamic>> pharmacies) {
    if (pharmacies.isEmpty) {
      return const Center(
        child: Text(
          'No pharmacies found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 20),
      itemCount: pharmacies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (ctx, index) =>
          _buildPharmacyCard(ctx, controller, pharmacies[index]),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, AdminController controller,
      Map<String, dynamic> pharmacy) {
    final documentUrl = pharmacy['document'] ?? '';
    final status = (pharmacy['status'] ?? 'pending') as String;

    Color statusColor;
    if (status == 'approved') {
      statusColor = Colors.teal;
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orangeAccent;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    pharmacy['name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoLine(Icons.email_outlined, pharmacy['email'] ?? 'No email'),
            _infoLine(Icons.phone, pharmacy['phone'] ?? 'No phone'),
            _infoLine(
                Icons.location_on_outlined, pharmacy['location'] ?? 'Unknown'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (documentUrl.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('Document'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (await canLaunchUrlString(documentUrl)) {
                        await launchUrlString(documentUrl);
                      }
                    },
                  ),
                if (status != 'approved')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showApproveDialog(
                        context, controller, pharmacy['uid']),
                  ),
                if (status != 'rejected')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _showRejectDialog(context, controller, pharmacy['uid']),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      {required String label, required int value, required Color color}) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.analytics, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.approvePharmacy(uid);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.rejectPharmacy(uid);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
