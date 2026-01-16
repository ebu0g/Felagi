import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // FirebaseStorage not used yet; remove unused field to avoid analyzer warnings.

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

      // Ensure phone number is unique (if provided) AFTER creating the auth user
      final String phoneTrim = phone.trim();
      if (phoneTrim.isNotEmpty) {
        final existing = await _firestore
            .collection('users')
            .where('phone', isEqualTo: phoneTrim)
            .get();
        if (existing.docs.isNotEmpty) {
          debugPrint('❌ Phone number already registered: $phoneTrim');
          // Clean up newly created auth user
          try {
            await _auth.currentUser!.delete();
            debugPrint('   ✅ Auth user deleted due to duplicate phone');
          } catch (deleteError) {
            debugPrint('   ⚠️  Failed to delete auth user: $deleteError');
          }
          throw Exception(
              'This phone number is already registered. Please use a different phone number.');
        }
      }

      // Send email verification
      try {
        await credential.user?.sendEmailVerification();
        debugPrint('✅ Verification email sent to $email');
      } catch (e) {
        debugPrint('⚠️ Failed to send verification email: $e');
      }

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

      // Enforce email verification
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        debugPrint('Login blocked - email not verified for: $email');
        throw Exception(
            'Please verify your email address before logging in. Check your inbox for the verification link.');
      }

      final uid = credential.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      final profileData = doc.data();

      if (!doc.exists || profileData == null) {
        debugPrint('User profile not found in Firestore for uid: $uid');
        throw Exception('User profile not found. Please register again.');
      }

      final role = profileData['role'];
      if (role == null || role.toString().isEmpty) {
        debugPrint('Role is null or empty for uid: $uid');
        throw Exception('User role not found in profile');
      }

      // Check if pharmacy is rejected
      if (role.toString() == 'Pharmacy') {
        final isRejected = profileData.containsKey('isRejected')
            ? profileData['isRejected'] == true
            : false;
        if (isRejected) {
          debugPrint('Pharmacy login attempted but rejected: $uid');
          await _createRejectionSupportTicket(uid, profileData);
          // Keep user signed in briefly so UI can attach appeal message, but sign out afterwards.
          throw Exception(
              '[REJECTED] Your pharmacy registration was rejected. We notified the admin to review your case.');
        }
      }

      // Check if pharmacy is approved
      if (role.toString() == 'Pharmacy') {
        final isApproved = profileData.containsKey('isApproved')
            ? profileData['isApproved'] == true
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
      rethrow;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  /// ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> _createRejectionSupportTicket(
      String uid, Map<String, dynamic> data) async {
    try {
      final name = (data['fullName'] ??
              data['full_name'] ??
              data['pharmacyName'] ??
              data['name'] ??
              '')
          .toString()
          .trim();

      await _firestore
          .collection('support_requests')
          .doc('rejection_$uid')
          .set({
        'type': 'pharmacy_rejection',
        'uid': uid,
        'email': (data['email'] ?? '').toString(),
        'name': name.isEmpty ? 'Unknown pharmacy' : name,
        'phone': (data['phone'] ?? '').toString(),
        'status': 'open',
        'message': 'Pharmacy cannot log in because status is rejected.',
        'appealMessage': FieldValue.delete(),
        'requestedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to create rejection support ticket: $e');
    }
  }

  /// Pharmacy appeal/update message to admin after rejected login
  Future<void> submitAppealMessage(String message) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not signed in. Please try logging in again.');
    }
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a message for the admin.');
    }
    try {
      // Fetch profile to ensure the support ticket always has basic contact info
      final profileSnap = await _firestore.collection('users').doc(uid).get();
      final data = profileSnap.data() ?? {};
      final name = (data['fullName'] ??
              data['full_name'] ??
              data['pharmacyName'] ??
              data['name'] ??
              '')
          .toString()
          .trim();
      final email = (data['email'] ?? '').toString();
      final phone = (data['phone'] ?? '').toString();

      await _firestore
          .collection('support_requests')
          .doc('rejection_$uid')
          .set({
        'type': 'pharmacy_rejection',
        'uid': uid,
        'email': email,
        'name': name.isEmpty ? 'Unknown pharmacy' : name,
        'phone': phone,
        'status': 'open',
        'message': 'Pharmacy submitted an appeal after rejection.',
        'appealMessage': trimmed,
        'requestedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to submit appeal message: $e');
      rethrow;
    } finally {
      // Sign out after submitting appeal
      try {
        await _auth.signOut();
      } catch (_) {}
    }
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

  /// ================= GOOGLE SIGN-IN =================
  /// Signs in using Google and ensures a Firestore profile exists.
  /// Returns the role string (e.g., 'Patient', 'Pharmacy', 'Admin').
  Future<String> signInWithGoogle({bool promptChooser = true}) async {
    try {
      final googleSignIn = GoogleSignIn();
      if (promptChooser) {
        try {
          await googleSignIn.signOut();
        } catch (_) {}
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in aborted.');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final uid = userCredential.user!.uid;
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // New user signed in with Google. Before defaulting to 'Patient',
        // check if there's an existing profile in Firestore with the same
        // email (e.g. created via email/password registration). If found,
        // reuse that role to avoid treating the user as a Patient.
        final email = userCredential.user?.email ?? '';
        if (email.isNotEmpty) {
          final existingQuery = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (existingQuery.docs.isNotEmpty) {
            final existingDoc = existingQuery.docs.first;
            final existing = existingDoc.data();
            final existingUid = existingDoc.id;
            final reusedRole = existing['role'] ?? 'Patient';
            final reusedIsApproved = existing['isApproved'] ?? true;

            final userData = {
              'uid': uid,
              'fullName': userCredential.user?.displayName ??
                  existing['fullName'] ??
                  '',
              'email': email,
              'phone':
                  userCredential.user?.phoneNumber ?? existing['phone'] ?? '',
              'address': existing['address'] ?? '',
              'role': reusedRole,
              'isApproved': reusedIsApproved,
              'createdAt': FieldValue.serverTimestamp(),
            };

            await docRef.set(userData);

            // Copy medicines from the existing profile to the new uid so the
            // Google-sign-in user sees their medicines immediately.
            try {
              final medsSnapshot = await _firestore
                  .collection('users')
                  .doc(existingUid)
                  .collection('medicines')
                  .get();

              for (final medDoc in medsSnapshot.docs) {
                await docRef
                    .collection('medicines')
                    .doc(medDoc.id)
                    .set(medDoc.data());
              }
            } catch (copyErr) {
              debugPrint(
                  '⚠️ Failed to copy medicines for migrated user: $copyErr');
            }

            debugPrint(
                'Reused existing profile role for email=$email -> $reusedRole (migrated from $existingUid)');
            return reusedRole.toString();
          }
        }

        // No existing profile found — default to 'Patient'. You may want to
        // prompt for role selection later for new Google users.
        final userData = {
          'uid': uid,
          'fullName': userCredential.user?.displayName ?? '',
          'email': userCredential.user?.email ?? '',
          'phone': userCredential.user?.phoneNumber ?? '',
          'address': '',
          'role': 'Patient',
          'isApproved': true,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await docRef.set(userData);
        return 'Patient';
      }

      final role = doc['role'];

      // Pharmacy checks (rejected/approved) - reuse logic from login
      if (role == 'Pharmacy') {
        final isRejected = doc.data()?.containsKey('isRejected') == true
            ? doc['isRejected']
            : false;
        if (isRejected) {
          throw Exception(
              'Your pharmacy registration was rejected by admin. Please contact admin.');
        }

        final isApproved = doc.data()?.containsKey('isApproved') == true
            ? doc['isApproved']
            : false;
        if (!isApproved) {
          throw Exception(
              'Your pharmacy is pending approval. Please wait for admin approval.');
        }
      }

      return role.toString();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException (Google): ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }
}
