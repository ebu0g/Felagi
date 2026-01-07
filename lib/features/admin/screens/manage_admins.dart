import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../../../core/constants/colors.dart';

class ManageAdminsScreen extends StatelessWidget {
  const ManageAdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Admins',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Clear Add Admin button at the top
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Admin',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () => _showAddAdminDialog(context, adminController),
              ),
            ),
            const SizedBox(height: 20),
            // Admin list
            Expanded(
              child: adminController.admins.isEmpty
                  ? const Center(
                      child: Text(
                        'No admins yet',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: adminController.admins.length,
                      itemBuilder: (context, index) {
                        final admin = adminController.admins[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(admin),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(
                                  context, adminController, admin),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAdminDialog(
      BuildContext context, AdminController adminController) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Admin'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Admin Email',
            hintText: 'Enter email address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                adminController.addAdmin(email);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context,
      AdminController adminController, String adminEmail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Admin'),
        content: Text('Are you sure you want to delete "$adminEmail"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              adminController.removeAdmin(adminEmail);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
