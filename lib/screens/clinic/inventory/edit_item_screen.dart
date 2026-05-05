import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/enums/item_status_enum.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_consts.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary     = Color(0xFF004AC6);
const _kBorder      = Color(0xFFE2E8F0);
const _kBorderFaint = Color(0xFFF1F5F9);
const _kBg          = Color(0xFFF7F9FB);
const _kSurface     = Color(0xFFFFFFFF);
const _kSlate50     = Color(0xFFF8FAFC);
const _kSlate400    = Color(0xFF94A3B8);
const _kSlate500    = Color(0xFF64748B);
const _kSlate700    = Color(0xFF334155);
const _kSlate900    = Color(0xFF0F172A);
const _kAmber700    = Color(0xFFB45309);
const _kAmber900    = Color(0xFF78350F);

class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  String? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _selectedCategory = widget.item.category;
    _priceController = TextEditingController(
      text: widget.item.price > 0
          ? widget.item.price.toStringAsFixed(2)
          : '',
    );
    _unitController = TextEditingController(text: widget.item.unit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number.';
    if (parsed < 0) return 'Must be 0 or more.';
    return null;
  }

  double _parseDouble(String value) {
    if (value.trim().isEmpty) return 0;
    return double.tryParse(value.trim()) ?? 0;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final name = _nameController.text.trim();
      final category = _selectedCategory?.trim().isEmpty ?? true
          ? null
          : _selectedCategory?.trim();
      final unit = _unitController.text.trim().isEmpty
          ? 'ea'
          : _unitController.text.trim();
      final price = _parseDouble(_priceController.text.trim());
      final itemsService = context.read<ItemsService>();
      final detailBloc = context.read<InventoryItemDetailBloc>();
      final listBloc = context.read<InventoryItemsBloc>();

      await itemsService.updateItem(
        id: widget.item.id,
        name: name,
        category: category,
        unit: unit,
        price: price,
      );

      detailBloc.add(const InventoryItemDetailRefreshed());
      listBloc.add(InventoryItemRefetched(itemId: widget.item.id));

      if (!mounted) return;
      AppToast.success(context, 'Item updated.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return isMobile ? _buildMobile() : _buildDesktop();
  }

  // ── Mobile ────────────────────────────────────────────────────────────────

  Widget _buildMobile() {
    return Scaffold(
      appBar: CustomAppBar(title: 'Edit Item'),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          text: 'Save Changes',
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MobileField(
                  label: 'Item Name',
                  child: _CsTextField(
                    controller: _nameController,
                    hint: 'e.g. Amoxicillin',
                    validator: _validateRequired,
                  ),
                ),
                const SizedBox(height: 14),
                _MobileField(
                  label: 'Category',
                  child: _CsDropdown(
                    items: inventoryCategories,
                    value: _selectedCategory,
                    hint: 'Select category',
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                const SizedBox(height: 14),
                _MobileField(
                  label: 'Selling Price (\$)',
                  child: _CsTextField(
                    controller: _priceController,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final r = _validateRequired(v);
                      if (r != null) return r;
                      return _validateNumber(v);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _MobileField(
                  label: 'Unit of Measure',
                  child: _CsTextField(
                    controller: _unitController,
                    hint: 'mg, ml, ea, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Prices are used when adding products to invoices.',
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: _kSlate500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop ───────────────────────────────────────────────────────────────

  Widget _buildDesktop() {
    final item = widget.item;
    final minThreshold = minThresholdFor(item.category);
    final status = statusFor(item.onHand, minThreshold);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Top action bar
              _EditTopBar(
                itemName: item.name,
                isSubmitting: _isSubmitting,
                onCancel: () => Navigator.of(context).pop(),
                onSave: _submit,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb + title
                      _Breadcrumb(
                        items: [
                          'Inventory',
                          item.category ?? 'General',
                          'Edit Item',
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Edit Item: ${item.name}',
                        style: AppFonts.extraBold(
                          fontSize: 26,
                          color: _kSlate900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Left column ────────────────────────────────
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                // General Information card
                                _FormCard(
                                  title: 'General Information',
                                  child: Column(
                                    children: [
                                      _Field(
                                        label: 'Product Name',
                                        child: _CsTextField(
                                          controller: _nameController,
                                          hint: 'Product name',
                                          validator: _validateRequired,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        spacing: 16,
                                        children: [
                                          Expanded(
                                            child: _Field(
                                              label: 'SKU / ID',
                                              child: _ReadOnlyField(
                                                value: _skuFrom(item),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: _Field(
                                              label: 'Category',
                                              child: _CsDropdown(
                                                items: inventoryCategories,
                                                value: _selectedCategory,
                                                hint: 'Select category',
                                                onChanged: (v) => setState(
                                                  () => _selectedCategory = v,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Inventory & Pricing card
                                _FormCard(
                                  title: 'Inventory & Pricing',
                                  child: Column(
                                    children: [
                                      if (status == InventoryStatus.lowStock ||
                                          status ==
                                              InventoryStatus.outOfStock) ...[
                                        _AlertBanner(status: status),
                                        const SizedBox(height: 16),
                                      ],
                                      Row(
                                        spacing: 16,
                                        children: [
                                          Expanded(
                                            child: _Field(
                                              label: 'Current Stock',
                                              child: _ReadOnlyField(
                                                value:
                                                    '${formatQuantity(item.onHand)} ${unitLabel(item.unit)}',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: _Field(
                                              label: 'Min. Threshold',
                                              child: _ReadOnlyField(
                                                value: formatQuantity(
                                                  minThreshold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: _Field(
                                              label: 'Unit Type',
                                              child: _CsTextField(
                                                controller: _unitController,
                                                hint: 'tablet, vial, mg…',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        spacing: 16,
                                        children: [
                                          Expanded(
                                            child: _Field(
                                              label: 'Selling Price (\$)',
                                              child: _CsTextField(
                                                controller: _priceController,
                                                hint: '0.00',
                                                keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                  decimal: true,
                                                ),
                                                validator: (v) {
                                                  final r =
                                                      _validateRequired(v);
                                                  if (r != null) return r;
                                                  return _validateNumber(v);
                                                },
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: SizedBox()),
                                          const Expanded(child: SizedBox()),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // ── Right column ───────────────────────────────
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                // Stock Overview card
                                _StockOverviewCard(
                                  item: item,
                                  status: status,
                                  minThreshold: minThreshold,
                                ),
                                const SizedBox(height: 16),
                                // Recent Movements card
                                _RecentMovementsCard(item: item),
                                const SizedBox(height: 16),
                                // Order supplies promo
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _kPrimary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Manage Stock',
                                        style: AppFonts.bold(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Use the item detail view to receive, use, or adjust stock with full transaction history.',
                                        style: AppFonts.regular(
                                          fontSize: 11,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _kPrimary,
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.white,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 9,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            textStyle: AppFonts.bold(
                                              fontSize: 12,
                                            ),
                                          ),
                                          child: const Text('View Item Detail'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Edit top action bar ───────────────────────────────────────────────────────

class _EditTopBar extends StatelessWidget {
  const _EditTopBar({
    required this.itemName,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSave,
  });

  final String itemName;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: _kSlate500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.semiBold(fontSize: 15, color: _kSlate900),
            ),
          ),
          OutlinedButton(
            onPressed: isSubmitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kSlate700,
              side: const BorderSide(color: _kBorder),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: AppFonts.medium(fontSize: 13),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: isSubmitting ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: AppFonts.medium(fontSize: 13),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update Item'),
          ),
        ],
      ),
    );
  }
}

// ── Stock Overview card ───────────────────────────────────────────────────────

class _StockOverviewCard extends StatelessWidget {
  const _StockOverviewCard({
    required this.item,
    required this.status,
    required this.minThreshold,
  });

  final Item item;
  final InventoryStatus status;
  final double minThreshold;

  @override
  Widget build(BuildContext context) {
    final Color statusBg, statusText;
    switch (status) {
      case InventoryStatus.inStock:
        statusBg = const Color(0xFFF0FDF4);
        statusText = const Color(0xFF166534);
      case InventoryStatus.lowStock:
        statusBg = const Color(0xFFFEF3C7);
        statusText = const Color(0xFF92400E);
      case InventoryStatus.outOfStock:
        statusBg = const Color(0xFFFEE2E2);
        statusText = const Color(0xFF991B1B);
    }

    return _SideCard(
      title: 'Stock Overview',
      child: Column(
        children: [
          _OverviewRow(
            label: 'Status',
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                status.label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusText,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _OverviewRow(
            label: 'On Hand',
            value: '${formatQuantity(item.onHand)} ${item.unit}',
            valueColor: _kPrimary,
          ),
          const SizedBox(height: 8),
          _OverviewRow(
            label: 'Min. Threshold',
            value: formatQuantity(minThreshold),
          ),
          const SizedBox(height: 8),
          _OverviewRow(
            label: 'Unit Price',
            value: '\$${item.price.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _OverviewRow(
            label: 'Stock Value',
            value:
                '\$${(item.price * item.onHand).toStringAsFixed(2)}',
            valueColor: _kSlate900,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.label,
    this.value,
    this.trailing,
    this.valueColor,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _kSlate50,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: _kSlate500,
            ),
          ),
          trailing ??
              Text(
                value ?? '—',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? _kSlate900,
                ),
              ),
        ],
      ),
    );
  }
}

// ── Recent Movements card ─────────────────────────────────────────────────────

class _RecentMovementsCard extends StatelessWidget {
  const _RecentMovementsCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryItemDetailBloc, InventoryItemDetailState>(
      builder: (context, state) {
        final txns = state is InventoryItemDetailLoaded ? state.txns : <InventoryTxn>[];
        final recent = txns.take(4).toList(growable: false);

        return Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Movements',
                      style: AppFonts.bold(fontSize: 14, color: _kSlate900),
                    ),
                    if (txns.length > 4)
                      Text(
                        'View All',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _kBorderFaint),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No transactions yet.',
                    style: AppFonts.regular(
                      fontSize: 13,
                      color: _kSlate400,
                    ),
                  ),
                )
              else
                ...recent.asMap().entries.map((entry) {
                  final i = entry.key;
                  final txn = entry.value;
                  final isLast = i == recent.length - 1;
                  return _MovementRow(
                    txn: txn,
                    unit: item.unit,
                    showDivider: !isLast,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.txn,
    required this.unit,
    required this.showDivider,
  });

  final InventoryTxn txn;
  final String unit;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final Color iconBg, iconColor;
    final IconData icon;
    final String deltaLabel;

    switch (txn.txnType) {
      case InventoryTxnType.receive:
        iconBg = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF16A34A);
        icon = Icons.add_rounded;
        deltaLabel = '+${_fmtQty(txn.quantity)} $unit';
      case InventoryTxnType.use:
        iconBg = const Color(0xFFEFF6FF);
        iconColor = _kPrimary;
        icon = Icons.remove_rounded;
        deltaLabel = '-${_fmtQty(txn.quantity)} $unit';
      case InventoryTxnType.waste:
        iconBg = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFDC2626);
        icon = Icons.delete_outline_rounded;
        deltaLabel = '-${_fmtQty(txn.quantity)} $unit';
      case InventoryTxnType.adjust:
        iconBg = const Color(0xFFF1F5F9);
        iconColor = _kSlate500;
        icon = Icons.tune_rounded;
        deltaLabel = '=${_fmtQty(txn.quantity)} $unit';
    }

    final timeAgo = _timeAgo(txn.createdAt);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.txnType.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kSlate900,
                      ),
                    ),
                    if (txn.note != null && txn.note!.isNotEmpty)
                      Text(
                        txn.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: _kSlate400,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    deltaLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: _kSlate400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: _kBorderFaint),
      ],
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.status});

  final InventoryStatus status;

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = status == InventoryStatus.outOfStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isOutOfStock
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOutOfStock
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: isOutOfStock
                ? const Color(0xFFDC2626)
                : _kAmber700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOutOfStock
                  ? 'This item is out of stock. A reorder notification has been triggered.'
                  : 'Current stock is below the threshold. A reorder notification will be triggered.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOutOfStock
                    ? const Color(0xFF991B1B)
                    : _kAmber900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final isLast = i == items.length - 1;
      widgets.add(
        Text(
          items[i],
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: isLast ? _kSlate900 : _kSlate400,
            fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      );
      if (!isLast) {
        widgets.add(
          const Icon(Icons.chevron_right, size: 14, color: _kSlate400),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: widgets),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.bold(fontSize: 16, color: _kSlate900),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.bold(fontSize: 14, color: _kSlate900),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kSlate700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MobileField extends StatelessWidget {
  const _MobileField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.semiBold(fontSize: 12)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _kSlate50,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: _kSlate500,
        ),
      ),
    );
  }
}

// ── Input primitives ──────────────────────────────────────────────────────────

class _CsTextField extends StatelessWidget {
  const _CsTextField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: AppFonts.regular(fontSize: 13, color: _kSlate900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.regular(fontSize: 13, color: _kSlate400),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _CsDropdown extends StatelessWidget {
  const _CsDropdown({
    required this.items,
    required this.hint,
    required this.onChanged,
    this.value,
  });

  final List<String> items;
  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      isDense: true,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _kSlate400,
        size: 18,
      ),
      style: AppFonts.regular(fontSize: 13, color: _kSlate900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.regular(fontSize: 13, color: _kSlate400),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _skuFrom(Item item) {
  final normalized = item.name
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
  if (normalized.isEmpty) {
    final id = item.id.replaceAll('-', '').toUpperCase();
    return id.substring(0, id.length.clamp(0, 8));
  }
  return normalized.split('-').take(3).join('-');
}

String _fmtQty(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.yMMMd().format(dateTime.toLocal());
}
