import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class EditAdminProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;

  const EditAdminProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
  });

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _addressController = TextEditingController(text: widget.address);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
    }
  }

  InputDecoration _fieldDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Edit Admin Profile',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: _fieldDecoration(
                          hint: 'Full name', icon: Icons.person),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Name required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          _fieldDecoration(hint: 'Email', icon: Icons.email),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Email required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      keyboardType: TextInputType.streetAddress,
                      decoration: _fieldDecoration(
                          hint: 'Street, city, etc.', icon: Icons.location_on),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Address required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecoration(
                          hint: 'Phone number', icon: Icons.phone),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Phone required'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Save changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
