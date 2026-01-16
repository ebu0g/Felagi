import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/pharmacy.dart';
import '../models/medicine.dart';

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key});

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<Map<String, dynamic>?>? _pharmacyDataFuture;

  final List<String> _categories = const [
    'All',
    'Pain relief',
    'Cold & flu',
    'Vitamins',
    'Allergy',
    'Kids care',
    'Other',
  ];

  String _selectedCategory = 'All';
  String _searchTerm = '';
  bool _onlyLowStock = false;

  @override
  void initState() {
    super.initState();
    _pharmacyDataFuture = _fetchPharmacyData();
  }

  Future<Map<String, dynamic>?> _ensurePharmacyFuture() {
    _pharmacyDataFuture ??= _fetchPharmacyData();
    return _pharmacyDataFuture!;
  }

  Future<Map<String, dynamic>?> _fetchPharmacyData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  String _resolvePharmacyName(Map<String, dynamic>? data) {
    final rawName = (data?['fullName'] ??
            data?['full_name'] ??
            data?['pharmacyName'] ??
            data?['name'] ??
            '')
        .toString()
        .trim();

    final looksGeneric =
        rawName.isEmpty || rawName.toLowerCase().contains('hub');
    return looksGeneric ? 'Pharmacy' : rawName;
  }

  Future<void> _openManageStock(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      final pharmacy = Pharmacy(
        id: doc.id,
        name: (data['fullName'] ?? 'Your Pharmacy').toString(),
        address: (data['address'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        medicines: <Medicine>[],
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        Routes.manageStock,
        arguments: pharmacy,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open stock manager: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openManageStockForMedicine(
    BuildContext context,
    String medicineId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      final pharmacy = Pharmacy(
        id: doc.id,
        name: (data['fullName'] ?? 'Your Pharmacy').toString(),
        address: (data['address'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        medicines: <Medicine>[],
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        Routes.manageStock,
        arguments: {
          'pharmacy': pharmacy,
          'medicineId': medicineId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open stock manager: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Please sign in again'))
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _pharmacyDataFuture = _fetchPharmacyData();
                  });
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: _ensurePharmacyFuture(),
                                    builder: (context, snapshot) {
                                      final displayName =
                                          snapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? 'Loading...'
                                              : _resolvePharmacyName(
                                                  snapshot.data,
                                                );
                                      return Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add, manage, and keep stock fresh.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.logout, color: Colors.white),
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await AuthController().logout();
                                navigator.pushNamedAndRemoveUntil(
                                  Routes.home,
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick actions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _actionCard(
                                    context,
                                    label: 'Add medicine',
                                    icon: Icons.add_circle_outline,
                                    color: AppColors.primary,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      Routes.addMedicine,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _actionCard(
                                    context,
                                    label: 'Profile',
                                    icon: Icons.storefront,
                                    color: AppColors.accent,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      Routes.pharmacyProfile,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _actionCard(
                              context,
                              label: 'Manage stock',
                              icon: Icons.inventory_2_outlined,
                              color: Colors.deepPurple,
                              onTap: () => _openManageStock(context),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Your medicines',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: InputDecoration(
                                hintText: 'Search medicine by name',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() =>
                                    _searchTerm = value.trim().toLowerCase());
                              },
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ..._categories.map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(c),
                                        selected: _selectedCategory == c,
                                        onSelected: (_) {
                                          setState(() => _selectedCategory = c);
                                        },
                                        selectedColor: AppColors.primary
                                            .withValues(alpha: 0.15),
                                        labelStyle: TextStyle(
                                          color: _selectedCategory == c
                                              ? AppColors.primary
                                              : Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: FilterChip(
                                      label: const Text('Low stock'),
                                      selected: _onlyLowStock,
                                      onSelected: (v) {
                                        setState(() => _onlyLowStock = v);
                                      },
                                      selectedColor:
                                          Colors.orange.withValues(alpha: 0.15),
                                      labelStyle: TextStyle(
                                        color: _onlyLowStock
                                            ? Colors.orange[800]
                                            : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('medicines')
                                  .orderBy('createdAt', descending: true)
                                  .limit(20)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 12,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'No medicines yet. Add your first item to get started.',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  );
                                }

                                final filtered = docs.where((d) {
                                  final data = d.data() as Map<String, dynamic>;
                                  final name = (data['name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  final category =
                                      (data['category'] ?? 'uncategorized')
                                          .toString()
                                          .toLowerCase();
                                  final qty = (data['quantity'] ?? 0) as int;

                                  final matchesSearch = _searchTerm.isEmpty
                                      ? true
                                      : name.contains(_searchTerm);

                                  final matchesCategory =
                                      _selectedCategory == 'All'
                                          ? true
                                          : category ==
                                              _selectedCategory.toLowerCase();

                                  final matchesLow =
                                      _onlyLowStock ? qty <= 5 : true;

                                  return matchesSearch &&
                                      matchesCategory &&
                                      matchesLow;
                                }).toList();

                                if (filtered.isEmpty) {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
                                          blurRadius: 12,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'No matches. Adjust search or filters.',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final data = filtered[index].data()
                                        as Map<String, dynamic>;
                                    final docId = filtered[index].id;
                                    return _medicineTile(data, () {
                                      _openManageStockForMedicine(
                                          context, docId);
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 26),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _medicineTile(Map<String, dynamic> data, VoidCallback onTap) {
    final name = (data['name'] ?? '').toString();
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final qty = data['quantity'] ?? 0;
    final category = (data['category'] ?? 'Uncategorized').toString();
    final bool isLow = qty > 0 && qty <= 5;
    final bool isOut = qty == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.18),
              ),
              child: const Icon(Icons.medication, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOut)
                        _badge('Out of stock', Colors.red)
                      else if (isLow)
                        _badge('Low stock', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _chip(category),
                      _chip('${price.toStringAsFixed(2)} ETB'),
                      _chip('Stock: $qty'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
