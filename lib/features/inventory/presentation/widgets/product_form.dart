import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amar_dokan/features/inventory/data/models/product_model.dart';
import 'package:amar_dokan/features/inventory/data/models/product_category.dart';
import 'package:amar_dokan/features/inventory/data/models/product_helper.dart';
import 'package:amar_dokan/core/constants/app_colors.dart';

/// Reusable Product Form Widget
/// Add আর Edit দুটোতেই ব্যবহার হবে
class ProductForm extends StatefulWidget {
  /// null = new product mode, non-null = edit mode
  final ProductModel? initialProduct;
  final void Function(ProductModel product) onSubmit;
  final VoidCallback? onCancel;

  const ProductForm({
    super.key,
    this.initialProduct,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _descriptionController;

  // Dropdown state
  late ProductCategory _selectedCategory;

  bool _isSubmitting = false;
  String? _nameError;
  String? _skuError;

  bool get isEditMode => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;

    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _purchasePriceController =
        TextEditingController(text: p?.purchasePrice.toStringAsFixed(2) ?? '');
    _sellingPriceController =
        TextEditingController(text: p?.sellingPrice.toStringAsFixed(2) ?? '');
    _stockController =
        TextEditingController(text: p?.stock.toString() ?? '');
    _thresholdController =
        TextEditingController(text: p?.lowStockThreshold.toString() ?? '5');
    _descriptionController =
        TextEditingController(text: p?.description ?? '');
    _selectedCategory = p?.category ?? ProductCategory.other;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================
  // Form submission
  // ============================================

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    final nameValidation = ProductHelper.validateName(_nameController.text);
    final skuValidation = ProductHelper.validateSku(_skuController.text);

    if (nameValidation != null || skuValidation != null) {
      setState(() {
        _nameError = nameValidation;
        _skuError = skuValidation;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _skuError = null;
      _isSubmitting = true;
    });

    final purchasePrice =
        double.tryParse(_purchasePriceController.text.trim()) ?? 0;
    final sellingPrice =
        double.tryParse(_sellingPriceController.text.trim()) ?? 0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final threshold = int.tryParse(_thresholdController.text.trim()) ?? 5;

    final now = DateTime.now();
    final product = ProductModel(
      // Edit mode হলে আগের id, নাহলে empty (Firestore generate করবে)
      id: widget.initialProduct?.id ?? '',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim().toUpperCase(),
      category: _selectedCategory,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stock: stock,
      lowStockThreshold: threshold,
      description: _descriptionController.text.trim(),
      createdAt: widget.initialProduct?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      widget.onSubmit(product);
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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Basic Information', Icons.info_outline),
            const SizedBox(height: 12),

            // Product Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name *',
                hintText: 'e.g., Rice, Sugar, Mobile Phone',
                prefixIcon: const Icon(Icons.inventory_outlined),
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // SKU
            TextFormField(
              controller: _skuController,
              decoration: InputDecoration(
                labelText: 'SKU / Code *',
                hintText: 'e.g., RICE-001',
                prefixIcon: const Icon(Icons.qr_code_outlined),
                border: const OutlineInputBorder(),
                errorText: _skuError,
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<ProductCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: ProductCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Pricing', Icons.attach_money),
            const SizedBox(height: 12),

            // Purchase Price
            TextFormField(
              controller: _purchasePriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                hintText: '0.00',
                prefixText: '৳ ',
                prefixIcon: Icon(Icons.shopping_cart_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Selling Price
            TextFormField(
              controller: _sellingPriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Selling Price *',
                hintText: '0.00',
                prefixText: '৳ ',
                prefixIcon: Icon(Icons.sell_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Enter valid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Stock Information', Icons.inventory),
            const SizedBox(height: 12),

            // Stock
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Current Stock *',
                hintText: '0',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final stock = int.tryParse(value);
                if (stock == null || stock < 0) {
                  return 'Enter valid stock';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Low Stock Threshold
            TextFormField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Low Stock Alert Threshold',
                hintText: '5',
                prefixIcon: Icon(Icons.warning_amber_outlined),
                border: OutlineInputBorder(),
                helperText: 'Alert when stock falls below this number',
              ),
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Additional Details', Icons.description),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add any additional product details...',
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
                              ? 'Update Product'
                              : 'Add Product',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
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