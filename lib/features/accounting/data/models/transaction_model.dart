import 'package:cloud_firestore/cloud_firestore.dart';

/// TransactionType - Income vs Expense.
enum TransactionType {
  income,
  expense;

  String toJson() => name;

  static TransactionType fromJson(String? value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        return TransactionType.expense;
    }
  }

  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
    }
  }
}

/// TransactionCategory - Business-specific categories for income/expense.
enum TransactionCategory {
  // Income
  salesRevenue,
  otherIncome,
  capitalInjection,
  loanReceived,
  customerPayment,
  refundReceived,
  // Expense
  purchasePayment,
  rent,
  salary,
  utilities,
  transport,
  marketing,
  maintenance,
  tax,
  ownerWithdrawal,
  loanRepayment,
  supplierPayment,
  refundGiven,
  otherExpense;

  String toJson() => name;

  static TransactionCategory fromJson(String? value) {
    for (final c in TransactionCategory.values) {
      if (c.name == value) return c;
    }
    return TransactionCategory.otherExpense;
  }

  TransactionType get type {
    switch (this) {
      case TransactionCategory.salesRevenue:
      case TransactionCategory.otherIncome:
      case TransactionCategory.capitalInjection:
      case TransactionCategory.loanReceived:
      case TransactionCategory.customerPayment:
      case TransactionCategory.refundReceived:
        return TransactionType.income;
      case TransactionCategory.purchasePayment:
      case TransactionCategory.rent:
      case TransactionCategory.salary:
      case TransactionCategory.utilities:
      case TransactionCategory.transport:
      case TransactionCategory.marketing:
      case TransactionCategory.maintenance:
      case TransactionCategory.tax:
      case TransactionCategory.ownerWithdrawal:
      case TransactionCategory.loanRepayment:
      case TransactionCategory.supplierPayment:
      case TransactionCategory.refundGiven:
      case TransactionCategory.otherExpense:
        return TransactionType.expense;
    }
  }

  bool get isIncome => type == TransactionType.income;

  String get label {
    switch (this) {
      case TransactionCategory.salesRevenue:
        return 'Sales Revenue';
      case TransactionCategory.otherIncome:
        return 'Other Income';
      case TransactionCategory.capitalInjection:
        return 'Capital Injection';
      case TransactionCategory.loanReceived:
        return 'Loan Received';
      case TransactionCategory.customerPayment:
        return 'Customer Payment';
      case TransactionCategory.refundReceived:
        return 'Refund Received';
      case TransactionCategory.purchasePayment:
        return 'Purchase Payment';
      case TransactionCategory.rent:
        return 'Rent';
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.marketing:
        return 'Marketing';
      case TransactionCategory.maintenance:
        return 'Maintenance';
      case TransactionCategory.tax:
        return 'Tax';
      case TransactionCategory.ownerWithdrawal:
        return 'Owner Withdrawal';
      case TransactionCategory.loanRepayment:
        return 'Loan Repayment';
      case TransactionCategory.supplierPayment:
        return 'Supplier Payment';
      case TransactionCategory.refundGiven:
        return 'Refund Given';
      case TransactionCategory.otherExpense:
        return 'Other Expense';
    }
  }

  String get shortLabel {
    switch (this) {
      case TransactionCategory.salesRevenue:
        return 'Sales';
      case TransactionCategory.otherIncome:
        return 'Income';
      case TransactionCategory.capitalInjection:
        return 'Capital';
      case TransactionCategory.loanReceived:
        return 'Loan In';
      case TransactionCategory.customerPayment:
        return 'Cust. Pay';
      case TransactionCategory.refundReceived:
        return 'Refund In';
      case TransactionCategory.purchasePayment:
        return 'Purchase';
      case TransactionCategory.rent:
        return 'Rent';
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.marketing:
        return 'Marketing';
      case TransactionCategory.maintenance:
        return 'Maintenance';
      case TransactionCategory.tax:
        return 'Tax';
      case TransactionCategory.ownerWithdrawal:
        return 'Withdrawal';
      case TransactionCategory.loanRepayment:
        return 'Loan Out';
      case TransactionCategory.supplierPayment:
        return 'Supplier';
      case TransactionCategory.refundGiven:
        return 'Refund Out';
      case TransactionCategory.otherExpense:
        return 'Expense';
    }
  }

