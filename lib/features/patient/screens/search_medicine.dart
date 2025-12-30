import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../../pharmacy/controllers/pharmacy_controller.dart';

class SearchMedicine extends StatefulWidget {
  const SearchMedicine({super.key});

  @override
  State<SearchMedicine> createState() => _SearchMedicineState();
}

class _SearchMedicineState extends State<SearchMedicine> {
  final TextEditingController _controller = TextEditingController();

  List<String> recentSearches = [];
  List<String> suggestions = [];

  @override
  void initState() {
    super.initState();
    loadRecentSearches();
  }

  // 🔹 Load recent searches
  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  // 🔹 Save search
  Future<void> saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();

    recentSearches.remove(query);
    recentSearches.insert(0, query);

    await prefs.setStringList('recentSearches', recentSearches);
    setState(() {});
  }

  // 🔹 Delete recent search
  Future<void> deleteSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.remove(query);
    await prefs.setStringList('recentSearches', recentSearches);
    setState(() {});
  }

  // 🔹 Update live suggestions
  void updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    final controller = PharmacyController();
    final allMedicines = controller.pharmacies
        .expand((p) => p.medicines)
        .toList();

    setState(() {
      suggestions = allMedicines
          .map((m) => m.name)
          .toSet() // remove duplicates
          .where((name) => name.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Medicine')),
      body: Padding(
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
                child: const Text('Search'),
              ),
            ),

            // 🔹 Recent Searches
            if (recentSearches.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text(
                'Recent searches',
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
    );
  }
}
