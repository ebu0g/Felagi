import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';

class EditMedicineScreen extends StatefulWidget {
  final String name;
  final double price;
  final int quantity;
  final String category;

  const EditMedicineScreen({
    super.key,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
  });

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late String _selectedCategory;
  final _formKey = GlobalKey<FormState>();

  static const List<String> _categories = [
    'Pain relief',
    'Cold & flu',
    'Vitamins',
    'Allergy',
    'Kids care',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _priceController = TextEditingController(text: widget.price.toString());
    _quantityController = TextEditingController(
      text: widget.quantity.toString(),
    );
    _selectedCategory = widget.category.isNotEmpty ? widget.category : 'Other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()),
        'category': _selectedCategory,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            const Text('Edit Medicine', style: TextStyle(color: Colors.white)),
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
                      'Edit details',
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
                              ? 'Name required'
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
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
                              if (value == null || value.trim().isEmpty) {
                                return 'Price required';
                              }
                              final v = value.trim();
                              if (double.tryParse(v) == null) {
                                return 'Enter a valid price';
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
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              hintText: 'e.g. 25',
                              labelText: 'Stock quantity',
                              prefixIcon: const Icon(Icons.inventory),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Quantity required';
                              }
                              final v = value.trim();
                              if (int.tryParse(v) == null) {
                                return 'Enter a valid quantity';
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
                        onPressed: _save,
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
