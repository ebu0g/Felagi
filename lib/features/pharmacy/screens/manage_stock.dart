import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
//import '../controllers/pharmacy_controller.dart';
import '../models/pharmacy.dart';
import '../models/medicine.dart';

class ManageStockScreen extends StatefulWidget {
  final Pharmacy pharmacy; // Pharmacy whose stock we are managing

  const ManageStockScreen({super.key, required this.pharmacy});

  @override
  State<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
  // Increase stock quantity
  void _increaseQuantity(int index) {
    setState(() {
      widget.pharmacy.medicines[index].quantity += 1;
    });
  }

  // Decrease stock quantity
  void _decreaseQuantity(int index) {
    setState(() {
      final currentQty = widget.pharmacy.medicines[index].quantity;
      if (currentQty > 0) {
        widget.pharmacy.medicines[index].quantity -= 1;
      }
    });
  }

  // Delete medicine
  void _deleteMedicine(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text(
          'Are you sure you want to delete "${widget.pharmacy.medicines[index].name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.pharmacy.medicines.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Edit medicine
  Future<void> _editMedicine(int index) async {
    final Medicine med = widget.pharmacy.medicines[index];

    final result = await Navigator.pushNamed(
      context,
      Routes.editMedicine,
      arguments: med, // pass Medicine object
    );

    if (result != null && result is Medicine) {
      setState(() {
        widget.pharmacy.medicines[index] = result; // update medicine
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Stock - ${widget.pharmacy.name}', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.pharmacy.medicines.length,
        itemBuilder: (context, index) {
          final Medicine medicine = widget.pharmacy.medicines[index];
          final int quantity = medicine.quantity;
          final bool isLowStock = quantity > 0 && quantity <= 5;
          final bool isOutOfStock = quantity == 0;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Stock Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Low Stock',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      if (isOutOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Price
                  Text(
                    'Price: ${medicine.price} ETB',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  // Quantity + Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock: $quantity',
                        style: TextStyle(
                          fontSize: 16,
                          color: isOutOfStock
                              ? Colors.red
                              : isLowStock
                                  ? Colors.orange
                                  : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.blue,
                            onPressed: () => _editMedicine(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deleteMedicine(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.green,
                            onPressed: () => _increaseQuantity(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.orange,
                            onPressed: () => _decreaseQuantity(index),
                          ),
                        ],
                      ),
                    ],
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
