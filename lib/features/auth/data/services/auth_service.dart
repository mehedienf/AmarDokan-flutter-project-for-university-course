import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amar_dokan/core/local/local_db.dart';
import 'package:amar_dokan/features/auth/data/models/user_model.dart';

/// AuthService - BDApps phone authentication with an on-device session.
///
/// BDApps verifies the phone number with OTP. All app data is stored locally
/// on the device, keyed by the verified phone number.
class AuthService {
  static const String bdAppsBaseUrl =
      'https://bdapps.flicksize.com/AmarDokan/';
  static const String phoneKey = 'bdapps_phone';
  static const String loggedInKey = 'bdapps_logged_in';

  final LocalDb _db;

  AuthService({LocalDb? db}) : _db = db ?? LocalDb.instance;

  String? get currentUid => LocalAuth.instance.currentUser?.uid;

  String? get currentPhone => _cachedPhone;

  SharedPreferences? _phonePrefs;
  String? _cachedPhone;
  bool _cachedLoggedIn = false;

  /// Local user id derived from the phone number.
  static String uidForPhone(String phone) => 'phone_$phone';

  Future<void> loadPhoneSession() async {
    _phonePrefs ??= await SharedPreferences.getInstance();
    _cachedPhone = _phonePrefs!.getString(phoneKey);
    _cachedLoggedIn = _phonePrefs!.getBool(loggedInKey) ?? false;
    if (hasLocalSession) {
      final uid = uidForPhone(_cachedPhone!);
      LocalAuth.instance.setUid(uid);
      await _ensureUserProfile(uid, _cachedPhone!);
    }
  }

  Future<void> _cachePhone(String phone) async {
    _phonePrefs ??= await SharedPreferences.getInstance();
    await _phonePrefs!.setString(phoneKey, phone);
    await _phonePrefs!.setBool(loggedInKey, true);
    _cachedPhone = phone;
    _cachedLoggedIn = true;
  }

  Future<void> clearPhone() async {
    _phonePrefs ??= await SharedPreferences.getInstance();
    await _phonePrefs!.remove(phoneKey);
    await _phonePrefs!.setBool(loggedInKey, false);
    _cachedPhone = null;
    _cachedLoggedIn = false;
  }

  bool get hasLocalSession =>
      _cachedLoggedIn && _cachedPhone != null && _cachedPhone!.isNotEmpty;

  /// True when BDApps reports REGISTERED or INITIAL CHARGING PENDING.
  Future<bool> isPhoneSubscribed(String phone) async {
    final response = await http
        .post(
          Uri.parse('${bdAppsBaseUrl}check_subscription.php'),
          body: {'user_mobile': phone},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return false;
    final status =
        data['subscriptionStatus']?.toString().trim().toUpperCase() ?? '';
    // INITIAL CHARGING PENDING = subscription exists, billing still ticking.
    return status == 'REGISTERED' || status == 'INITIAL CHARGING PENDING';
  }

  /// Polls [isPhoneSubscribed] until REGISTERED / INITIAL CHARGING PENDING.
  Future<bool> waitForSubscription(
    String phone, {
    int maxAttempts = 5,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(delay);
      try {
        if (await isPhoneSubscribed(phone)) return true;
      } catch (_) {}
    }
    return false;
  }

  Future<OtpRequest> requestPhoneOtp(String phone) async {
    final response = await http
        .post(
          Uri.parse('${bdAppsBaseUrl}send_otp.php'),
          body: {'user_mobile': phone},
        )
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const AuthException('Invalid response from BDApps server.');
    }
    return OtpRequest(
      success: data['success'] == true,
      referenceNo: data['referenceNo']?.toString().trim() ?? '',
      message: data['message']?.toString() ??
          data['statusDetail']?.toString() ??
          '',
      statusCode: data['statusCode']?.toString().trim() ?? '',
    );
  }

  Future<bool> verifyPhoneOtp({
    required String phone,
    required String otp,
    required String referenceNo,
  }) async {
    final response = await http
        .post(
          Uri.parse('${bdAppsBaseUrl}verify_otp.php'),
          body: {
            'Otp': otp,
            'otp': otp,
            'referenceNo': referenceNo,
            'reference_no': referenceNo,
            'user_mobile': phone,
          },
        )
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return false;
    final statusCode = (data['statusCode'] ??
            data['StatusCode'] ??
            data['status_code'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    final subStatus = (data['subscriptionStatus'] ??
            data['SubscriptionStatus'] ??
            data['subscription_status'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();
    final verified = statusCode == 'S1000' ||
        statusCode == 'E1351' ||
        subStatus == 'REGISTERED' ||
        subStatus == 'INITIAL CHARGING PENDING' ||
        data['success'] == true ||
        data['status']?.toString().trim().toLowerCase() == 'success' ||
        data['result']?.toString().trim().toLowerCase() == 'success';
    if (verified) return true;
    // Fallback: if BDApps already activated/queued the subscription, allow login.
    return await isPhoneSubscribed(phone);
  }

  /// Starts the local session for [phone] and creates its profile if needed.
  Future<void> completePhoneLogin(String phone) async {
    await _cachePhone(phone);
    final uid = uidForPhone(phone);
    LocalAuth.instance.setUid(uid);
    await _ensureUserProfile(uid, phone);
  }

  // ============================================
  // Sign out
  // ============================================

  Future<void> signOut() async {
    LocalAuth.instance.setUid(null);
    await clearPhone();
  }

  // ============================================
  // User profile (local)
  // ============================================

  DocumentReference _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> _ensureUserProfile(String uid, String phone) async {
    final ref = _userDoc(uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.update({
        'lastSignInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final now = DateTime.now();
    final profile = UserModel(
      uid: uid,
      email: '',
      phoneNumber: phone,
      providerId: AuthProviderId.phone,
      emailVerified: true,
      role: UserRole.admin,
      lastSignInAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(profile.toFirestore());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromFirestore(snap.data(), snap.id);
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _db.collection('users').snapshots().map((snap) {
      for (final doc in snap.docs) {
        if (doc.id == uid) return UserModel.fromFirestore(doc.data(), doc.id);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(UserModel profile) async {
    await _userDoc(profile.uid).update(profile.toFirestore());
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

class OtpRequest {
  final bool success;
  final String referenceNo;
  final String message;
  final String statusCode;

  const OtpRequest({
    required this.success,
    required this.referenceNo,
    required this.message,
    required this.statusCode,
  });
}
