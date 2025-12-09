
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk mengirim push notification via Firestore
/// Notifikasi akan disimpan di collection 'notifications' dan
/// trigger Cloud Function untuk kirim FCM
class PushNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kirim notifikasi untuk friend request
  Future<void> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'friend_request',
        'toUserId': toUserId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'title': 'Permintaan Pertemanan',
        'body': '$fromUserName ingin berteman dengan Anda',
        'data': {
          'requestId': '', // Will be filled by friend request ID
          'screen': 'notifications',
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending friend request notification: $e');
    }
  }

  /// Kirim notifikasi untuk activity invitation
  Future<void> sendActivityInvitationNotification({
    required String toUserId,
    required String activityId,
    required String activityName,
    required String inviterName,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'activity_invitation',
        'toUserId': toUserId,
        'activityId': activityId,
        'activityName': activityName,
        'inviterName': inviterName,
        'title': 'Undangan Aktivitas',
        'body': '$inviterName mengundang Anda ke "$activityName"',
        'data': {'activityId': activityId, 'screen': 'notifications'},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending activity invitation notification: $e');
    }
  }

  /// Kirim notifikasi untuk payment request
  Future<void> sendPaymentRequestNotification({
    required String toUserId,
    required String activityId,
    required String activityName,
    required String requesterName,
    required double amount,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'payment_request',
        'toUserId': toUserId,
        'activityId': activityId,
        'activityName': activityName,
        'requesterName': requesterName,
        'amount': amount,
        'title': 'Permintaan Pembayaran',
        'body':
            '$requesterName meminta pembayaran Rp ${amount.toStringAsFixed(0)} untuk "$activityName"',
        'data': {'activityId': activityId, 'screen': 'activity_detail'},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending payment request notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get all notifications for current user
  Stream<QuerySnapshot> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
