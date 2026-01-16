import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/visited_pharmacies_controller.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key, this.onOpenSearchTab});

  final VoidCallback? onOpenSearchTab;

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  final VisitedPharmaciesController _controller = VisitedPharmaciesController();
  List<SearchHistoryItem> _recentSearches = [];
  bool _isLoading = true;
  String _userName = '';
  String _role = '';
  final List<_MedicineHighlight> _popularMedicines = const [
    _MedicineHighlight(
      name: 'Paracetamol',
      usage: 'Pain & fever relief',
      icon: Icons.medication_rounded,
      background: Color(0xFFE7F5EC),
    ),
    _MedicineHighlight(
      name: 'Amoxicillin',
      usage: 'Antibiotic course',
      icon: Icons.vaccines,
      background: Color(0xFFDFF0E5),
    ),
    _MedicineHighlight(
      name: 'Ibuprofen',
      usage: 'Muscle & joint pain',
      icon: Icons.healing,
      background: Color(0xFFFFF4EC),
    ),
    _MedicineHighlight(
      name: 'Vitamin C',
      usage: 'Immunity boost',
      icon: Icons.health_and_safety,
      background: Color(0xFFEFFBF4),
    ),
    _MedicineHighlight(
      name: 'Cetirizine',
      usage: 'Allergy relief',
      icon: Icons.grass,
      background: Color(0xFFFFF3F6),
    ),
  ];

  final List<String> _quickFilters = const [
    'Pain relief',
    'Cold & flu',
    'Vitamins',
    'Allergy',
    'Kids care',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadRecentSearches();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final providerDisplayFallback = user.providerData
        .map((p) => (p.displayName ?? '').trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    final providerEmailFull = user.providerData
        .map((p) => (p.email ?? '').trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    final providerEmailPrefix = user.providerData
        .map((p) => (p.email ?? '').trim())
        .map((email) => email.contains('@') ? email.split('@').first : email)
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    final immediateFallback = [
      (user.displayName ?? '').trim(),
      providerDisplayFallback,
      (user.email ?? '').trim(),
      providerEmailFull,
      (user.email?.split('@').first ?? '').trim(),
      providerEmailPrefix,
      (user.phoneNumber ?? '').trim(),
    ].firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (immediateFallback.isNotEmpty && mounted) {
      setState(() {
        _userName = immediateFallback;
      });
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return;
      final data = doc.data();
      final fetchedName =
          (data?['fullName'] ?? data?['full_name'] ?? data?['name'] ?? '')
              .toString()
              .trim();
      final fetchedRole = (data?['role'] ?? '').toString().trim();
      final displayNameFallback = (user.displayName ?? '').trim();

      if (!mounted) return;
      setState(() {
        final emailFallbackFull = (user.email ?? '').trim().isNotEmpty
            ? (user.email ?? '').trim()
            : providerEmailFull;
        final emailFallbackPrefix = (user.email ?? '').trim().contains('@')
            ? (user.email ?? '').split('@').first.trim()
            : (user.email ?? '').trim();
        final emailFallback = emailFallbackPrefix.isNotEmpty
            ? emailFallbackPrefix
            : providerEmailPrefix;
        final phoneFallback = (user.phoneNumber ?? '').trim();
        final keepExisting = _userName.trim();

        debugPrint(
            'PatientHome name resolve -> fetchedName="$fetchedName", displayName="$displayNameFallback", providerDisplay="$providerDisplayFallback", emailFull="$emailFallbackFull", emailPrefix="$emailFallback", phone="$phoneFallback", keepExisting="$keepExisting"');

        _userName = [
          fetchedName,
          displayNameFallback,
          providerDisplayFallback,
          keepExisting,
          emailFallback,
          emailFallbackFull,
          providerEmailPrefix,
          providerEmailFull,
          phoneFallback,
          'User',
        ].firstWhere((v) => v.isNotEmpty, orElse: () => 'User');

        _role = fetchedRole;
      });
    } catch (e) {
      // Keep silent fallback; greeting will degrade gracefully.
    }
  }

  Future<void> _loadRecentSearches() async {
    final allHistory = await _controller.getSearchHistory();
    setState(() {
      // Show only 2 most recent items
      _recentSearches =
          allHistory.length > 2 ? allHistory.sublist(0, 2) : allHistory;
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when returning to this screen
    _loadRecentSearches();
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentSearches,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName.isNotEmpty ? _userName : 'User',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                    'Search and track meds',
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.white70),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              await AuthController().logout();
                              if (!mounted) return;
                              navigator.pushNamedAndRemoveUntil(
                                Routes.home,
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          // If we are inside the bottom nav, switch to Search tab; otherwise push the page.
                          if (widget.onOpenSearchTab != null) {
                            widget.onOpenSearchTab!.call();
                          } else {
                            Navigator.pushNamed(context, Routes.searchMedicine);
                          }
                        },
                        child: Material(
                          color: Colors.white,
                          elevation: 6,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.search, color: Colors.grey),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Search medicines or pharmacies',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    color: AppColors.primary, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popular medicines',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 190,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _popularMedicines.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) =>
                              _medicineHighlightCard(
                            context,
                            _popularMedicines[index],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickFilters
                            .map(
                              (filter) => ActionChip(
                                label: Text(filter),
                                backgroundColor:
                                    AppColors.accent.withValues(alpha: 0.12),
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  Routes.searchResults,
                                  arguments: filter,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent history',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, Routes.searchHistory)
                                  .then((_) => _loadRecentSearches());
                            },
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _recentSearches.isEmpty
                              ? Container(
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
                                    'No history yet. Start by searching for a medicine.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                )
                              : Column(
                                  children: _recentSearches
                                      .map(
                                        (item) => _searchHistoryTile(
                                          context,
                                          item,
                                        ),
                                      )
                                      .toList(),
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

  Widget _medicineHighlightCard(
    BuildContext context,
    _MedicineHighlight highlight,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.searchResults,
        arguments: highlight.name,
      ),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight.background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(
                highlight.icon,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              highlight.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              highlight.usage,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: const [
                Text(
                  'Tap to search',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchHistoryTile(BuildContext context, SearchHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.local_pharmacy,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicineName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.store_mall_directory,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.pharmacy.name,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.medicinePrice} ETB',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.searchResults,
                    arguments: item.medicineName,
                  );
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                splashRadius: 20,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.searchResults,
                    arguments: item.medicineName,
                  );
                },
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MedicineHighlight {
  const _MedicineHighlight({
    required this.name,
    required this.usage,
    required this.icon,
    required this.background,
  });

  final String name;
  final String usage;
  final IconData icon;
  final Color background;
}
