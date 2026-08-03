import 'package:cloud_firestore/cloud_firestore.dart';

/// Supplier Model - Firestore এর সাথে কাজ করার জন্য design করা
///
/// এই model এর প্রতিটি field এর purpose:
/// - id: Firestore document ID
/// - name: Supplier এর contact person এর নাম
/// - companyName: Company / business এর নাম
/// - phone: Phone number (primary contact)
/// - email: Email address (optional)
/// - address: Address (optional)
/// - website: Company website (optional)
/// - notes: Supplier সম্পর্কে notes (optional)
/// - productsSupplied: কত ধরনের product এই supplier দেয়
/// - totalPurchases: এই supplier থেকে আমরা মোট কত টাকার কিনেছি
/// - lastPurchaseDate: শেষ কবে কিনেছি
/// - isActive: Supplier এখন active কিনা
/// - createdAt: কখন add হয়েছে
/// - updatedAt: কখন শেষ update হয়েছে
class SupplierModel {
  final String id;
  final String name;
  final String companyName;
  final String phone;
  final String? email;
  final String? address;
  final String? website;
  final String? notes;
  final int productsSupplied;
  final double totalPurchases;
  final DateTime? lastPurchaseDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.name,
    required this.companyName,
    required this.phone,
    required this.productsSupplied,
    required this.totalPurchases,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.address,
    this.website,
    this.notes,
    this.lastPurchaseDate,
  });

  // ============================================
  // Business Logic (Getters)
  // ============================================

  /// Email আছে কিনা
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Address আছে কিনা
  bool get hasAddress => address != null && address!.isNotEmpty;

  /// Website আছে কিনা
  bool get hasWebsite => website != null && website!.isNotEmpty;

  /// Notes আছে কিনা
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// এই supplier এর কাছ থেকে কি কখনো কেনা হয়েছে
  bool get hasSupplied => totalPurchases > 0;

  /// Contact person এর initials (e.g., "Karim Uddin" -> "KU")
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Company name এর first letter (avatar এর জন্য)
  String get companyInitial {
    if (companyName.trim().isEmpty) return '?';
    return companyName.trim()[0].toUpperCase();
  }

  /// Display name — company name থাকলে সেটা, না হলে contact name
  String get displayName =>
      companyName.trim().isNotEmpty ? companyName : name;

  // ============================================
  // Firestore Serialization
  // ============================================

  /// Firestore document থেকে SupplierModel বানাও
  factory SupplierModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SupplierModel(
      id: documentId,
      name: data['name'] ?? '',
      companyName: data['companyName'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] as String?,
      address: data['address'] as String?,
      website: data['website'] as String?,
      notes: data['notes'] as String?,
      productsSupplied: (data['productsSupplied'] ?? 0).toInt(),
      totalPurchases: (data['totalPurchases'] ?? 0).toDouble(),
      lastPurchaseDate: (data['lastPurchaseDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// SupplierModel কে Firestore document এ save করার জন্য Map এ convert
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'address': address,
      'website': website,
      'notes': notes,
      'productsSupplied': productsSupplied,
      'totalPurchases': totalPurchases,
      'lastPurchaseDate': lastPurchaseDate != null
          ? Timestamp.fromDate(lastPurchaseDate!)
          : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================
  // Copy & Update Methods
  // ============================================

  /// Supplier এর copy return করে, কিছু field change করে
  SupplierModel copyWith({
    String? id,
    String? name,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    String? website,
    String? notes,
    int? productsSupplied,
    double? totalPurchases,
    DateTime? lastPurchaseDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      productsSupplied: productsSupplied ?? this.productsSupplied,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================
  // Display Helpers
  // ============================================

  @override
  String toString() {
    return 'SupplierModel(id: $id, company: $companyName, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplierModel &&
        other.id == id &&
        other.name == name &&
        other.companyName == companyName &&
        other.phone == phone &&
        other.email == email &&
        other.address == address &&
        other.website == website &&
        other.notes == notes &&
        other.productsSupplied == productsSupplied &&
        other.totalPurchases == totalPurchases &&
        other.lastPurchaseDate == lastPurchaseDate &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      companyName,
      phone,
      email,
      address,
      website,
      notes,
      productsSupplied,
      totalPurchases,
      lastPurchaseDate,
      isActive,
      createdAt,
      updatedAt,
    );
  }
}
