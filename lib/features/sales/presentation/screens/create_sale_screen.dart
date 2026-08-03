import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/providers/customer_provider.dart';
import '../../../inventory/data/models/product_model.dart';
import '../../../inventory/providers/inventory_provider.dart';
import '../../data/models/sale_item_model.dart';
import '../../data/models/sale_model.dart';
import '../../providers/sale_provider.dart';
import '../widgets/sale_item_card.dart';
import '../widgets/sale_summary.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final List<SaleItemModel> _cart = [];
  CustomerModel? _selectedCustomer;
  String _paymentMethod = 'cash';
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _extraDiscountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _invoiceNumber;
  bool _isSubmitting = false;
  bool _isLoadingInvoice = true;

  @override
  void initState() {
    super.initState();
    _paidController.addListener(_onPaidChanged);
    _extraDiscountController.addListener(_recalc);
    _taxController.addListener(_recalc);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInvoiceNumber());
  }

  @override
  void dispose() {
    _paidController.dispose();
    _extraDiscountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceNumber() async {
    final provider = context.read<SaleProvider>();
    final num = await provider.generateNextInvoiceNumber();
    if (!mounted) return;
    setState(() {
      _invoiceNumber = num;
      _isLoadingInvoice = false;
    });
  }

  void _recalc() {
    if (mounted) setState(() {});
  }

  void _onPaidChanged() {
    if (mounted) setState(() {});
  }

  double get _subtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);

  double get _itemDiscount =>
      _cart.fold(0.0, (sum, item) => sum + item.discount);

  double get _extraDiscount => double.tryParse(_extraDiscountController.text) ?? 0.0;

  double get _tax => double.tryParse(_taxController.text) ?? 0.0;

  double get _total {
    final raw = _subtotal - _itemDiscount - _extraDiscount + _tax;
    return raw < 0 ? 0.0 : raw;
  }

  double get _paidAmount {
    final value = double.tryParse(_paidController.text) ?? 0.0;
    if (value < 0) return 0.0;
    if (value > _total) return _total;
    return value;
  }

  double get _changeAmount {
    final value = double.tryParse(_paidController.text) ?? 0.0;
    return value > _total ? value - _total : 0.0;
  }

  String get _paymentStatus {
    if (_total <= 0) return 'unpaid';
    if (_paidAmount >= _total) return 'paid';
    if (_paidAmount > 0) return 'partial';
    return 'unpaid';
  }

  void _addToCart(ProductModel product) {
    if (product.stock <= 0) {
      _showSnack('${product.name} is out of stock', AppColors.error);
      return;
    }
    final idx = _cart.indexWhere((i) => i.productId == product.id);
    setState(() {
      if (idx >= 0) {
        final existing = _cart[idx];
        if (existing.quantity >= product.stock) {
          _showSnack('Only ${product.stock} in stock', AppColors.warning);
          return;
        }
        _cart[idx] = existing.copyWith(quantity: existing.quantity + 1);
      } else {
        _cart.add(SaleItemModel(
          productId: product.id,
          productName: product.name,
          sku: product.sku.isEmpty ? null : product.sku,
          quantity: 1,
          unitPrice: product.sellingPrice,
          unitCost: product.purchasePrice,
          discount: 0.0,
        ));
      }
    });
  }

  void _updateQuantity(int index, int qty) {
    if (index < 0 || index >= _cart.length) return;
    if (qty <= 0) {
      _removeItem(index);
      return;
    }
    final product = _productInCart(_cart[index].productId);
    if (product != null && qty > product.stock) {
      _showSnack('Only ${product.stock} in stock', AppColors.warning);
      return;
    }
    setState(() {
      _cart[index] = _cart[index].copyWith(quantity: qty);
    });
  }

  void _updateItemDiscount(int index, double discount) {
    if (index < 0 || index >= _cart.length) return;
    final item = _cart[index];
    final maxDiscount = item.subtotal;
    final clamped = discount < 0
        ? 0.0
        : discount > maxDiscount
            ? maxDiscount
            : discount;
    setState(() {
      _cart[index] = item.copyWith(discount: clamped);
    });
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _cart.length) return;
    setState(() => _cart.removeAt(index));
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _extraDiscountController.clear();
      _taxController.clear();
      _paidController.clear();
      _selectedCustomer = null;
      _paymentMethod = 'cash';
      _notesController.clear();
    });
  }

  ProductModel? _productInCart(String productId) {
    try {
      return context
          .read<InventoryProvider>()
          .products
          .firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
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

  Future<void> _pickCustomer() async {
    final customers = context.read<CustomerProvider>().customers;
    final selected = await showModalBottomSheet<CustomerModel?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CustomerPickerSheet(customers: customers),
    );
    if (!mounted) return;
    setState(() {
      _selectedCustomer = selected;
    });
  }

  Future<void> _openProductPicker() async {
    final products = context.read<InventoryProvider>().products;
    final result = await showModalBottomSheet<ProductModel?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ProductPickerSheet(products: products),
    );
    if (result != null) _addToCart(result);
  }

  Future<bool> _confirmSubmit() async {
    if (_cart.isEmpty) return false;
    if (_paymentStatus == 'unpaid' && _paymentMethod == 'cash') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unpaid Cash Sale?'),
          content: const Text(
            'Customer paid nothing but you chose cash. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      return ok ?? false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) {
      _showSnack('Cart is empty', AppColors.error);
      return;
    }
    if (_isSubmitting) return;
    final confirmed = await _confirmSubmit();
    if (!confirmed || !mounted) return;
    setState(() => _isSubmitting = true);
    final now = DateTime.now();
    final sale = SaleModel(
      id: '',
      invoiceNumber: _invoiceNumber ?? 'INV-${now.millisecondsSinceEpoch}',
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name ?? '',
      items: List<SaleItemModel>.from(_cart),
      subtotal: _subtotal,
      itemDiscount: _itemDiscount,
      extraDiscount: _extraDiscount,
      tax: _tax,
      total: _total,
      paymentMethod: _paymentMethod,
      paymentStatus: _paymentStatus,
      paidAmount: _paidAmount,
      changeAmount: _changeAmount,
      status: 'completed',
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      saleDate: now,
      createdAt: now,
      updatedAt: now,
    );
    final provider = context.read<SaleProvider>();
    final ok = await provider.addSale(sale);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok) {
      _showSnack('Sale ${sale.invoiceNumber} completed', AppColors.success);
      Navigator.pop(context, true);
    } else {
      _showSnack('Failed to save sale', AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summarySale = SaleModel(
      id: '',
      invoiceNumber: _invoiceNumber ?? '',
      items: List<SaleItemModel>.from(_cart),
      subtotal: _subtotal,
      itemDiscount: _itemDiscount,
      extraDiscount: _extraDiscount,
      tax: _tax,
      total: _total,
      paymentMethod: _paymentMethod,
      paymentStatus: _paymentStatus,
      paidAmount: _paidAmount,
      changeAmount: _changeAmount,
      status: 'completed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isLoadingInvoice
            ? const Text('New Sale')
            : Text('New Sale — ${_invoiceNumber ?? ''}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear cart',
            onPressed: _cart.isEmpty ? null : _clearCart,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCustomerAndMeta(),
          _buildCart(),
          _buildPaymentSection(),
          SaleSummary(
            sale: summarySale,
            primaryButtonLabel: _isSubmitting ? 'Saving...' : 'Complete Sale',
            primaryButtonIcon: Icons.check_circle_outline,
            onPrimaryPressed: _isSubmitting
                ? null
                : (_cart.isEmpty ? null : _submit),
            enabled: _cart.isNotEmpty && !_isSubmitting,
          ),
        ],
      ),
      floatingActionButton: _cart.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _openProductPicker,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add Products'),
            )
          : null,
    );
  }

  Widget _buildCustomerAndMeta() {
    final customer = _selectedCustomer;
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          InkWell(
            onTap: _pickCustomer,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.person_outline,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer?.name ?? 'Walk-in Customer',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (customer != null)
                          Text(
                            customer.phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          const Text(
                            'Tap to select a customer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    customer == null
                        ? Icons.arrow_drop_down
                        : Icons.close,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    return Expanded(
      child: Container(
        color: AppColors.background,
        child: _cart.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'Cart is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the "Add Products" button to start',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: _cart.length,
                itemBuilder: (ctx, i) => SaleItemCard(
                  item: _cart[i],
                  onQuantityChanged: (qty) => _updateQuantity(i, qty),
                  onDiscountChanged: (d) => _updateItemDiscount(i, d),
                  onRemove: () => _removeItem(i),
                  editable: true,
                  showDiscountField: true,
                ),
              ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _methodChip('cash', 'Cash', Icons.payments_outlined),
              const SizedBox(width: 8),
              _methodChip('card', 'Card', Icons.credit_card),
              const SizedBox(width: 8),
              _methodChip('mobile', 'Mobile', Icons.phone_android),
              const SizedBox(width: 8),
              _methodChip('credit', 'Credit', Icons.account_balance_wallet),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _paidController,
                  label: 'Paid',
                  hint: '0.00',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  controller: _extraDiscountController,
                  label: 'Discount',
                  hint: '0.00',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  controller: _taxController,
                  label: 'Tax',
                  hint: '0.00',
                ),
              ),
            ],
          ),
          if (_paymentMethod == 'cash' &&
              _paidAmount > 0 &&
              _changeAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    'Change: BDT ${_changeAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Notes (optional)',
              hintText: 'Add a note for this sale',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _methodChip(String value, String label, IconData icon) {
    final selected = _paymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isBold = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: TextStyle(
        fontSize: 14,
        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final List<CustomerModel> customers;

  const _CustomerPickerSheet({required this.customers});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? widget.customers
        : widget.customers.where((c) {
            final q = _query.trim().toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                c.phone.contains(_query.trim());
          }).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Column(
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
              'Select Customer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.textSecondary,
              child: Icon(Icons.person_outline,
                  color: Colors.white, size: 18),
            ),
            title: const Text('Walk-in Customer'),
            subtitle: const Text('No customer record'),
            onTap: () => Navigator.pop(context, null),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No customers found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scroll,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            c.initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(c.name),
                        subtitle: Text(c.phone),
                        trailing: Text(
                          'BDT ${c.totalPurchases.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
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
  String _query = '';

  Color _stockColor(int stock, int threshold) {
    if (stock == 0) return AppColors.error;
    if (stock <= threshold) return AppColors.warning;
    return AppColors.success;
  }

  String _stockLabel(int stock, int threshold) {
    if (stock == 0) return 'Out';
    if (stock <= threshold) return 'Low';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? widget.products
        : widget.products.where((p) {
            final q = _query.trim().toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q);
          }).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, scroll) => Column(
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
              'Add Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search by name or SKU',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No products found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scroll,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final p = filtered[i];
                      final color =
                          _stockColor(p.stock, p.lowStockThreshold);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            p.name.isEmpty
                                ? '?'
                                : p.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.sku} • BDT ${p.sellingPrice.toStringAsFixed(2)}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_stockLabel(p.stock, p.lowStockThreshold)} (${p.stock})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        onTap: p.isOutOfStock
                            ? null
                            : () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
