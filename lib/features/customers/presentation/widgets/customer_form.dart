import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amar_dokan/features/customers/data/models/customer_model.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Reusable Customer Form Widget
/// Add আর Edit দুটোতেই ব্যবহার হবে
class CustomerForm extends StatefulWidget {
  /// null = new customer mode, non-null = edit mode
  final CustomerModel? initialCustomer;
  final void Function(CustomerModel customer) onSubmit;
  final VoidCallback? onCancel;

  const CustomerForm({
    super.key,
    this.initialCustomer,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;
  String? _nameError;
  String? _phoneError;

  bool get isEditMode => widget.initialCustomer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCustomer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ============================================
  // Validation
  // ============================================

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name too short';
    if (value.trim().length > 50) return 'Name too long';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final emailRegex = RegExp(r'^[\w\.\-+]+@[\w\.\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  // ============================================
  // Form submission
  // ============================================

  void _handleSubmit() {
    if (_isSubmitting) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate
    final nameErr = _validateName(_nameController.text);
    final phoneErr = _validatePhone(_phoneController.text);
    final emailErr = _validateEmail(_emailController.text);

    if (nameErr != null || phoneErr != null || emailErr != null) {
      setState(() {
        _nameError = nameErr;
        _phoneError = phoneErr;
      });
      // Email error show করতে একটা SnackBar (কারণ email field এ errorText নেই)
      if (emailErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailErr),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _nameError = null;
      _phoneError = null;
      _isSubmitting = true;
    });

    final now = DateTime.now();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();

    final customer = CustomerModel(
      id: widget.initialCustomer?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: email.isEmpty ? null : email,
      address: address.isEmpty ? null : address,
      notes: notes.isEmpty ? null : notes,
      totalPurchases: widget.initialCustomer?.totalPurchases ?? 0,
      totalOrders: widget.initialCustomer?.totalOrders ?? 0,
      lastPurchaseDate: widget.initialCustomer?.lastPurchaseDate,
      isActive: widget.initialCustomer?.isActive ?? true,
      createdAt: widget.initialCustomer?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      widget.onSubmit(customer);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================
  // Build
  // ============================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Basic Information', Icons.person_outline),
          const SizedBox(height: 12),

          // Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              hintText: 'e.g., Karim Rahman',
              prefixIcon: const Icon(Icons.person_outlined),
              border: const OutlineInputBorder(),
              errorText: _nameError,
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Phone
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-\(\)\+]')),
            ],
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              hintText: 'e.g., +880 1711-123456',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: const OutlineInputBorder(),
              errorText: _phoneError,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          // Email (optional)
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (Optional)',
              hintText: 'e.g., example@mail.com',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Additional Details', Icons.location_on_outlined),
          const SizedBox(height: 12),

          // Address
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Address (Optional)',
              hintText: 'e.g., House 12, Road 5, Dhanmondi, Dhaka',
              prefixIcon: Icon(Icons.home_outlined),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 12),

          // Notes
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Any extra info about this customer...',
              prefixIcon: Icon(Icons.notes_outlined),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              if (widget.onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              if (widget.onCancel != null) const SizedBox(width: 12),
              Expanded(
                flex: widget.onCancel != null ? 1 : 2,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(isEditMode ? Icons.update : Icons.add),
                  label: Text(
                    _isSubmitting
                        ? 'Saving...'
                        : isEditMode
                            ? 'Update Customer'
                            : 'Add Customer',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
