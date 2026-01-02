import 'package:cloud_firestore/cloud_firestore.dart';

import 'pharmacy.dart';

class Medicine {
  String id;
  String name;
  double price;
  int quantity;
  Pharmacy? pharmacy; // Parent pharmacy

  Medicine({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.pharmacy,
  });

  factory Medicine.fromDoc(doc, {Pharmacy? pharmacy}) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine(
      id: doc.id,
      name: data['name'],
      price: data['price']?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 0,
      pharmacy: pharmacy,
    );
  }
}
