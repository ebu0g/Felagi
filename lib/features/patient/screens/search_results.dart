import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../../pharmacy/models/medicine.dart';
import '../../pharmacy/models/pharmacy.dart';

class SearchResults extends StatelessWidget {
  const SearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final String query =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    // ✅ FIX: define search OUTSIDE StreamBuilder
    final String search = query.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "$query"'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('medicines')
            .where('name_lower', isGreaterThanOrEqualTo: search)
            .where('name_lower', isLessThanOrEqualTo: '$search\uf8ff')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No results found for "$query".'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final medicine = Medicine(
                id: doc.id,
                name: data['name'],
                price: (data['price'] as num).toDouble(),
                quantity: data['quantity'],
              );

              // 🔑 Parent pharmacy document
              final pharmacyRef = doc.reference.parent.parent!;

              return FutureBuilder<DocumentSnapshot>(
                future: pharmacyRef.get(),
                builder: (context, pharmacySnap) {
                  if (!pharmacySnap.hasData) {
                    return const SizedBox();
                  }

                  final pData =
                      pharmacySnap.data!.data() as Map<String, dynamic>;

                  final pharmacy = Pharmacy(
                    id: pharmacyRef.id,
                    name: pData['name'],
                    address: pData['address'],
                    phone: pData['phone'],
                    medicines: const [],
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(medicine.name),
                      subtitle: Text(
                        '${pharmacy.name}\nPrice: ${medicine.price} ETB | Stock: ${medicine.quantity}',
                      ),
                      isThreeLine: true,
                      trailing:
                          const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.pharmacyDetails,
                          arguments: {
                            'pharmacy': pharmacy,
                            'medicine': medicine,
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
