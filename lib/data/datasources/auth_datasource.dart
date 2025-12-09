import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user.dart' as domain;

abstract class AuthDataSource {
  Future<domain.User> signInWithEmailAndPassword(String email, String password);
  Future<domain.User> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Future<domain.User> signInWithGoogle();
  Future<void> signOut();
  Stream<domain.User?> authStateChanges();
  domain.User? getCurrentUser();
}

class AuthDataSourceImpl implements AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthDataSourceImpl(this._firebaseAuth, this._firestore);

  @override
  Future<domain.User> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('User is null after sign in');

    return _mapFirebaseUserToEntity(user);
  }

  @override
  Future<domain.User> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('User is null after sign up');

    await user.updateDisplayName(displayName);

    // Create user document in Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'email': email.toLowerCase(),
      'name': displayName,
      'friends': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return _mapFirebaseUserToEntity(user, displayName: displayName);
  }

  @override
  Future<domain.User> signInWithGoogle() async {
    // This will be implemented with GoogleSignIn package
    throw UnimplementedError('Google sign-in will be handled in UI layer');
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Stream<domain.User?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return _mapFirebaseUserToEntity(user);
    });
  }

  @override
  domain.User? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUserToEntity(user);
  }

  domain.User _mapFirebaseUserToEntity(User user, {String? displayName}) {
    return domain.User(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName ?? '',
      photoUrl: user.photoURL,
    );
  }
}
