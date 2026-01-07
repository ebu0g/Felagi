import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class EditPharmacyProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;

  const EditPharmacyProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
  });

  @override
  State<EditPharmacyProfileScreen> createState() => _EditPharmacyProfileScreenState();
}

class _EditPharmacyProfileScreenState extends State<EditPharmacyProfileScreen> {
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
        'name': _nameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pharmacy Profile'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pharmacy Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Email required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Address required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Phone required' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
