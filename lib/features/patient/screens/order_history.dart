import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../controllers/visited_pharmacies_controller.dart';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  final VisitedPharmaciesController _controller = VisitedPharmaciesController();
  List<SearchHistoryItem> _searchHistory = [];
  String? _query = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _controller.getSearchHistory();
    setState(() {
      _searchHistory = history;
      _isLoading = false;
    });
  }

  Future<void> _removeHistoryItem(int index) async {
    await _controller.removeSearchHistory(index);
    _loadSearchHistory();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content:
            const Text('Are you sure you want to clear all search history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.clearSearchHistory();
      _loadSearchHistory();
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Search History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          if (_searchHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAll,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchHistory.isEmpty
              ? const Center(
                  child: Text(
                    'No search history yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Builder(builder: (context) {
                  final filtered = _filteredHistory();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SearchField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () => setState(() {
                          _query = '';
                          _searchController.clear();
                        }),
                      ),
                      const SizedBox(height: 12),
                      ...filtered.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final inStock = item.medicineQuantity > 0;
                        return _HistoryTile(
                          item: item,
                          timestampText: _formatTimestamp(item.timestamp),
                          inStock: inStock,
                          onRemove: () => _removeHistoryItem(idx),
                          onOpen: () {
                            Navigator.pushNamed(
                              context,
                              Routes.searchResults,
                              arguments: item.medicineName,
                            );
                          },
                        );
                      }),
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            (_query ?? '').isEmpty
                                ? 'No history yet'
                                : 'No matches for "${_query ?? ''}"',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  );
                }),
    );
  }

  List<SearchHistoryItem> _filteredHistory() {
    final q = (_query ?? '').trim();
    if (q.isEmpty) return _searchHistory;
    final lower = q.toLowerCase();
    return _searchHistory.where((item) {
      final name = (item.medicineName).toString().toLowerCase();
      final pharmacyName = (item.pharmacy.name).toString().toLowerCase();
      return name.contains(lower) || pharmacyName.contains(lower);
    }).toList();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search history by medicine or pharmacy',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.timestampText,
    required this.inStock,
    required this.onRemove,
    required this.onOpen,
  });

  final SearchHistoryItem item;
  final String timestampText;
  final bool inStock;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.medicineName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      timestampText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.pharmacy.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.pharmacy.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill('${item.medicinePrice} ETB', AppColors.primary),
                    _pill(
                      inStock
                          ? 'Stock: ${item.medicineQuantity}'
                          : 'Out of stock',
                      inStock ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onRemove,
                splashRadius: 22,
                tooltip: 'Remove',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: onOpen,
                splashRadius: 22,
                tooltip: 'Open',
              ),
            ],
          ),
        ],
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
