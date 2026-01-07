import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ================= REGISTER =================
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String role, // Patient | Pharmacy | Admin
    String? documentLink, // Google Drive link for Pharmacy
  }) async {
    try {
      debugPrint('🔵 REGISTER START: email=$email, role=$role');
      debugPrint(
          '📄 Document link provided: ${documentLink != null && documentLink.isNotEmpty}');

      // 1️⃣ Create Auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      debugPrint('✅ Auth user created: $uid');

      // 2️⃣ Validate document link for Pharmacy
      String? documentUrl;
      if (role == 'Pharmacy') {
        if (documentLink == null || documentLink.isEmpty) {
          debugPrint(
              '❌ Pharmacy requires Google Drive link but documentLink is empty');
          // Delete auth user since Pharmacy MUST have document link
          try {
            await _auth.currentUser!.delete();
            debugPrint('   ✅ Auth user deleted');
          } catch (deleteError) {
            debugPrint('   ⚠️  Failed to delete auth user: $deleteError');
          }
          throw Exception(
              'Pharmacy registration requires a Google Drive document link.');
        }

        // Validate it's a valid Google Drive link
        if (!documentLink.contains('drive.google.com')) {
          try {
            await _auth.currentUser!.delete();
            debugPrint('   ✅ Auth user deleted');
          } catch (deleteError) {
            debugPrint('   ⚠️  Failed to delete auth user: $deleteError');
          }
          throw Exception('Please provide a valid Google Drive link.');
        }

        documentUrl = documentLink;
        debugPrint(
            '✅ Google Drive link validated: ${documentUrl.substring(0, 50)}...');
      }

      // 3️⃣ Determine approval status
      // Pharmacy requires approval, Patient and Admin are auto-approved
      bool isApproved = role != 'Pharmacy';
      debugPrint('   - isApproved: $isApproved (role=$role)');

      // 4️⃣ Save Firestore user profile
      final userData = {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'role': role,
        'isApproved': isApproved,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add document URL if available
      if (documentUrl != null) {
        userData['documentUrl'] = documentUrl;
        debugPrint(
            '📝 Adding documentUrl to Firestore: ${documentUrl.substring(0, 50)}...');
      } else {
        debugPrint('⚠️  documentUrl is null - will not be saved to Firestore');
      }

      debugPrint('💾 Saving to Firestore: users/$uid');
      debugPrint('   - Data: ${userData.keys.join(", ")}');

      await _firestore.collection('users').doc(uid).set(userData);
      debugPrint('✅ Firestore save completed');

      debugPrint(
          '🟢 REGISTER COMPLETE: uid=$uid, role=$role, hasDocument=${documentUrl != null}');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Registration failed: ${e.code}');
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      debugPrint('   Stack trace: $e');
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

      // Check if pharmacy is rejected
      if (role.toString() == 'Pharmacy') {
        final isRejected = doc.data()?.containsKey('isRejected') == true
            ? doc['isRejected']
            : false;
        if (isRejected) {
          debugPrint('Pharmacy login attempted but rejected: $uid');
          throw Exception(
              'Your pharmacy registration was rejected by admin. Please contact admin to reapply or resolve any issues.');
        }
      }

      // Check if pharmacy is approved
      if (role.toString() == 'Pharmacy') {
        final isApproved = doc.data()?.containsKey('isApproved') == true
            ? doc['isApproved']
            : false;
        if (!isApproved) {
          debugPrint('Pharmacy login attempted but not approved: $uid');
          throw Exception(
              'Your pharmacy is pending approval. Please wait for admin approval.');
        }
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
          errorMessage =
              'This email address is not registered. Please check your email or create an account.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage =
              'This account has been disabled. Please contact support.';
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
