import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
//import '../models/medicine.dart';

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

  final List<String> _categories = const [
    'Pain relief',
    'Cold & flu',
    'Vitamins',
    'Allergy',
    'Kids care',
    'Other',
  ];
  String _selectedCategory = 'Pain relief';

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
    final category = _selectedCategory.trim();

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
        final existingPrice =
            (existingData['price'] as num?)?.toDouble() ?? 0.0;
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
                child: const Text('Update',
                    style: TextStyle(color: Colors.orange)),
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
            'category': category,
            'category_lower': category.toLowerCase(),
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

          // Return to previous screen so lists can refresh
          if (mounted) Navigator.pop(context, true);
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
        'category': category,
        'category_lower': category.toLowerCase(),
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

      // Pop back to previous screen so the caller can refresh lists
      if (mounted) Navigator.pop(context, true);
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            const Text('Add Medicine', style: TextStyle(color: Colors.white)),
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
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Paracetamol 500mg',
                        prefixIcon: const Icon(Icons.medication),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Medicine name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories
                          .map(
                            (c) => ChoiceChip(
                              label: Text(c),
                              selected: _selectedCategory == c,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = c),
                              selectedColor:
                                  AppColors.primary.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: _selectedCategory == c
                                    ? AppColors.primary
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0.00',
                              labelText: 'Price (ETB)',
                              prefixIcon: const Icon(Icons.attach_money),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Price is required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 25',
                              labelText: 'Quantity',
                              prefixIcon: const Icon(Icons.inventory),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Quantity is required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
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
                        onPressed: _submitForm,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Save medicine',
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
