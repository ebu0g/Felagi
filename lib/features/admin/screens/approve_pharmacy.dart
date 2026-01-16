import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../controllers/admin_controller.dart';

class ApprovePharmacyScreen extends StatelessWidget {
  const ApprovePharmacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);
    final pendingPharmacies = adminController.pendingPharmacies;
    final allPharmacies = adminController.pharmacies;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Approve Pharmacies',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pharmacies: ${allPharmacies.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Pending Approval: ${pendingPharmacies.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pendingPharmacies.isEmpty
                ? const Center(
                    child: Text(
                      'No pharmacies pending approval',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingPharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = pendingPharmacies[index];
                      final hasDocument =
                          pharmacy['document'].toString().isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pharmacy Info
                              Text(
                                pharmacy['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Email: ${pharmacy['email']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Location: ${pharmacy['location']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Phone: ${pharmacy['phone']}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 12),

                              // Document Link Button (Prominent)
                              if (hasDocument)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '📄 Google Drive Document:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final documentUrl =
                                              pharmacy['document'];
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final uri = Uri.parse(documentUrl);
                                          try {
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } else {
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Could not open document. Please check the link.'),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error opening document: $e'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text(
                                            'View Document on Google Drive'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: const Text(
                                    '⚠️ No document attached',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              // Approve / Reject Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => adminController
                                          .approvePharmacy(pharmacy['uid']),
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => adminController
                                          .rejectPharmacy(pharmacy['uid']),
                                      icon: const Icon(Icons.cancel),
                                      label: const Text('Reject'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
