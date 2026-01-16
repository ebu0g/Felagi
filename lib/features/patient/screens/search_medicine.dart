import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';

class SearchMedicine extends StatefulWidget {
  const SearchMedicine({super.key});

  @override
  State<SearchMedicine> createState() => _SearchMedicineState();
}

class _SearchMedicineState extends State<SearchMedicine> {
  final TextEditingController _controller = TextEditingController();

  List<String> recentSearches = [];
  List<String> suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    loadRecentSearches();
  }

  // 🔹 Load recent searches (scoped to current user)
  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final key = uid == null ? 'recentSearches' : 'recentSearches_$uid';
    setState(() {
      recentSearches = prefs.getStringList(key) ?? [];
    });
  }

  // 🔹 Save search
  Future<void> saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final key = uid == null ? 'recentSearches' : 'recentSearches_$uid';

    recentSearches.remove(query);
    recentSearches.insert(0, query);

    await prefs.setStringList(key, recentSearches);
    setState(() {});
  }

  // 🔹 Delete recent search
  Future<void> deleteSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final key = uid == null ? 'recentSearches' : 'recentSearches_$uid';

    recentSearches.remove(query);
    await prefs.setStringList(key, recentSearches);
    setState(() {});
  }

  // 🔹 Update live suggestions with debounce + Firestore prefix search
  void updateSuggestions(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = query.trim();
      if (q.isEmpty) {
        if (mounted) setState(() => suggestions = []);
        return;
      }

      final search = q.toLowerCase();

      try {
        final snap = await FirebaseFirestore.instance
            .collectionGroup('medicines')
            .where('name_lower', isGreaterThanOrEqualTo: search)
            .where('name_lower', isLessThanOrEqualTo: '$search\uf8ff')
            .limit(20)
            .get();

        final names = <String>{};

        for (final doc in snap.docs) {
          final data = doc.data();
          final name = (data['name'] ?? '').toString();
          if (name.isNotEmpty) names.add(name);
        }

        // Fuzzy fallback if no prefix matches
        if (names.isEmpty) {
          final first = search[0];
          final broader = await FirebaseFirestore.instance
              .collectionGroup('medicines')
              .where('name_lower', isGreaterThanOrEqualTo: first)
              .where('name_lower', isLessThanOrEqualTo: '$first\uf8ff')
              .limit(200)
              .get();

          final candidates = <String>[];
          for (final doc in broader.docs) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString();
            if (name.isNotEmpty) candidates.add(name);
          }

          candidates.sort((a, b) {
            final da = _levenshtein(a.toLowerCase(), search);
            final db = _levenshtein(b.toLowerCase(), search);
            return da.compareTo(db);
          });

          for (var i = 0; i < candidates.length && i < 10; i++) {
            names.add(candidates[i]);
          }
        }

        if (mounted) setState(() => suggestions = names.toList());
      } catch (e) {
        if (mounted) setState(() => suggestions = []);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Simple Levenshtein distance for fuzzy ranking
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final v0 = List<int>.filled(t.length + 1, 0);
    final v1 = List<int>.filled(t.length + 1, 0);

    for (var i = 0; i <= t.length; i++) v0[i] = i;

    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      for (var j = 0; j <= t.length; j++) v0[j] = v1[j];
    }

    return v1[t.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Search Medicine',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 Search Input
              TextField(
                controller: _controller,
                onChanged: updateSuggestions,
                decoration: InputDecoration(
                  hintText: 'Enter medicine name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // 🔹 Suggestions
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final name = suggestions[index];

                    return ListTile(
                      leading: const Icon(Icons.search),
                      title: Text(name),
                      onTap: () {
                        _controller.text = name;
                        saveSearch(name);

                        Navigator.pushNamed(
                          context,
                          Routes.searchResults,
                          arguments: name,
                        );
                      },
                    );
                  },
                ),
              ],

              const SizedBox(height: 20),

              // 🔍 Search Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    final query = _controller.text.trim();
                    if (query.isEmpty) return;

                    saveSearch(query);

                    Navigator.pushNamed(
                      context,
                      Routes.searchResults,
                      arguments: query,
                    );
                  },
                  child: const Text(
                    'Search',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              // 🔹 Recent Searches (per-user)
              if (recentSearches.isNotEmpty) ...[
                const SizedBox(height: 30),
                const Text(
                  'Recent Searches',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSearches.length,
                  itemBuilder: (context, index) {
                    final query = recentSearches[index];

                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(query),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.searchResults,
                          arguments: query,
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => deleteSearch(query),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
