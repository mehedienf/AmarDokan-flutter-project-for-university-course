import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:amar_dokan/features/auth/data/models/user_model.dart';

/// AuthService - Firebase Authentication wrapper.
///
/// Handles email/password and Google Sign-In flows. After successful
/// authentication it ensures the user's profile document exists in
/// Firestore at `users/{uid}`.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: const ['email', 'profile']);

  // ============================================
  // Stream of Firebase Auth state
  // ============================================

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  // ============================================
  // Email + password
  // ============================================

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _updateLastSignIn(cred.user?.uid);
    return cred;
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    await _ensureUserProfile(cred.user);
    await _updateLastSignIn(cred.user?.uid);
    return cred;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ============================================
  // Email verification
  // ============================================

  /// Sends a verification email to the currently signed-in user.
  /// Caller must ensure [currentUser] is non-null (e.g. an email/password
  /// account that has just signed up or signed in).
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user.');
    }
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  /// Refreshes the cached [User] from Firebase so that
  /// `User.emailVerified` reflects the latest server state. Useful after
  /// the user has tapped the verification link in their inbox and
  /// returned to the app.
  Future<User?> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _auth.currentUser;
  }

  // ============================================
  // Google Sign-In
  // ============================================

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw const GoogleSignInCancelled();
    }

    final auth = await googleUser.authentication;
    final accessToken = auth.accessToken;
    final idToken = auth.idToken;

    if (accessToken == null && idToken == null) {
      throw const AuthException('Google sign-in failed: no tokens returned');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    await _ensureUserProfile(cred.user);
    await _updateLastSignIn(cred.user?.uid);
    return cred;
  }

  // ============================================
  // Sign out
  // ============================================

  Future<void> signOut() async {
    // Best-effort cleanup for Google — wrapped in timeouts so a stalled
    // network call can never block logout. Order matters: disconnect
    // locally, then sign out, then drop the Firebase session last so
    // the auth state change is the final signal.
    try {
      await _googleSignIn.disconnect().timeout(const Duration(seconds: 2));
    } catch (_) {
      // ignore — may not have been signed in via Google
    }
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {
      // ignore — best-effort cleanup
    }
    await _auth.signOut();
  }

  // ============================================
  // User profile (Firestore)
  // ============================================

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  /// Creates the profile doc if missing. Used after first sign-in.
  Future<void> _ensureUserProfile(User? user) async {
    if (user == null) return;
    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final now = DateTime.now();
    final profile = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      phoneNumber: user.phoneNumber,
      providerId: _detectProviderId(user),
      emailVerified: user.emailVerified,
      lastSignInAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(profile.toFirestore());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return UserModel.fromFirestore(data, snap.id);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UserModel.fromFirestore(data, snap.id);
    });
  }

  Future<void> updateUserProfile(UserModel profile) async {
    await _userDoc(profile.uid).update(profile.toFirestore());
  }

  Future<void> _updateLastSignIn(String? uid) async {
    if (uid == null) return;
    await _userDoc(uid).update({
      'lastSignInAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _detectProviderId(User user) {
    if (user.providerData.isEmpty) return AuthProviderId.email;
    // providerId is non-null in practice (Firebase populates it).
    return user.providerData.first.providerId;
  }
}

/// AuthException - thrown by AuthService for app-level errors.
class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}

/// GoogleSignInCancelled - thrown when user dismisses Google sign-in.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();

  @override
  String toString() => 'Google sign-in cancelled';
}
