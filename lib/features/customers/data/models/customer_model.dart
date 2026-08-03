import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer Model - Firestore এর সাথে কাজ করার জন্য design করা
///
/// এই model এর প্রতিটি field এর purpose:
/// - id: Firestore document ID
/// - name: Customer এর নাম
/// - phone: Phone number (primary contact)
/// - email: Email address (optional)
/// - address: Address (optional)
/// - notes: Customer সম্পর্কে additional notes (optional)
/// - totalPurchases: মোট কত টাকার product কিনেছে
/// - totalOrders: মোট কতবার order করেছে
/// - lastPurchaseDate: শেষ কবে কিনেছে
/// - isActive: Customer এখন active কিনা
/// - createdAt: কখন add হয়েছে
/// - updatedAt: কখন শেষ update হয়েছে
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? notes;
  final double totalPurchases;
  final int totalOrders;
  final DateTime? lastPurchaseDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalPurchases,
    required this.totalOrders,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.address,
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

  /// Notes আছে কিনা
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// এই customer কি কখনো কিনেছে
  bool get hasOrdered => totalOrders > 0;

  /// Customer কে display করার জন্য initials (e.g., "Mehedi Hasan" -> "MH")
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // ============================================
  // Firestore Serialization
  // ============================================

  /// Firestore document থেকে CustomerModel বানাও
  factory CustomerModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return CustomerModel(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] as String?,
      address: data['address'] as String?,
      notes: data['notes'] as String?,
      totalPurchases: (data['totalPurchases'] ?? 0).toDouble(),
      totalOrders: (data['totalOrders'] ?? 0).toInt(),
      lastPurchaseDate: (data['lastPurchaseDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// CustomerModel কে Firestore document এ save করার জন্য Map এ convert
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'totalPurchases': totalPurchases,
      'totalOrders': totalOrders,
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

  /// Customer এর copy return করে, কিছু field change করে
  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? totalPurchases,
    int? totalOrders,
    DateTime? lastPurchaseDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalOrders: totalOrders ?? this.totalOrders,
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
    return 'CustomerModel(id: $id, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.address == address &&
        other.notes == notes &&
        other.totalPurchases == totalPurchases &&
        other.totalOrders == totalOrders &&
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
      phone,
      email,
      address,
      notes,
      totalPurchases,
      totalOrders,
      lastPurchaseDate,
      isActive,
      createdAt,
      updatedAt,
    );
  }
}
