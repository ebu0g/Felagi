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
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Registration failed: ${e.code}');
    } catch (e) {
      debugPrint('Registration error: $e');
      // If Firestore write fails but Auth user was created, delete the Auth user
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (deleteError) {
          debugPrint('Failed to delete auth user: $deleteError');
        }
      }
      throw Exception('Registration failed: ${e.toString()}');
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
        debugPrint('User profile not found in Firestore for uid: $uid');
        throw Exception('User profile not found. Please register again.');
      }

      final role = doc['role'];
      if (role == null || role.toString().isEmpty) {
        debugPrint('Role is null or empty for uid: $uid');
        throw Exception('User role not found in profile');
      }

      debugPrint('Login successful for role: $role');
      return role.toString();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Login failed: ${e.code}');
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// ================= RESET PASSWORD =================
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      
      // Provide user-friendly error messages
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'This email address is not registered. Please check your email or create an account.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled. Please contact support.';
          break;
        default:
          errorMessage = e.message ?? 'Password reset failed: ${e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// ================= CURRENT USER =================
  User? get currentUser => _auth.currentUser;
}
