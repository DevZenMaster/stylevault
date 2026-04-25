import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  bool isLockedOut(String email) {
    final until = _lockoutUntil[email.toLowerCase()];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _lockoutUntil.remove(email.toLowerCase());
      _failedAttempts.remove(email.toLowerCase());
      return false;
    }
    return true;
  }

  int lockoutSecondsRemaining(String email) {
    final until = _lockoutUntil[email.toLowerCase()];
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  int attemptsRemaining(String email) {
    final attempts = _failedAttempts[email.toLowerCase()] ?? 0;
    final remaining = _maxAttempts - attempts;
    return remaining > 0 ? remaining : 0;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (isLockedOut(key)) {
      throw Exception('Account temporarily locked. Please try again later.');
    }
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: key,
        password: password,
      );
      _failedAttempts.remove(key);
      _lockoutUntil.remove(key);
      return await getUserData(cred.user!.uid);
    } catch (e) {
      final attempts = (_failedAttempts[key] ?? 0) + 1;
      _failedAttempts[key] = attempts;
      if (attempts >= _maxAttempts) {
        _lockoutUntil[key] = DateTime.now().add(_lockoutDuration);
      }
      rethrow;
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    final user = UserModel(
      uid: cred.user!.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: 'user',
    );
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<UserModel> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    final firebaseUser = _auth.currentUser;
    return UserModel(
      uid: uid,
      name: firebaseUser?.displayName ?? '',
      email: firebaseUser?.email ?? '',
      role: 'user',
    );
  }

  /// Updates Firestore AND Firebase Auth profile (photoURL + displayName)
  Future<void> updateUserProfile(UserModel user) async {
    // 1. Update Firestore document
    await _firestore.collection('users').doc(user.uid).update(user.toMap());

    // 2. Sync Firebase Auth profile fields
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(user.name);
      // FIX: sync photoURL to Firebase Auth so it shows everywhere
      await _auth.currentUser!.updatePhotoURL(
        user.photoUrl.isNotEmpty ? user.photoUrl : null,
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> reauthenticate(String email, String password) async {
    final credential = EmailAuthProvider.credential(
        email: email, password: password);
    await _auth.currentUser?.reauthenticateWithCredential(credential);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
