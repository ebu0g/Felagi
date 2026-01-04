import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pharmacy/models/pharmacy.dart';
import '../../pharmacy/models/medicine.dart';

class SearchHistoryItem {
  final String medicineName;
  final String medicineId;
  final double medicinePrice;
  final int medicineQuantity;
  final Pharmacy pharmacy;
  final String timestamp;

  SearchHistoryItem({
    required this.medicineName,
    required this.medicineId,
    required this.medicinePrice,
    required this.medicineQuantity,
    required this.pharmacy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'medicineName': medicineName,
        'medicineId': medicineId,
        'medicinePrice': medicinePrice,
        'medicineQuantity': medicineQuantity,
        'pharmacy': {
          'id': pharmacy.id,
          'name': pharmacy.name,
          'address': pharmacy.address,
          'phone': pharmacy.phone,
        },
        'timestamp': timestamp,
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      medicineName: json['medicineName'] ?? '',
      medicineId: json['medicineId'] ?? '',
      medicinePrice: (json['medicinePrice'] as num?)?.toDouble() ?? 0.0,
      medicineQuantity: json['medicineQuantity'] ?? 0,
      pharmacy: Pharmacy(
        id: json['pharmacy']['id'] ?? '',
        name: json['pharmacy']['name'] ?? '',
        address: json['pharmacy']['address'] ?? '',
        phone: json['pharmacy']['phone'] ?? '',
        medicines: [],
      ),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class VisitedPharmaciesController {
  static const String _key = 'search_history';

  // Add a search history item (medicine + pharmacy)
  Future<void> addSearchHistory(String medicineName, Medicine medicine, Pharmacy pharmacy) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = await getSearchHistory();
    
    // Create new history item
    final newItem = SearchHistoryItem(
      medicineName: medicineName,
      medicineId: medicine.id,
      medicinePrice: medicine.price,
      medicineQuantity: medicine.quantity,
      pharmacy: pharmacy,
      timestamp: DateTime.now().toIso8601String(),
    );
    
    // Add to the beginning
    historyList.insert(0, newItem);
    
    // Keep only last 100 searches
    if (historyList.length > 100) {
      historyList.removeRange(100, historyList.length);
    }
    
    // Save to SharedPreferences
    final jsonList = historyList.map((item) => item.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  // Get all search history
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => SearchHistoryItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Clear all search history
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // Remove a specific search history item
  Future<void> removeSearchHistory(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = await getSearchHistory();
    
    if (index >= 0 && index < historyList.length) {
      historyList.removeAt(index);
      
      final jsonList = historyList.map((item) => item.toJson()).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    }
  }

  // Legacy methods for backward compatibility (if needed)
  Future<void> addVisitedPharmacy(Pharmacy pharmacy) async {
    // This is now handled by addSearchHistory
  }

  Future<List<Pharmacy>> getVisitedPharmacies() async {
    final history = await getSearchHistory();
    // Return unique pharmacies from history
    final Map<String, Pharmacy> uniquePharmacies = {};
    for (var item in history) {
      if (!uniquePharmacies.containsKey(item.pharmacy.id)) {
        uniquePharmacies[item.pharmacy.id] = item.pharmacy;
      }
    }
    return uniquePharmacies.values.toList();
  }

  Future<void> clearVisitedPharmacies() async {
    await clearSearchHistory();
  }

  Future<void> removeVisitedPharmacy(String pharmacyId) async {
    final history = await getSearchHistory();
    history.removeWhere((item) => item.pharmacy.id == pharmacyId);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }
}

