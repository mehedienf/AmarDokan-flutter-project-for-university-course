import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider id values used in [providerId].
class AuthProviderId {
  static const String email = 'password';
  static const String google = 'google.com';
}

/// Role assigned to a user — controls which screens are reachable.
///
/// Admin / Owner: full access. Staff: can only create sales.
class UserRole {
  static const String admin = 'admin';
  static const String staff = 'staff';

  /// Default role when none is recorded (legacy accounts, OAuth, etc.).
  static const String defaultRole = staff;

  static bool isAdmin(String? role) => role == admin;
  static bool isStaff(String? role) => role == staff;
}

/// UserModel - Firebase Auth user profile stored in Firestore `users` collection.
///
/// Holds profile fields surfaced from FirebaseAuth + extra metadata we
/// keep in Firestore. The `providerId` field remembers which auth
/// provider created the account (password or Google) for analytics.
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String providerId;
  final bool emailVerified;
  final String role;
  final DateTime? lastSignInAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.providerId,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.emailVerified = false,
    this.role = UserRole.defaultRole,
    this.lastSignInAt,
  });

  // ============================================
  // Getters
  // ============================================

  bool get hasDisplayName =>
      displayName != null && displayName!.trim().isNotEmpty;
  bool get hasPhoto => photoURL != null && photoURL!.isNotEmpty;
  bool get hasPhone => phoneNumber != null && phoneNumber!.trim().isNotEmpty;

  String get initials {
    final name = displayName?.trim() ?? email.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get effectiveName {
    if (hasDisplayName) return displayName!.trim();
    return email.split('@').first;
  }

  bool get isGoogleUser => providerId == AuthProviderId.google;
  bool get isEmailUser => providerId == AuthProviderId.email;

  bool get isAdmin => UserRole.isAdmin(role);
  bool get isStaff => UserRole.isStaff(role);

  // ============================================
  // Firestore serialization
  // ============================================

  factory UserModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      providerId: data['providerId'] ?? AuthProviderId.email,
      emailVerified: data['emailVerified'] ?? false,
      role: (data['role'] as String?) ?? UserRole.defaultRole,
      lastSignInAt: (data['lastSignInAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'providerId': providerId,
      'emailVerified': emailVerified,
      'role': role,
      'lastSignInAt': lastSignInAt == null
          ? null
          : Timestamp.fromDate(lastSignInAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================
  // Copy / Update
  // ============================================

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? providerId,
    bool? emailVerified,
    String? role,
    DateTime? lastSignInAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      providerId: providerId ?? this.providerId,
      emailVerified: emailVerified ?? this.emailVerified,
      role: role ?? this.role,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, provider: $providerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.providerId == providerId &&
        other.emailVerified == emailVerified;
  }

  @override
  int get hashCode =>
      Object.hash(uid, email, displayName, photoURL, providerId);
}
