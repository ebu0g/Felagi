import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a message from pharmacy to admin
  Future<void> sendMessageToAdmin({
    required String pharmacyId,
    required String pharmacyName,
    required String pharmacyEmail,
    required String message,
  }) async {
    try {
      await _firestore.collection('messages').add({
        'from': pharmacyName,
        'fromEmail': pharmacyEmail,
        'fromId': pharmacyId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      debugPrint('Message sent from $pharmacyName to admin');
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get all messages
  Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final snapshot = await _firestore
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'from': doc['from'],
          'fromEmail': doc['fromEmail'],
          'message': doc['message'],
          'timestamp': doc['timestamp'],
          'read': doc['read'] ?? false,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'read': true,
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }
}
