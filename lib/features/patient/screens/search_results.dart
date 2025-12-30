import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../../pharmacy/controllers/pharmacy_controller.dart';
import '../../pharmacy/models/medicine.dart';
import '../../pharmacy/models/pharmacy.dart';
//import '../models/medicine.dart';

class SearchResults extends StatelessWidget {
  const SearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final String query =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final pharmacyController = PharmacyController();
   
    final filtered = pharmacyController.searchMedicines(query);

    // // Filter medicines by name or pharmacy
    // List<Medicine> filtered = allMedicines.where((medicine) {
    //   return medicine.name.toLowerCase().contains(query.toLowerCase()) ||
    //       medicine.pharmacyName.toLowerCase().contains(query.toLowerCase());
    // }).toList();

    // // Only keep medicines with available stock
    // filtered = filtered.where((m) => m.quantity > 0).toList();

    // // Sort by price ascending
    // filtered.sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "$query"'),
        backgroundColor: AppColors.primary,
      ),
      body: filtered.isEmpty
          ? Center(
              child: Text('No results found for "$query".'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final Pharmacy pharmacy = filtered[index]['pharmacy'];
                final Medicine medicine = filtered[index]['medicine'];
// Inside ListView.builder
return Card(
  elevation: 3,
  margin: const EdgeInsets.only(bottom: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: InkWell(
    onTap: () {
      Navigator.pushNamed(
        context,
        Routes.pharmacyDetails,
        arguments: {
          'pharmacy': pharmacy,
          'medicine': medicine,
        } // pass the whole medicine object
      );
    },
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_pharmacy, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pharmacy: ${pharmacy.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: ${medicine.price} ETB | Stock: ${medicine.quantity}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ),
  ),
);

              },
            ),
    );
  }
}
