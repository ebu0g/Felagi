import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

          if (snapshot.hasError) {
            debugPrint('Search error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This might be due to missing Firestore index.\nCheck Firebase Console for index errors.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            debugPrint('No results found. Search term: "$search"');
            return Center(
              child: Text('No results found for "$query".'),
            );
          }

          debugPrint('Found ${snapshot.data!.docs.length} medicine documents');

          final docs = snapshot.data!.docs;

          // Filter medicines from Pharmacy users only
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _filterPharmacyMedicines(docs),
            builder: (context, filteredSnapshot) {
              if (filteredSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredResults = filteredSnapshot.data ?? [];

              if (filteredResults.isEmpty) {
                return Center(
                  child: Text('No results found for "$query".'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredResults.length,
                itemBuilder: (context, index) {
                  final result = filteredResults[index];
                  final medicine = result['medicine'] as Medicine;
                  final pharmacy = result['pharmacy'] as Pharmacy;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(medicine.name),
                      subtitle: Text(
                        '${pharmacy.name}\nPrice: ${medicine.price} ETB | Stock: ${medicine.quantity}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  Future<List<Map<String, dynamic>>> _filterPharmacyMedicines(
      List<QueryDocumentSnapshot> docs) async {
    final List<Map<String, dynamic>> results = [];

    for (final doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final pharmacyRef = doc.reference.parent.parent;

        if (pharmacyRef == null) continue;

        final pharmacyDoc = await pharmacyRef.get();
        if (!pharmacyDoc.exists) continue;

        final pData = pharmacyDoc.data() as Map<String, dynamic>;

        // Only include medicines from Pharmacy users
        if (pData['role'] != 'Pharmacy') continue;

        final medicine = Medicine(
          id: doc.id,
          name: data['name'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: data['quantity'] ?? 0,
        );

        final pharmacy = Pharmacy(
          id: pharmacyRef.id,
          name: pData['fullName'] ?? '',
          address: pData['address'] ?? '',
          phone: pData['phone'] ?? '',
          medicines: const [],
        );

        results.add({
          'medicine': medicine,
          'pharmacy': pharmacy,
        });
      } catch (e) {
        // Skip documents that fail to process
        continue;
      }
    }

    return results;
  }
}
