import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:amar_dokan/features/auth/data/models/user_model.dart';
import 'package:amar_dokan/features/auth/data/services/auth_service.dart';

/// AuthProvider - High-level auth state for the app.
///
/// Listens to FirebaseAuth's authStateChanges and exposes the
/// current user + loading/error state. UI uses this to decide
/// whether to show LoginScreen or MainApp.
class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthProvider({AuthService? service}) : _service = service ?? AuthService();

  // ============================================
  // State
  // ============================================

  User? _firebaseUser;
  UserModel? _profile;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================

  User? get firebaseUser => _firebaseUser;
  UserModel? get profile => _profile;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _firebaseUser != null;
  String? get uid => _firebaseUser?.uid;
  String? get email => _firebaseUser?.email;
  String? get displayName =>
      _firebaseUser?.displayName ?? _profile?.displayName;
  String? get photoURL => _firebaseUser?.photoURL ?? _profile?.photoURL;

  // ============================================
  // Lifecycle
  // ============================================

  /// Subscribe to the auth state stream. Call once from main().
  void initialize() {
    if (_authSub != null) return;
    _authSub = _service.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _firebaseUser = user;
    _errorMessage = null;
    _isInitialized = true;

    // Reset profile subscription when user changes.
    _profileSub?.cancel();
    _profileSub = null;
    _profile = null;

    if (user != null) {
      _profileSub = _service
          .watchUserProfile(user.uid)
          .listen(
            (p) {
              _profile = p;
              notifyListeners();
            },
            onError: (_) {
              // Firestore profile may be missing for brand-new accounts;
              // not fatal — ignore.
            },
          );
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  // ============================================
  // Actions
  // ============================================

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _runAuth(
      () => _service.signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _runAuth(
      () => _service.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<bool> signInWithGoogle() async {
    return _runAuth(() => _service.signInWithGoogle());
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _service.sendPasswordReset(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signOut() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _service.signOut();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ============================================
  // Helpers
  // ============================================

  Future<bool> _runAuth(Future<UserCredential> Function() action) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await action();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
      _setLoading(false);
      return false;
    } on GoogleSignInCancelled {
      // User cancelled — don't surface as error.
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. '
            'Enable it in Firebase Console → Authentication.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
