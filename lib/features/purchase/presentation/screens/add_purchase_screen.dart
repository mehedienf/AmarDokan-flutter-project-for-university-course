import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/providers/inventory_provider.dart';
import '../../../suppliers/data/models/supplier_model.dart';
import '../../../suppliers/providers/supplier_provider.dart';
import '../../data/models/purchase_item_model.dart';
import '../../data/models/purchase_model.dart';
import '../../providers/purchase_provider.dart';

/// AddPurchaseScreen - Record a new purchase.
///
/// On submit:
/// - New purchase is added to Firestore.
/// - For each item: product stock is incremented by `quantity`
///   and `purchasePrice` is refreshed to the entered unit cost.
/// - User is popped back with `true`.
class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final List<PurchaseItemModel> _cart = [];
  SupplierModel? _selectedSupplier;

  String _paymentMethod = 'cash';
  String _paymentStatus = 'paid';
  String _status = 'completed';

  final TextEditingController _supplierInvoiceController =
      TextEditingController();
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _extraDiscountController =
      TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  DateTime? _expectedDeliveryDate;

  String? _invoiceNumber;
  bool _isSubmitting = false;
  bool _isLoadingInvoice = true;

  @override
  void initState() {
    super.initState();
    _paidController.addListener(_onAnyChanged);
    _extraDiscountController.addListener(_onAnyChanged);
    _taxController.addListener(_onAnyChanged);
    _shippingController.addListener(_onAnyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvoiceNumber();
      // Make sure inventory + suppliers streams are alive
      context.read<InventoryProvider>().startListening();
      context.read<SupplierProvider>().startListening();
    });
  }

  @override
  void dispose() {
    _supplierInvoiceController.dispose();
    _paidController.dispose();
    _extraDiscountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ============================================
  // Helpers
  // ============================================

  void _onAnyChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInvoiceNumber() async {
    final provider = context.read<PurchaseProvider>();
    final num = await provider.generateNextInvoiceNumber();
    if (!mounted) return;
    setState(() {
      _invoiceNumber = num;
      _isLoadingInvoice = false;
    });
  }

  double get _subtotal =>
      _cart.fold(0.0, (acc, item) => acc + item.subtotal);

  double get _itemDiscount =>
      _cart.fold(0.0, (acc, item) => acc + item.discount);

  double get _extraDiscount =>
      double.tryParse(_extraDiscountController.text.trim()) ?? 0.0;

  double get _tax => double.tryParse(_taxController.text.trim()) ?? 0.0;

  double get _shipping =>
      double.tryParse(_shippingController.text.trim()) ?? 0.0;

  double get _total {
    final v = _subtotal - _itemDiscount - _extraDiscount + _tax + _shipping;
    return v < 0 ? 0 : v;
  }

  double get _paid =>
      double.tryParse(_paidController.text.trim()) ?? 0.0;

  double get _due {
    final v = _total - _paid;
    return v < 0 ? 0 : v;
  }

  void _addToCart(ProductModel product) {
    final existing = _cart.indexWhere((i) => i.productId == product.id);
    if (existing >= 0) {
      final cur = _cart[existing];
      setState(() {
        _cart[existing] = cur.copyWith(quantity: cur.quantity + 1);
      });
    } else {
      setState(() {
        _cart.add(
          PurchaseItemModel(
            productId: product.id,
            productName: product.name,
            sku: product.sku,
            quantity: 1,
            unitPrice: product.purchasePrice,
            unitSellingPrice: product.sellingPrice,
          ),
        );
      });
    }
  }

  void _updateQuantity(int index, int qty) {
    if (qty < 1) {
      _removeItem(index);
      return;
    }
    setState(() {
      _cart[index] = _cart[index].copyWith(quantity: qty);
    });
  }

  void _updateItemPrice(int index, double price) {
    setState(() {
      _cart[index] = _cart[index].copyWith(unitPrice: price);
    });
  }

  void _updateItemSellingPrice(int index, double price) {
    setState(() {
      _cart[index] = _cart[index].copyWith(unitSellingPrice: price);
    });
  }

  void _updateItemDiscount(int index, double discount) {
    setState(() {
      _cart[index] = _cart[index].copyWith(discount: discount);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickSupplier() async {
    final suppliers = context.read<SupplierProvider>().suppliers;
    final picked = await showModalBottomSheet<SupplierModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) =>
          _SupplierPickerSheet(suppliers: suppliers),
    );
    if (picked != null) {
      setState(() => _selectedSupplier = picked);
    }
  }

  Future<void> _openProductPicker() async {
    final products = context.read<InventoryProvider>().products;
    final picked = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ProductPickerSheet(products: products),
    );
    if (picked != null) {
      _addToCart(picked);
    }
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _pickExpectedDelivery() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDeliveryDate ??
          _purchaseDate.add(const Duration(days: 3)),
      firstDate: _purchaseDate,
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _expectedDeliveryDate = picked);
  }

  Future<bool> _confirmSubmit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text(
          'Save purchase ${_invoiceNumber ?? ''} for BDT ${_total.toStringAsFixed(2)}?\n'
          'Stock for ${_cart.length} product${_cart.length == 1 ? '' : 's'} will be incremented.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    final provider = context.read<PurchaseProvider>();
    if (_cart.isEmpty) {
      _showSnack('Add at least one product', AppColors.error);
      return;
    }
    if (!await _confirmSubmit()) return;

    setState(() => _isSubmitting = true);
    final now = DateTime.now();
    final purchase = PurchaseModel(
      id: '',
      invoiceNumber: _invoiceNumber ?? 'PUR-${now.millisecondsSinceEpoch}',
      supplierId: _selectedSupplier?.id,
      supplierName: _selectedSupplier?.displayName,
      supplierInvoice:
          _supplierInvoiceController.text.trim().isEmpty
              ? null
              : _supplierInvoiceController.text.trim(),
      items: List.unmodifiable(_cart),
      subtotal: _subtotal,
      itemDiscount: _itemDiscount,
      extraDiscount: _extraDiscount,
      tax: _tax,
      shippingCost: _shipping,
      total: _total,
      paymentMethod: _paymentMethod,
      paymentStatus: _paymentStatus,
      paidAmount: _paid,
      dueAmount: _due,
      status: _status,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      purchaseDate: _purchaseDate,
      expectedDeliveryDate: _expectedDeliveryDate,
      createdAt: now,
      updatedAt: now,
    );

    final ok = await provider.addPurchase(purchase);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _showSnack('Purchase saved — stock updated', AppColors.success);
      Navigator.of(context).pop(true);
    } else {
      _showSnack(
        provider.errorMessage ?? 'Failed to save',
        AppColors.error,
      );
    }
  }

  // ============================================
  // Build
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoadingInvoice
            ? const Text('New Purchase')
            : Text(_invoiceNumber ?? 'New Purchase'),
        actions: [
          IconButton(
            tooltip: 'Clear cart',
            onPressed: _cart.isEmpty ? null : _clearCart,
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSupplierAndMeta(),
              const SizedBox(height: 16),
              _buildCart(),
              const SizedBox(height: 16),
              _buildTotalsAndPayment(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openProductPicker,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Add Product'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isSubmitting || _cart.isEmpty ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save Purchase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierAndMeta() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supplier',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickSupplier,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedSupplier != null
                          ? Icons.local_shipping_outlined
                          : Icons.person_outline,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedSupplier?.displayName ?? 'Choose supplier (optional)',
                        style: TextStyle(
                          color: _selectedSupplier != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: _selectedSupplier != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _supplierInvoiceController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Invoice #',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    label: 'Purchase Date',
                    date: _purchaseDate,
                    onTap: _pickPurchaseDate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateTile(
                    label: 'Expected Delivery',
                    date: _expectedDeliveryDate,
                    onTap: _pickExpectedDelivery,
                    onClear:
                        _expectedDeliveryDate == null ? null : _clearDelivery,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearDelivery() {
    setState(() => _expectedDeliveryDate = null);
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    date == null
                        ? '—'
                        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_cart.length} item${_cart.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_cart.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const Column(
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No items added yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap "Add Product" below to begin',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cart.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (ctx, i) =>
                    _buildCartItem(i, _cart[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(int index, PurchaseItemModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (item.sku != null && item.sku!.isNotEmpty)
                    Text(
                      'SKU: ${item.sku}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeItem(index),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildQtyStepper(index, item.quantity),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPriceField(
                label: 'Cost',
                initial: item.unitPrice,
                onChanged: (v) => _updateItemPrice(index, v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPriceField(
                label: 'Sell',
                initial: item.unitSellingPrice,
                onChanged: (v) => _updateItemSellingPrice(index, v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildPriceField(
                label: 'Item Discount',
                initial: item.discount,
                onChanged: (v) => _updateItemDiscount(index, v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Line Total',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'BDT ${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQtyStepper(int index, int qty) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _updateQuantity(index, qty - 1),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.remove, size: 16),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              '$qty',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: () => _updateQuantity(index, qty + 1),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField({
    required String label,
    required double initial,
    required ValueChanged<double> onChanged,
  }) {
    final controller = TextEditingController(
      text: initial == 0 ? '' : initial.toStringAsFixed(2),
    );
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 13),
      onChanged: (v) {
        final d = double.tryParse(v) ?? 0;
        onChanged(d);
      },
    );
  }

  Widget _buildTotalsAndPayment() {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _summaryRow('Subtotal', _subtotal),
            if (_itemDiscount > 0)
              _summaryRow('Item Discount', -_itemDiscount, color: AppColors.error),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _extraDiscountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Extra Discount',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _taxController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tax',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _shippingController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Shipping',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _summaryRow('Total', _total, bold: true, fontSize: 16),
            const Divider(height: 24),
            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodRow(),
            const SizedBox(height: 8),
            _buildPaymentStatusRow(),
            const SizedBox(height: 8),
            _buildStatusRow(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paidController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Paid (BDT)',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      errorText: _due > 0 && _paid <= 0
                          ? 'Set amount or status = Unpaid'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _due > 0
                          ? AppColors.error.withValues(alpha: 0.08)
                          : AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Due',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'BDT ${_due.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _due > 0
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    bool bold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            'BDT ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow() {
    final methods = const [
      ['cash', 'Cash'],
      ['bank', 'Bank'],
      ['mobile', 'Mobile'],
      ['cheque', 'Cheque'],
      ['credit', 'Credit'],
    ];
    return Wrap(
      spacing: 8,
      children: methods.map((m) {
        final selected = _paymentMethod == m[0];
        return ChoiceChip(
          label: Text(m[1]),
          selected: selected,
          onSelected: (_) => setState(() => _paymentMethod = m[0]),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentStatusRow() {
    final statuses = const [
      ['paid', 'Paid'],
      ['partial', 'Partial'],
      ['unpaid', 'Unpaid'],
    ];
    return Wrap(
      spacing: 8,
      children: statuses.map((s) {
        final selected = _paymentStatus == s[0];
        return ChoiceChip(
          label: Text(s[1]),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _paymentStatus = s[0];
              if (s[0] == 'paid' && _paid == 0 && _total > 0) {
                _paidController.text = _total.toStringAsFixed(2);
              } else if (s[0] == 'unpaid') {
                _paidController.text = '0';
              }
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusRow() {
    final statuses = const [
      ['completed', 'Completed'],
      ['pending', 'Pending'],
      ['cancelled', 'Cancelled'],
    ];
    return Wrap(
      spacing: 8,
      children: statuses.map((s) {
        final selected = _status == s[0];
        return ChoiceChip(
          label: Text(s[1]),
          selected: selected,
          onSelected: (_) => setState(() => _status = s[0]),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }
}

class _SupplierPickerSheet extends StatefulWidget {
  final List<SupplierModel> suppliers;
  const _SupplierPickerSheet({required this.suppliers});

  @override
  State<_SupplierPickerSheet> createState() => _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends State<_SupplierPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final filtered = widget.suppliers
        .where((s) =>
            s.displayName.toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Choose Supplier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Search suppliers...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No suppliers found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final s = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              s.companyInitial,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(s.displayName),
                          subtitle: Text(
                            s.phone.isNotEmpty ? s.phone : s.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => Navigator.pop(ctx, s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final List<ProductModel> products;
  const _ProductPickerSheet({required this.products});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final filtered = widget.products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Choose Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.isInStock
                                ? AppColors.primary
                                : AppColors.error,
                            child: Text(
                              p.name.isNotEmpty
                                  ? p.name.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            'Stock: ${p.stock} • Cost: BDT ${p.purchasePrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => Navigator.pop(ctx, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}