import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:amar_dokan/features/auth/data/models/user_model.dart';
import 'package:amar_dokan/features/auth/data/services/auth_service.dart';

/// AuthProvider - High-level BDApps phone auth state for the app.
///
/// The session and all app data live on the device only.
class AuthProvider extends ChangeNotifier {
  final AuthService _service;

  AuthProvider({AuthService? service}) : _service = service ?? AuthService();

  // ============================================
  // State
  // ============================================

  UserModel? _profile;
  StreamSubscription<UserModel?>? _profileSub;

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _hasLocalSession = false;
  String? _errorMessage;

  // ============================================
  // Getters
  // ============================================

  UserModel? get profile => _profile;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _hasLocalSession && _service.currentPhone != null;
  String? get uid => _service.currentUid;
  String? get email => _service.currentPhone;
  String? get phoneNumber => _service.currentPhone;
  String? get displayName => _profile?.displayName;
  String? get photoURL => _profile?.photoURL;

  /// Role from the local profile. Defaults to staff if the profile
  /// hasn't loaded yet (safe for nav gating — staff can only see sales).
  String get role => _profile?.role ?? UserRole.defaultRole;
  bool get isAdmin => UserRole.isAdmin(role);
  bool get isStaff => UserRole.isStaff(role);

  // ============================================
  // Lifecycle
  // ============================================

  /// Restore the saved session. Call once from main().
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _service.loadPhoneSession();
    _hasLocalSession = _service.hasLocalSession;
    _watchProfile();
    _isInitialized = true;
    notifyListeners();
  }

  void _watchProfile() {
    _profileSub?.cancel();
    _profileSub = null;
    _profile = null;
    final id = _service.currentUid;
    if (id == null) return;
    _profileSub = _service.watchUserProfile(id).listen((p) {
      _profile = p;
      notifyListeners();
    });
  }

  @override
  void dispose() {
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

  Future<bool> signInWithBdApps({
    required String phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _service.completePhoneLogin(phone);
      _hasLocalSession = true;
      _watchProfile();
      _setLoading(false);
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
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
      _hasLocalSession = false;
      _profileSub?.cancel();
      _profileSub = null;
      _profile = null;
      _setLoading(false);
      notifyListeners();
      return true;
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
}
