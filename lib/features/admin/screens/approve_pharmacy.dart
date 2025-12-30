import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../controllers/admin_controller.dart';
import '../screens/document_viewer_screen.dart'; // import your document viewer

class ApprovePharmacyScreen extends StatelessWidget {
  const ApprovePharmacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);
    final pendingPharmacies = adminController.pendingPharmacies;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Approve Pharmacies',
          style: TextStyle(color: Colors.white), // title color white
        ),
        backgroundColor: AppColors.primary,
      ),
      body: pendingPharmacies.isEmpty
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(pharmacy['name']),
                    subtitle: Text(pharmacy['location']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () =>
                              adminController.approvePharmacy(pharmacy['name']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () =>
                              adminController.rejectPharmacy(pharmacy['name']),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            // Navigate to your DocumentViewerScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DocumentViewerScreen(
                                  url:
                                      pharmacy['document'], // make sure this is a full URL
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
