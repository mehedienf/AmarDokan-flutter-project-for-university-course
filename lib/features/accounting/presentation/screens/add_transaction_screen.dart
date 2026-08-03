import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/customers/data/models/customer_model.dart';
import 'package:amar_dokan/features/customers/providers/customer_provider.dart';
import 'package:amar_dokan/features/suppliers/data/models/supplier_model.dart';
import 'package:amar_dokan/features/suppliers/providers/supplier_provider.dart';
import 'package:amar_dokan/features/accounting/data/models/transaction_model.dart';
import 'package:amar_dokan/features/accounting/providers/transaction_provider.dart';

/// AddTransactionScreen - Record a new income or expense entry.
///
/// Lets the user pick type (income/expense), category, amount,
/// payment method, party (optional customer or supplier),
/// date, description and notes. On submit a TransactionModel is
/// generated and added through TransactionProvider.
class AddTransactionScreen extends StatefulWidget {
  /// Optional pre-selected type (defaults to income).
  final TransactionType initialType;

  /// Optional party id/name carried in if launched from a record.
  final String? initialPartyId;
  final String? initialPartyName;
  final String? initialPartyType; // 'customer' or 'supplier' (informational)

  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.income,
    this.initialPartyId,
    this.initialPartyName,
    this.initialPartyType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Form state
  TransactionType _type = TransactionType.income;
  TransactionCategory _category = TransactionCategory.salesRevenue;
  String _paymentMethod = 'cash';
  String? _partyId;
  String? _partyName;
  String? _partyType; // 'customer' | 'supplier' | null
  DateTime _transactionDate = DateTime.now();
  bool _isSubmitting = false;
  String? _referenceNumber;

  // Payment method options
  static const List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash'},
    {'value': 'mobile', 'label': 'Mobile Banking'},
    {'value': 'bank', 'label': 'Bank Transfer'},
    {'value': 'card', 'label': 'Card'},
    {'value': 'cheque', 'label': 'Cheque'},
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _partyId = widget.initialPartyId;
    _partyName = widget.initialPartyName;
    _partyType = widget.initialPartyType;
    _syncCategoryToType();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReferenceNumber();
      context.read<CustomerProvider>().startListening();
      context.read<SupplierProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncCategoryToType() {
    // Pick first category that matches current type
    final cats = TransactionCategory.forType(_type);
    if (cats.isEmpty) return;
    if (cats.contains(_category)) return;
    _category = cats.first;
  }

