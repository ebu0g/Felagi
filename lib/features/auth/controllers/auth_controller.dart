import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================= REGISTER =================
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role, // Patient | Pharmacy
  }) async {
    try {
      // 1️⃣ Create Auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2️⃣ Save Firestore user profile
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'role': role,
        'isApproved': true, // ✅ pharmacies are automatically approved
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Registration successful');
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  /// ================= LOGIN =================
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      final role = doc['role'];
      // Removed the isApproved check completely

      return role;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// ================= CURRENT USER =================
  User? get currentUser => _auth.currentUser;
}
