import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../../pharmacy/models/medicine.dart';
import '../../pharmacy/models/pharmacy.dart';
import '../controllers/visited_pharmacies_controller.dart';

class SearchResults extends StatefulWidget {
  const SearchResults({super.key});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

enum _SortOption { relevance, priceAsc, priceDesc, stockDesc }

class _SearchResultsState extends State<SearchResults> {
  _SortOption _sort = _SortOption.relevance;
  bool _inStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final String query =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';

    final String search = query.trim().toLowerCase();
    final bool searchByCategory = _isCategory(search);
    final String medicineSearched = query.trim();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Results for "$query"',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: searchByCategory
            ? FirebaseFirestore.instance
                .collectionGroup('medicines')
                .where('category_lower', isEqualTo: search)
                .snapshots()
            : FirebaseFirestore.instance
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
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
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
            debugPrint(
                'No prefix results found. Running fallback contains search for "$search"');
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fallbackContainsSearch(search),
              builder: (context, fbSnap) {
                if (fbSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final fallback = fbSnap.data ?? [];
                if (fallback.isEmpty) {
                  return Center(
                    child: Text('No results found for "$query".'),
                  );
                }

                return _buildList(context, fallback, medicineSearched);
              },
            );
          }

          debugPrint('Found ${snapshot.data!.docs.length} medicine documents');

          final docs = snapshot.data!.docs;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _filterPharmacyMedicines(docs),
            builder: (context, filteredSnapshot) {
              if (filteredSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredResults = filteredSnapshot.data ?? [];

              if (filteredResults.isEmpty) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fallbackContainsSearch(search),
                  builder: (context, fbSnap) {
                    if (fbSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final fallback = fbSnap.data ?? [];
                    if (fallback.isEmpty) {
                      return Center(
                        child: Text('No results found for "$query".'),
                      );
                    }

                    return _buildList(context, fallback, medicineSearched);
                  },
                );
              }

              return _buildList(context, filteredResults, medicineSearched);
            },
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items,
      String medicineSearched) {
    final visibleItems = _applyFilters(items);

    return Column(
      children: [
        _FiltersBar(
          total: items.length,
          visible: visibleItems.length,
          sort: _sort,
          inStockOnly: _inStockOnly,
          onSortChanged: (option) => setState(() => _sort = option),
          onStockToggle: (value) => setState(() => _inStockOnly = value),
        ),
        if (visibleItems.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No items match the current filters'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final result = visibleItems[index];
                final medicine = result['medicine'] as Medicine;
                final pharmacy = result['pharmacy'] as Pharmacy;

                return _ResultCard(
                  medicine: medicine,
                  pharmacy: pharmacy,
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final historyController = VisitedPharmaciesController();

                    await historyController.addSearchHistory(
                      medicineSearched,
                      medicine,
                      pharmacy,
                    );

                    navigator.pushNamed(
                      Routes.pharmacyDetails,
                      arguments: {
                        'pharmacy': pharmacy,
                        'medicine': medicine,
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> items) {
    var list = List<Map<String, dynamic>>.from(items);

    if (_inStockOnly) {
      list = list
          .where((item) => (item['medicine'] as Medicine).quantity > 0)
          .toList();
    }

    switch (_sort) {
      case _SortOption.priceAsc:
        list.sort((a, b) => (a['medicine'] as Medicine)
            .price
            .compareTo((b['medicine'] as Medicine).price));
        break;
      case _SortOption.priceDesc:
        list.sort((a, b) => (b['medicine'] as Medicine)
            .price
            .compareTo((a['medicine'] as Medicine).price));
        break;
      case _SortOption.stockDesc:
        list.sort((a, b) => (b['medicine'] as Medicine)
            .quantity
            .compareTo((a['medicine'] as Medicine).quantity));
        break;
      case _SortOption.relevance:
        break;
    }

    return list;
  }

  bool _isCategory(String value) {
    const categories = [
      'pain relief',
      'cold & flu',
      'vitamins',
      'allergy',
      'kids care',
      'other',
    ];
    return categories.contains(value);
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
          category: (data['category'] ?? 'Uncategorized').toString(),
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

  Future<List<Map<String, dynamic>>> _fallbackContainsSearch(
      String search) async {
    if (search.isEmpty) return [];

    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('medicines')
          .limit(200)
          .get();

      final List<Map<String, dynamic>> matches = [];
      final lowerSearch = search.toLowerCase();

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString();
        if (name.isEmpty || !name.toLowerCase().contains(lowerSearch)) {
          continue;
        }

        final pharmacyRef = doc.reference.parent.parent;
        if (pharmacyRef == null) continue;
        final pharmacyDoc = await pharmacyRef.get();
        if (!pharmacyDoc.exists) continue;
        final pData = pharmacyDoc.data() as Map<String, dynamic>;
        if (pData['role'] != 'Pharmacy') continue;

        matches.add({
          'medicine': Medicine(
            id: doc.id,
            name: name,
            price: (data['price'] as num?)?.toDouble() ?? 0.0,
            quantity: data['quantity'] ?? 0,
            category: (data['category'] ?? 'Uncategorized').toString(),
          ),
          'pharmacy': Pharmacy(
            id: pharmacyRef.id,
            name: pData['fullName'] ?? '',
            address: pData['address'] ?? '',
            phone: pData['phone'] ?? '',
            medicines: const [],
          ),
        });
      }

      return matches;
    } catch (e) {
      debugPrint('Fallback search failed: $e');
      return [];
    }
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.total,
    required this.visible,
    required this.sort,
    required this.inStockOnly,
    required this.onSortChanged,
    required this.onStockToggle,
  });

  final int total;
  final int visible;
  final _SortOption sort;
  final bool inStockOnly;
  final ValueChanged<_SortOption> onSortChanged;
  final ValueChanged<bool> onStockToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$visible of $total results',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Relevance', _SortOption.relevance, Icons.filter_list),
              _chip('Price ↑', _SortOption.priceAsc, Icons.arrow_upward),
              _chip('Price ↓', _SortOption.priceDesc, Icons.arrow_downward),
              _chip('Stock', _SortOption.stockDesc, Icons.inventory_2),
              FilterChip(
                label: const Text('In stock'),
                selected: inStockOnly,
                onSelected: onStockToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _SortOption option, IconData icon) {
    final bool selected = sort == option;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSortChanged(option),
      selectedColor: AppColors.primary.withAlpha(30),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : Colors.black,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.medicine,
    required this.pharmacy,
    required this.onTap,
  });

  final Medicine medicine;
  final Pharmacy pharmacy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool inStock = medicine.quantity > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill('${medicine.price} ETB', AppColors.primary),
                      const SizedBox(width: 8),
                      _pill('Stock: ${medicine.quantity}',
                          inStock ? Colors.green : Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharmacy.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pharmacy.phone,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
