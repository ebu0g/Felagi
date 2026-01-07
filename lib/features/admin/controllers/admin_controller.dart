import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;

  AdminController() {
    _initializePharmacies();
    // Do initial fetch to ensure data loads immediately
    _loadInitialData();
  }

  // Load initial data immediately
  Future<void> _loadInitialData() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Pharmacy')
          .get();

      debugPrint('Initial fetch: Found ${snapshot.docs.length} pharmacies');

      _pharmacies = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'email': data['email'] ?? 'No email',
          'location': data['address'] ?? 'Unknown',
          'status': data['isApproved'] == true
              ? 'approved'
              : (data['isRejected'] == true ? 'rejected' : 'pending'),
          'document': data['documentUrl'] ?? '',
          'phone': data['phone'] ?? 'No phone',
          'createdAt': data['createdAt'],
        };
      }).toList();

      // Sort by status (pending first, then approved, then rejected) and by createdAt (oldest first)
      _pharmacies.sort((a, b) {
        final statusOrder = {'pending': 0, 'approved': 1, 'rejected': 2};
        final aStatusOrder = statusOrder[a['status']] ?? 3;
        final bStatusOrder = statusOrder[b['status']] ?? 3;

        if (aStatusOrder != bStatusOrder) {
          return aStatusOrder.compareTo(bStatusOrder);
        }

        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });

      _isLoading = false;
      debugPrint(
          'Initial data loaded: ${_pharmacies.length} total, ${pendingPharmacies.length} pending');
      notifyListeners();
    } catch (e) {
      debugPrint('Initial fetch error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize and listen to Firestore in real-time
  void _initializePharmacies() {
    debugPrint('Starting real-time listener for pharmacies...');
    _isLoading = true;
    notifyListeners();

    _firestore
        .collection('users')
        .where('role', isEqualTo: 'Pharmacy')
        .snapshots()
        .listen((snapshot) {
      debugPrint(
          'Listener triggered: ${snapshot.docs.length} pharmacies found');

      _pharmacies = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['fullName'] ?? 'Unknown',
          'email': data['email'] ?? 'No email',
          'location': data['address'] ?? 'Unknown',
          'status': data['isApproved'] == true
              ? 'approved'
              : (data['isRejected'] == true ? 'rejected' : 'pending'),
          'document': data['documentUrl'] ?? '',
          'phone': data['phone'] ?? 'No phone',
          'createdAt': data['createdAt'],
        };
      }).toList();

      // Sort by status (pending first, then approved, then rejected) and by createdAt (oldest first)
      _pharmacies.sort((a, b) {
        final statusOrder = {'pending': 0, 'approved': 1, 'rejected': 2};
        final aStatusOrder = statusOrder[a['status']] ?? 3;
        final bStatusOrder = statusOrder[b['status']] ?? 3;

        if (aStatusOrder != bStatusOrder) {
          return aStatusOrder.compareTo(bStatusOrder);
        }

        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });

      _isLoading = false;
      debugPrint(
          'Pharmacies loaded: ${_pharmacies.length} total, ${pendingPharmacies.length} pending');
      notifyListeners();
    }, onError: (e) {
      debugPrint('Listener error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Map<String, dynamic>> get pendingPharmacies =>
      _pharmacies.where((p) => p['status'] == 'pending').toList();

  List<Map<String, dynamic>> get approvedPharmacies =>
      _pharmacies.where((p) => p['status'] == 'approved').toList();

  List<Map<String, dynamic>> get rejectedPharmacies =>
      _pharmacies.where((p) => p['status'] == 'rejected').toList();

  List<Map<String, dynamic>> get pharmacies => _pharmacies;

  bool get isLoading => _isLoading;

  Future<void> approvePharmacy(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isApproved': true,
      });
      debugPrint('Pharmacy approved: $uid');
    } catch (e) {
      debugPrint('Error approving pharmacy: $e');
    }
  }

  Future<void> rejectPharmacy(String uid) async {
    try {
      // Mark pharmacy as rejected instead of deleting
      await _firestore.collection('users').doc(uid).update({
        'isRejected': true,
      });
      debugPrint('Pharmacy rejected: $uid');
    } catch (e) {
      debugPrint('Error rejecting pharmacy: $e');
    }
  }

  // Admin info
  String adminName = "Main Admin";
  String adminEmail = "admin@example.com";
  String adminPhone = "+251900000000";

  // Update profile method
  void updateProfile(String name, String email, String phone) {
    adminName = name;
    adminEmail = email;
    adminPhone = phone;
    notifyListeners(); // notify UI about the change
  }

  List<String> admins = ['admin1@example.com', 'admin2@example.com'];

  void addAdmin(String email) {
    admins.add(email);
    notifyListeners();
  }

  void removeAdmin(String email) {
    admins.remove(email);
    notifyListeners();
  }

  // Initialize real-time messages listener
  void _initializeMessages() {
    _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      debugPrint('Messages loaded: ${snapshot.docs.length}');
      notifyListeners();
    }, onError: (e) {
      debugPrint('Messages listener error: $e');
    });
  }
}
