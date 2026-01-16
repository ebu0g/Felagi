import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _pharmacies = [];
  int _openSupportCount = 0;
  List<Map<String, dynamic>> _openSupportRequests = [];
  bool _isLoading = true;

  AdminController() {
    _initializePharmacies();
    _initializeSupportRequests();
    _loadInitialSupportRequests();
    // Do initial fetch to ensure data loads immediately
    _loadInitialData();
  }

  // One-time fetch to ensure support requests show even if the stream is delayed
  Future<void> _loadInitialSupportRequests() async {
    try {
      final snapshot = await _firestore.collection('support_requests').get();
      _ingestSupportSnapshot(snapshot);
    } catch (e) {
      debugPrint('Initial support fetch error: $e');
    }
  }

  // Load initial data immediately
  Future<void> _loadInitialData() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Pharmacy')
          .get();

      debugPrint('Initial fetch: Found ${snapshot.docs.length} pharmacies');
      _processSnapshot(snapshot);
      debugPrint(
          'Initial data loaded: ${_pharmacies.length} total, ${pendingPharmacies.length} pending');
    } catch (e) {
      debugPrint('Initial fetch error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manual refresh trigger for UI actions
  Future<void> fetchPharmacies() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Pharmacy')
          .get();
      debugPrint('Manual refresh: Found ${snapshot.docs.length} pharmacies');
      _processSnapshot(snapshot);
    } catch (e) {
      debugPrint('Manual refresh error: $e');
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
      _processSnapshot(snapshot);
      debugPrint(
          'Pharmacies loaded: ${_pharmacies.length} total, ${pendingPharmacies.length} pending');
    }, onError: (e) {
      debugPrint('Listener error: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  void _initializeSupportRequests() {
    _firestore.collection('support_requests').snapshots().listen((snapshot) {
      _ingestSupportSnapshot(snapshot);
    }, onError: (e) {
      debugPrint('Support listener error: $e');
    });
  }

  void _ingestSupportSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    int openCount = 0;
    final List<Map<String, dynamic>> items = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status.isEmpty || status == 'open') {
        openCount += 1;
        items.add({
          'id': doc.id,
          'type': data['type'] ?? '',
          'uid': data['uid'] ?? '',
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'message': data['message'] ?? '',
          'appealMessage': data['appealMessage'] ?? '',
          'createdAt': data['createdAt'],
          'requestedAt': data['requestedAt'],
          'updatedAt': data['updatedAt'],
        });
      }
    }

    // Sort newest first using updatedAt/requestedAt fallback
    items.sort((a, b) {
      final aTime =
          (a['updatedAt'] ?? a['requestedAt'] ?? a['createdAt']) as Timestamp?;
      final bTime =
          (b['updatedAt'] ?? b['requestedAt'] ?? b['createdAt']) as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    _openSupportCount = openCount;
    _openSupportRequests = items;
    notifyListeners();
  }

  void _processSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
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
    notifyListeners();
  }

  List<Map<String, dynamic>> get pendingPharmacies =>
      _pharmacies.where((p) => p['status'] == 'pending').toList();

  List<Map<String, dynamic>> get approvedPharmacies =>
      _pharmacies.where((p) => p['status'] == 'approved').toList();

  List<Map<String, dynamic>> get rejectedPharmacies =>
      _pharmacies.where((p) => p['status'] == 'rejected').toList();

  List<Map<String, dynamic>> get pharmacies => _pharmacies;

  int get openSupportCount => _openSupportCount;
  List<Map<String, dynamic>> get openSupportRequests => _openSupportRequests;

  bool get isLoading => _isLoading;

  Future<void> approvePharmacy(String uid) async {
    try {
      // Mark approved and clear any previous rejection flag so
      // login-time checks (which first check isRejected) don't block approved users.
      await _firestore.collection('users').doc(uid).update({
        'isApproved': true,
        'isRejected': false,
      });
      // Close any open rejection ticket for this pharmacy so it disappears from notifications
      try {
        await _firestore
            .collection('support_requests')
            .doc('rejection_' + uid)
            .set({
          'status': 'closed',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to close support ticket for $uid: $e');
      }
      debugPrint('Pharmacy approved: $uid');
    } catch (e) {
      debugPrint('Error approving pharmacy: $e');
    }
  }

  Future<void> closeSupportRequest(String docId) async {
    try {
      await _firestore.collection('support_requests').doc(docId).set({
        'status': 'closed',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Support request closed: $docId');
    } catch (e) {
      debugPrint('Error closing support request $docId: $e');
    }
  }

  Future<void> rejectPharmacy(String uid) async {
    try {
      // Mark pharmacy as rejected instead of deleting
      // Mark rejected and clear any approval flag so the status is unambiguous.
      await _firestore.collection('users').doc(uid).update({
        'isRejected': true,
        'isApproved': false,
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

  // Message listener intentionally omitted — add when messaging UI is implemented.
}
