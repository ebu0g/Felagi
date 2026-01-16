import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/colors.dart';

String _formatError(Object? e) {
  if (e == null) return 'Something went wrong.';

  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email and password do not match. Please try again.';
      case 'user-not-found':
        return 'We could not find an account with that email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in or resetting your password.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method. Use the original method (e.g., Google) to sign in.';
      case 'weak-password':
        return 'That password is too weak. Use at least 6 characters with letters and numbers.';
      case 'network-request-failed':
        return 'No internet connection. Please connect and try again.';
      default:
        return e.message ?? 'Sign-in failed. Please try again.';
    }
  }

  final s = e.toString();
  final normalized = s.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  final lower = normalized.toLowerCase();

  // Handle common auth keywords even if wrapped in a generic Exception
  if (lower.contains('wrong-password') ||
      lower.contains('invalid-credential')) {
    return 'Email and password do not match. Please try again.';
  }
  if (lower.contains('user-not-found')) {
    return 'We could not find an account with that email.';
  }
  if (lower.contains('user-disabled')) {
    return 'This account has been disabled. Please contact support.';
  }
  if (lower.contains('too-many-requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (lower.contains('invalid-email')) {
    return 'That email address looks invalid.';
  }
  if (lower.contains('email-already-in-use')) {
    return 'That email is already registered. Try logging in or resetting your password.';
  }
  if (lower.contains('network')) {
    return 'We could not reach the server. Please check your connection.';
  }

  // Fall back to the provided message if it looks user-friendly
  if (normalized.isNotEmpty) {
    return normalized;
  }

  return 'Something went wrong. Please try again.';
}

Future<void> showErrorDialog(BuildContext context,
    {String title = 'Error', required Object? error}) {
  final message = _formatError(error);
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade600,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    ),
  );
  return Future.value();
}

Future<void> showInfoDialog(
  BuildContext context, {
  String title = 'Info',
  required String message,
  Duration autoDismissDuration = const Duration(minutes: 2),
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var isClosed = false;
  Timer? timer;

  final duration = _clampDuration(
    autoDismissDuration,
    min: const Duration(minutes: 2),
    max: const Duration(minutes: 5),
  );

  if (duration > Duration.zero) {
    timer = Timer(duration, () {
      if (!isClosed && navigator.canPop()) {
        navigator.pop();
      }
    });
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
          child: const Text('OK'),
        )
      ],
    ),
  );

  isClosed = true;
  timer?.cancel();
}

Duration _clampDuration(Duration value,
    {required Duration min, required Duration max}) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