  Future<void> _loadReferenceNumber() async {
    try {
      final provider = context.read<TransactionProvider>();
      final ref = await provider.generateNextReferenceNumber();
      if (!mounted) return;
      setState(() => _referenceNumber = ref);
    } catch (_) {
      // ignore — fallback displayed in UI
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _pickParty() async {
    final isIncome = _type == TransactionType.income;
    // Reset stale party if it doesn't match the current type.
    final expectedType = isIncome ? 'customer' : 'supplier';
    if (_partyType != null && _partyType != expectedType) {
      _partyId = null;
      _partyName = null;
    }
    final result = isIncome
        ? await _pickFromList<CustomerModel>(
            title: 'Select Customer',
            provider: context.read<CustomerProvider>(),
            labelOf: (c) => c.name,
          )
        : await _pickFromList<SupplierModel>(
            title: 'Select Supplier',
            provider: context.read<SupplierProvider>(),
            labelOf: (s) => s.name,
          );

    if (result == null) return;
    setState(() {
      _partyId = result.id;
      _partyName = result.label;
      _partyType = isIncome ? 'customer' : 'supplier';
    });
  }

  Future<_PartyChoice?> _pickFromList<T>({
    required String title,
    required Listenable provider,
    required String Function(T) labelOf,
  }) async {
    // Use Consumer indirectly via showModalBottomSheet
    return showModalBottomSheet<_PartyChoice>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            final list = _readPartyList<T>(ctx, provider);
            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No records found. Add a record first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final item = list[i];
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(item.label),
                                onTap: () => Navigator.pop(ctx, item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_PartyChoice> _readPartyList<T>(BuildContext ctx, Listenable _) {
    if (T == CustomerModel) {
      final customers = ctx.watch<CustomerProvider>().customers;
      return customers
          .map((c) => _PartyChoice(id: c.id, label: c.name))
          .toList();
    } else {
      final suppliers = ctx.watch<SupplierProvider>().suppliers;
      return suppliers
          .map((s) => _PartyChoice(id: s.id, label: s.name))
          .toList();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('Please enter a valid amount', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: '',
        referenceNumber: _referenceNumber ?? 'TX-${now.millisecondsSinceEpoch}',
        type: _type,
        category: _category,
        amount: amount,
        paymentMethod: _paymentMethod,
        partyId: _partyId,
        partyName: _partyName,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        transactionDate: _transactionDate,
        createdAt: now,
        updatedAt: now,
      );

      final provider = context.read<TransactionProvider>();
      await provider.addTransaction(tx);
      if (!mounted) return;
      _showSnack('Transaction added successfully');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to add transaction: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ============================================
  // Build
  // ============================================

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TransactionType.income;
    final categories = TransactionCategory.forType(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Add Income' : 'Add Expense'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_referenceNumber != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _referenceNumber!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _typeSelector(),
            const SizedBox(height: 16),
            _sectionLabel('Category'),
            _categoryDropdown(categories),
            const SizedBox(height: 16),
            _sectionLabel('Amount'),
            _amountField(),
            const SizedBox(height: 16),
            _sectionLabel('Payment Method'),
            _paymentMethodSelector(),
            const SizedBox(height: 16),
            _sectionLabel(
              isIncome ? 'Customer (Optional)' : 'Supplier (Optional)',
            ),
            _partyField(isIncome),
            const SizedBox(height: 16),
            _sectionLabel('Transaction Date'),
            _dateField(),
            const SizedBox(height: 16),
            _sectionLabel('Description (Optional)'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Monthly sales from Main Branch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Notes (Optional)'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Internal notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isIncome ? Icons.add_circle : Icons.remove_circle),
              label: Text(
                _isSubmitting
                    ? 'Saving...'
                    : (isIncome ? 'Record Income' : 'Record Expense'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isIncome ? AppColors.success : AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================
  // Field widgets
  // ============================================

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _typeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeChip(
            label: 'Income',
            icon: Icons.trending_up,
            isSelected: _type == TransactionType.income,
            color: AppColors.success,
            onTap: () {
              if (_type == TransactionType.income) return;
              setState(() {
                _type = TransactionType.income;
                _syncCategoryToType();
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _typeChip(
            label: 'Expense',
            icon: Icons.trending_down,
            isSelected: _type == TransactionType.expense,
            color: AppColors.error,
            onTap: () {
              if (_type == TransactionType.expense) return;
              setState(() {
                _type = TransactionType.expense;
                _syncCategoryToType();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.12) : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown(List<TransactionCategory> categories) {
    return DropdownButtonFormField<TransactionCategory>(
      initialValue: _category,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: categories
          .map(
            (c) => DropdownMenuItem<TransactionCategory>(
              value: c,
              child: Text(c.label),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _category = v);
      },
    );
  }

  Widget _amountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        prefixText: '৳  ',
        prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        hintText: '0.00',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Amount is required';
        final parsed = double.tryParse(v.trim());
        if (parsed == null || parsed <= 0) return 'Enter a valid amount';
        return null;
      },
    );
  }

  Widget _paymentMethodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _paymentMethods.map((m) {
        final isSelected = _paymentMethod == m['value'];
        return ChoiceChip(
          label: Text(m['label']!),
          selected: isSelected,
          onSelected: (_) => setState(() => _paymentMethod = m['value']!),
        );
      }).toList(),
    );
  }

  Widget _partyField(bool isIncome) {
    return InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        suffixIcon: _partyId != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                  _partyId = null;
                  _partyName = null;
                  _partyType = null;
                }),
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      child: InkWell(
        onTap: _pickParty,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                isIncome ? Icons.person : Icons.local_shipping,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _partyName ??
                      'Tap to select ${isIncome ? 'customer' : 'supplier'}',
                  style: TextStyle(
                    color: _partyName != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    return InputDecorator(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today, size: 18),
      ),
      child: InkWell(
        onTap: _pickDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${_transactionDate.year}-${_transactionDate.month.toString().padLeft(2, '0')}-${_transactionDate.day.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _PartyChoice {
  final String id;
  final String label;
  _PartyChoice({required this.id, required this.label});
}
