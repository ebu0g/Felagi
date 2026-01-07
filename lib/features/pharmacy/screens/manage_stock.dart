import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
//import '../controllers/pharmacy_controller.dart';
import '../models/pharmacy.dart';
import '../models/medicine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ManageStockScreen extends StatefulWidget {
  final Pharmacy pharmacy; // Pharmacy whose stock we are managing

  const ManageStockScreen({super.key, required this.pharmacy});

  @override
  State<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
    @override
  void initState() {
    super.initState();
    loadMedicines(); // 🔹 load medicines when screen starts
  } 

    // 🔹 Load medicines from Firestore
Future<void> loadMedicines() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('medicines')
      .get();

  final meds = snapshot.docs.map((doc) => Medicine.fromDoc(doc)).toList();

  setState(() {
    widget.pharmacy.medicines = meds;
  });
}

Future<void> _increaseQuantity(int index) async {
  final med = widget.pharmacy.medicines[index];
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('medicines')
      .doc(med.id);

  try {
    await docRef.update({'quantity': med.quantity + 1});

    if (!mounted) return;
    setState(() {
      widget.pharmacy.medicines[index].quantity += 1;
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to increase quantity: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _decreaseQuantity(int index) async {
  final med = widget.pharmacy.medicines[index];
  if (med.quantity == 0) return;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('medicines')
      .doc(med.id);

  try {
    await docRef.update({'quantity': med.quantity - 1});

    if (!mounted) return;
    setState(() {
      widget.pharmacy.medicines[index].quantity -= 1;
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to decrease quantity: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


// Delete medicine
Future<void> _deleteMedicine(int index) async {
  final med = widget.pharmacy.medicines[index];
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('medicines')
      .doc(med.id)
      .delete();

  setState(() {
    widget.pharmacy.medicines.removeAt(index);
  });
}


  // Edit medicine
Future<void> _editMedicine(int index) async {
  final med = widget.pharmacy.medicines[index];

  final result = await Navigator.pushNamed(
    context,
    Routes.editMedicine,
    arguments: {
      'name': med.name,
      'price': med.price,
      'quantity': med.quantity,
    },
  );

  if (result != null && result is Map<String, dynamic>) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .doc(med.id);

    await docRef.update({
      'name': result['name'],
      'price': result['price'],
      'quantity': result['quantity'],
    });

    setState(() {
      widget.pharmacy.medicines[index].name = result['name'];
      widget.pharmacy.medicines[index].price = result['price'];
      widget.pharmacy.medicines[index].quantity = result['quantity'];
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
                  appBar: AppBar(
        title: const Text(
          'Manage Stock',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        leading: SizedBox.shrink(),
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
