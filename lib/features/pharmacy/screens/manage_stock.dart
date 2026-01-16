import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';

class ManageStockScreen extends StatefulWidget {
  final Pharmacy pharmacy;
  final String? initialMedicineId;

  const ManageStockScreen({
    super.key,
    required this.pharmacy,
    this.initialMedicineId,
  });

  @override
  State<ManageStockScreen> createState() => _ManageStockScreenState();
}

class _ManageStockScreenState extends State<ManageStockScreen> {
  static const List<String> _categories = [
    'All',
    'Pain relief',
    'Cold & flu',
    'Vitamins',
    'Allergy',
    'Kids care',
    'Other',
  ];

  bool _handledInitial = false;
  String _selectedCategory = 'All';
  String _searchTerm = '';
  bool _onlyLowStock = false;
  bool _showSearch = false;
  String _sortOption = 'name';

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

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

    if (!_handledInitial && widget.initialMedicineId != null) {
      final idx = widget.pharmacy.medicines
          .indexWhere((m) => m.id == widget.initialMedicineId);
      if (idx != -1) {
        _handledInitial = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _editMedicine(idx);
        });
      }
    }
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
      setState(() => widget.pharmacy.medicines[index].quantity += 1);
    } catch (e) {
      _showError('Failed to increase quantity: $e');
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
      setState(() => widget.pharmacy.medicines[index].quantity -= 1);
    } catch (e) {
      _showError('Failed to decrease quantity: $e');
    }
  }

  Future<void> _confirmDelete(int index) async {
    final med = widget.pharmacy.medicines[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete medicine'),
          content: Text('Are you sure you want to delete ${med.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteMedicine(index);
    }
  }

  Future<void> _deleteMedicine(int index) async {
    final med = widget.pharmacy.medicines[index];
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final medRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .doc(med.id);

    try {
      await medRef.delete();
      if (!mounted) return;
      setState(() => widget.pharmacy.medicines.removeAt(index));
    } catch (e) {
      _showError('Failed to delete medicine: $e');
    }
  }

  Future<void> _editMedicine(int index) async {
    final med = widget.pharmacy.medicines[index];

    final result = await Navigator.pushNamed(
      context,
      Routes.editMedicine,
      arguments: {
        'name': med.name,
        'price': med.price,
        'quantity': med.quantity,
        'category': med.category,
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
        'name_lower': result['name'].toString().toLowerCase(),
        'price': result['price'],
        'quantity': result['quantity'],
        'category': result['category'],
        'category_lower': result['category'].toString().toLowerCase(),
      });

      if (!mounted) return;
      setState(() {
        widget.pharmacy.medicines[index]
          ..name = result['name']
          ..price = result['price']
          ..quantity = result['quantity']
          ..category = result['category'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = widget.pharmacy.medicines;
    final filtered = meds.where((m) {
      final name = m.name.toLowerCase();
      final cat =
          (m.category.isNotEmpty ? m.category : 'uncategorized').toLowerCase();
      final matchesSearch = _searchTerm.isEmpty || name.contains(_searchTerm);
      final matchesCategory = _selectedCategory == 'All'
          ? true
          : cat == _selectedCategory.toLowerCase();
      final matchesLow = _onlyLowStock ? m.quantity <= 5 : true;
      return matchesSearch && matchesCategory && matchesLow;
    }).toList();

    switch (_sortOption) {
      case 'qty_low':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'qty_high':
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      default:
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final int lowStockCount =
        meds.where((m) => m.quantity <= 5 && m.quantity > 0).length;
    final int outStockCount = meds.where((m) => m.quantity == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Stock',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        leading: const SizedBox.shrink(),
      ),
      body: RefreshIndicator(
        onRefresh: loadMedicines,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(meds.length, lowStockCount, outStockCount),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filters(),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    _emptyState('No medicines match these filters.')
                  else
                    ListView.separated(
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _medicineCard(filtered[index]);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(int total, int low, int out) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory overview',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check levels, restock, or edit items.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statPill('Total', total.toString(), AppColors.primary),
              const SizedBox(width: 8),
              _statPill('Low', low.toString(), Colors.orange),
              const SizedBox(width: 8),
              _statPill('Out', out.toString(), Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$label · $value',
            style:
                TextStyle(color: color.darken(), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: () => setState(() => _showSearch = !_showSearch),
              icon: Icon(_showSearch ? Icons.close : Icons.search),
            ),
          ],
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _showSearch
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _searchTerm = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
            ],
          ),
          secondChild: const SizedBox(height: 0),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _selectedCategory == c,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: _selectedCategory == c
                          ? AppColors.primary
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              FilterChip(
                label: const Text('Low stock'),
                selected: _onlyLowStock,
                onSelected: (v) => setState(() => _onlyLowStock = v),
                selectedColor: Colors.orange.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: _onlyLowStock ? Colors.orange[800] : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _sortOption,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                  DropdownMenuItem(
                      value: 'qty_low', child: Text('Qty: Low→High')),
                  DropdownMenuItem(
                      value: 'qty_high', child: Text('Qty: High→Low')),
                ],
                onChanged: (v) => setState(() => _sortOption = v ?? 'name'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _medicineCard(Medicine medicine) {
    final quantity = medicine.quantity;
    final bool isLowStock = quantity > 0 && quantity <= 5;
    final bool isOutOfStock = quantity == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medicine.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOutOfStock)
                _badge('Out', Colors.red)
              else if (isLowStock)
                _badge('Low', Colors.orange),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(medicine.category.isNotEmpty
                  ? medicine.category
                  : 'Uncategorized'),
              _pill('${medicine.price.toStringAsFixed(2)} ETB'),
              _pill('Stock: $quantity'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconAction(Icons.remove_circle_outline, Colors.orange,
                      onTap: () => _decreaseQuantity(
                          widget.pharmacy.medicines.indexOf(medicine))),
                  _iconAction(Icons.add_circle_outline, Colors.green,
                      onTap: () => _increaseQuantity(
                          widget.pharmacy.medicines.indexOf(medicine))),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _editMedicine(
                        widget.pharmacy.medicines.indexOf(medicine)),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(
                        widget.pharmacy.medicines.indexOf(medicine)),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.darken(),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color,
      {required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(icon),
      color: color.darken(),
      onPressed: onTap,
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

extension ColorShade on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
