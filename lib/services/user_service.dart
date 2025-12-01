import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 🔍 Cari user berdasarkan email (Menggunakan normalisasi email)
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    // Normalisasi email menjadi huruf kecil untuk pencarian yang konsisten
    final normalizedEmail = email.toLowerCase().trim();

    final result = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    final doc = result.docs.first;
    final data = doc.data();
    data['uid'] = doc.id; // tambahkan UID user
    return data;
  }

  // ➕ Tambahkan teman berdasarkan UID (Menambah pengecekan null safety)
  Future<void> addFriend(String friendUid) async {
    final currentUser = _auth.currentUser;

    // Pengecekan: Pastikan pengguna sedang login dan tidak mencoba menambah diri sendiri
    if (currentUser == null || currentUser.uid == friendUid) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'INVALID_FRIEND_ID',
        message:
            'User tidak terautentikasi atau mencoba menambah diri sendiri.',
      );
    }

    final currentUid = currentUser.uid;

    await _firestore.collection('users').doc(currentUid).update({
      // FieldValue.arrayUnion memastikan tidak ada duplikasi UID
      'friends': FieldValue.arrayUnion([friendUid]),
    });
  }

  // 👥 Ambil daftar teman user saat ini (Menambah pengecekan null safety)
  Future<List<String>> getFriends() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'UserService',
        code: 'NOT_AUTHENTICATED',
        message: 'User harus login untuk melihat daftar teman.',
      );
    }

    final uid = currentUser.uid;
    final snapshot = await _firestore.collection('users').doc(uid).get();

    final data = snapshot.data();
    // Menggunakan safe cast (List<String>.from)
    return List<String>.from(data?['friends'] ?? []);
  }
}
