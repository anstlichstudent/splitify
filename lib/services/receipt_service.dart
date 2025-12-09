import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceiptService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Simpan hasil OCR ke Firestore
  Future<String> saveReceipt({
    required Map<String, dynamic> receiptData,
    required String imagePath,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User harus login untuk menyimpan receipt');
    }

    final docRef = await _firestore.collection('receipts').add({
      'userId': currentUser.uid,
      'items': receiptData['items'] ?? [],
      'subtotal': receiptData['subtotal'] ?? 0,
      'tax': receiptData['tax'] ?? 0,
      'service_charge': receiptData['service_charge'] ?? 0,
      'discount': receiptData['discount'] ?? 0,
      'total': receiptData['total'] ?? 0,
      'restaurant_name': receiptData['restaurant_name'] ?? '',
      'date': receiptData['date'] ?? '',
      'imagePath': imagePath,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Receipt saved to Firestore with ID: ${docRef.id}');
    return docRef.id;
  }

  /// Ambil receipt dari Firestore by ID
  Future<Map<String, dynamic>?> getReceipt(String receiptId) async {
    final doc = await _firestore.collection('receipts').doc(receiptId).get();

    if (!doc.exists) {
      return null;
    }

    return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
  }

  /// Ambil semua receipts user
  Stream<List<Map<String, dynamic>>> getUserReceipts() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('receipts')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  /// Hapus receipt
  Future<void> deleteReceipt(String receiptId) async {
    await _firestore.collection('receipts').doc(receiptId).delete();
    print('🗑️ Receipt deleted: $receiptId');
  }
}
