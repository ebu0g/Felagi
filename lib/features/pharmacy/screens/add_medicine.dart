import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../models/medicine.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  final name = _nameController.text.trim();
  final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
  final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

  final user = _auth.currentUser;
  if (user == null) return;

  try {
    // Check if medicine with same name already exists (case-insensitive)
    final existingMedicines = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .where('name_lower', isEqualTo: name.toLowerCase())
        .get();

    if (existingMedicines.docs.isNotEmpty) {
      // Medicine already exists - show dialog
      final existingDoc = existingMedicines.docs.first;
      final existingData = existingDoc.data();
      final existingName = existingData['name'] ?? '';
      final existingPrice = (existingData['price'] as num?)?.toDouble() ?? 0.0;
      final existingQuantity = existingData['quantity'] ?? 0;

      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Medicine Already Exists'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A medicine named "$existingName" already exists.'),
              const SizedBox(height: 12),
              Text('Current: ${existingPrice} ETB, Stock: $existingQuantity'),
              const SizedBox(height: 12),
              const Text('Would you like to update it with the new values?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );

      if (shouldUpdate == true) {
        // Update existing medicine
        await existingDoc.reference.update({
          'name': name,
          'name_lower': name.toLowerCase(),
          'price': price,
          'quantity': quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear fields
        _nameController.clear();
        _priceController.clear();
        _quantityController.clear();
      }
      // If user cancels, do nothing
      return;
    }

    // No duplicate found - add new medicine
    final docRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .add({
      'name': name,
      'name_lower': name.toLowerCase(), // 🔑 for case-insensitive search
      'price': price,
      'quantity': quantity,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine added successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear fields
    _nameController.clear();
    _priceController.clear();
    _quantityController.clear();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to add medicine: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Medicine name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (ETB)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Price is required';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  prefixIcon: Icon(Icons.inventory),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Quantity is required';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submitForm,
                  child: const Text('Add Medicine', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