  String get iconName {
    switch (this) {
      case TransactionCategory.salesRevenue:
        return 'point_of_sale';
      case TransactionCategory.otherIncome:
        return 'savings';
      case TransactionCategory.capitalInjection:
        return 'account_balance';
      case TransactionCategory.loanReceived:
        return 'money';
      case TransactionCategory.customerPayment:
        return 'payments';
      case TransactionCategory.refundReceived:
        return 'undo';
      case TransactionCategory.purchasePayment:
        return 'shopping_bag';
      case TransactionCategory.rent:
        return 'home';
      case TransactionCategory.salary:
        return 'badge';
      case TransactionCategory.utilities:
        return 'bolt';
      case TransactionCategory.transport:
        return 'local_shipping';
      case TransactionCategory.marketing:
        return 'campaign';
      case TransactionCategory.maintenance:
        return 'build';
      case TransactionCategory.tax:
        return 'gavel';
      case TransactionCategory.ownerWithdrawal:
        return 'person';
      case TransactionCategory.loanRepayment:
        return 'money_off';
      case TransactionCategory.supplierPayment:
        return 'inventory';
      case TransactionCategory.refundGiven:
        return 'undo';
      case TransactionCategory.otherExpense:
        return 'receipt_long';
    }
  }

  static List<TransactionCategory> forType(TransactionType type) {
    return TransactionCategory.values
        .where((c) => c.type == type)
        .toList(growable: false);
  }
}

/// TransactionModel - represents a single income or expense entry.
class TransactionModel {
  final String id;
  final String referenceNumber;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final String paymentMethod;
  final String? referenceId;
  final String? referenceType;
  final String? partyId;
  final String? partyName;
  final String? description;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.referenceNumber,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.referenceId,
    this.referenceType,
    this.partyId,
    this.partyName,
    this.description,
    this.notes,
  });

  // ============================================
  // Getters
  // ============================================

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Signed amount: positive for income, negative for expense.
  double get signedAmount => isIncome ? amount : -amount;

  bool get hasReference =>
      referenceId != null && referenceId!.isNotEmpty;
  bool get hasParty => partyId != null && partyId!.isNotEmpty;
  bool get hasPartyName =>
      partyName != null && partyName!.isNotEmpty;
  bool get hasDescription =>
      description != null && description!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  String get displayPaymentMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'mobile':
      case 'mobile_banking':
      case 'bkash':
      case 'nagad':
        return 'Mobile Banking';
      case 'bank':
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cheque':
      case 'check':
        return 'Cheque';
      default:
        return paymentMethod;
    }
  }

  /// Short label for the linked reference (e.g. "SALE").
  String get referenceLabel {
    if (!hasReference) return '';
    switch (referenceType) {
      case 'sale':
        return 'SALE';
      case 'purchase':
        return 'PURCHASE';
      case 'customer':
        return 'CUSTOMER';
      case 'supplier':
        return 'SUPPLIER';
      default:
        return (referenceType ?? 'REF').toUpperCase();
    }
  }

  // ============================================
  // Firestore Serialization
  // ============================================

  factory TransactionModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return TransactionModel(
      id: documentId,
      referenceNumber: data['referenceNumber'] ?? '',
      type: TransactionType.fromJson(data['type'] as String?),
      category:
          TransactionCategory.fromJson(data['category'] as String?),
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      referenceId: data['referenceId'] as String?,
      referenceType: data['referenceType'] as String?,
      partyId: data['partyId'] as String?,
      partyName: data['partyName'] as String?,
      description: data['description'] as String?,
      notes: data['notes'] as String?,
      transactionDate:
          (data['transactionDate'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'referenceNumber': referenceNumber,
      'type': type.toJson(),
      'category': category.toJson(),
      'amount': amount,
      'paymentMethod': paymentMethod,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'partyId': partyId,
      'partyName': partyName,
      'description': description,
      'notes': notes,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ============================================
  // Copy & Equality
  // ============================================

  TransactionModel copyWith({
    String? id,
    String? referenceNumber,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    String? paymentMethod,
    String? referenceId,
    String? referenceType,
    String? partyId,
    String? partyName,
    String? description,
    String? notes,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, ref: $referenceNumber, '
        'type: ${type.name}, category: ${category.name}, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.referenceNumber == referenceNumber &&
        other.type == type &&
        other.category == category &&
        other.amount == amount &&
        other.paymentMethod == paymentMethod &&
        other.referenceId == referenceId &&
        other.referenceType == referenceType &&
        other.partyId == partyId &&
        other.partyName == partyName &&
        other.description == description &&
        other.notes == notes &&
        other.transactionDate == transactionDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      referenceNumber,
      type,
      category,
      amount,
      paymentMethod,
      referenceId,
      referenceType,
      partyId,
      partyName,
      description,
      notes,
      transactionDate,
      createdAt,
      // updatedAt omitted to stay within Object.hash's 20-arg limit
    );
  }
}
