import 'package:clinic_management_app/bloc/inventory_bloc/add_item_cubit.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/add_item_state.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
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

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF004AC6);
const _kBorder     = Color(0xFFE2E8F0);
const _kBg         = Color(0xFFF7F9FB);
const _kSurface    = Color(0xFFFFFFFF);
const _kSlate400   = Color(0xFF94A3B8);
const _kSlate500   = Color(0xFF64748B);
const _kSlate600   = Color(0xFF475569);
const _kSlate700   = Color(0xFF334155);
const _kSlate900   = Color(0xFF0F172A);
const _kAmber50    = Color(0xFFFFFBEB);
const _kAmber200   = Color(0xFFFDE68A);
const _kAmber700   = Color(0xFFB45309);
const _kAmber900   = Color(0xFF78350F);

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddItemCubit(
        itemsService: context.read<ItemsService>(),
        inventoryService: context.read<InventoryService>(),
      ),
      child: const _AddItemView(),
    );
  }
}

class _AddItemView extends StatefulWidget {
  const _AddItemView();

  @override
  State<_AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<_AddItemView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _initialStockController = TextEditingController();
  final _minLevelController = TextEditingController();
  final _unitController = TextEditingController();
  String? _selectedCategory;
  bool _coldChain = false;
  bool _controlled = false;
  bool _trackExpiry = true;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _initialStockController.dispose();
    _minLevelController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final name = _nameController.text.trim();
    final category = _selectedCategory;
    final unit = _unitController.text.trim().isEmpty
        ? 'ea'
        : _unitController.text.trim();
    final initialStock = _parseDouble(_initialStockController.text.trim());
    final price = _parseDouble(_priceController.text.trim());

    context.read<AddItemCubit>().addItem(
      name: name,
      category: category,
      unit: unit,
      price: price,
      initialStock: initialStock,
    );
  }

  double _parseDouble(String value) {
    if (value.trim().isEmpty) return 0;
    return double.tryParse(value) ?? 0;
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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return BlocListener<AddItemCubit, AddItemState>(
      listener: (context, state) {
        final error = state.error;
        if (error != null && error.isNotEmpty) {
          AppToast.error(context, error);
        }
        if (state.submitSuccess) {
          context.read<InventoryItemsBloc>().add(
            const InventoryItemsRefreshed(),
          );
          AppToast.success(context, 'Item added.');
          Navigator.of(context).pop(true);
        }
      },
      child: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  // ── Mobile ────────────────────────────────────────────────────────────────

  Widget _buildMobile() {
    return Scaffold(
      appBar: CustomAppBar(title: 'Add New Item'),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<AddItemCubit, AddItemState>(
          builder: (context, state) => PrimaryButton(
            text: 'Save Item',
            isLoading: state.isSubmitting,
            onPressed: _submit,
          ),
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
                _MobileFormField(
                  label: 'Item Name',
                  child: _CsTextField(
                    controller: _nameController,
                    hint: 'e.g. Rabies Vaccine (3-Year)',
                    validator: _validateRequired,
                  ),
                ),
                const SizedBox(height: 14),
                _MobileFormField(
                  label: 'Category',
                  child: _CsDropdown(
                    items: inventoryCategories,
                    value: _selectedCategory,
                    hint: 'Select category',
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                const SizedBox(height: 14),
                _MobileFormField(
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
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: _MobileFormField(
                        label: 'Initial Stock',
                        child: _CsTextField(
                          controller: _initialStockController,
                          hint: '0',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validateNumber,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _MobileFormField(
                        label: 'Min. Alert Level',
                        child: _CsTextField(
                          controller: _minLevelController,
                          hint: '5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validateNumber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MobileFormField(
                  label: 'Unit of Measure',
                  child: _CsTextField(
                    controller: _unitController,
                    hint: 'mg, ml, ea, vial, box…',
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
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _DesktopTopBar(
                title: 'New Inventory Entry',
                onCancel: () => Navigator.of(context).pop(),
                onSave: _submit,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Breadcrumb
                      _Breadcrumb(
                        items: const ['Inventory', 'Add New Item'],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'New Inventory Entry',
                        style: AppFonts.extraBold(
                          fontSize: 26,
                          color: _kSlate900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Register medical supplies, medications, or clinic equipment to the central database.',
                        style: AppFonts.regular(
                          fontSize: 13,
                          color: _kSlate500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Warning banner
                      _WarningBanner(
                        title: 'Mandatory Data Accuracy',
                        message:
                            'Please ensure all fields are complete and accurate. Pricing changes will be recorded in the audit log.',
                      ),
                      const SizedBox(height: 24),
                      // Two-column form
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                _DesktopFormCard(
                                  icon: Icons.medical_services_outlined,
                                  title: 'Basic Information',
                                  child: Column(
                                    children: [
                                      _DesktopFormField(
                                        label: 'Item Name',
                                        child: _CsTextField(
                                          controller: _nameController,
                                          hint: 'e.g. Rabies Vaccine (3-Year)',
                                          validator: _validateRequired,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        spacing: 16,
                                        children: [
                                          Expanded(
                                            child: _DesktopFormField(
                                              label: 'Category',
                                              child: _CsDropdown(
                                                items: inventoryCategories,
                                                value: _selectedCategory,
                                                hint: 'Select Category',
                                                onChanged: (v) => setState(
                                                  () => _selectedCategory = v,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: _DesktopFormField(
                                              label: 'Unit of Measure',
                                              child: _CsTextField(
                                                controller: _unitController,
                                                hint: 'vial, tab, mg, ml, ea…',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _DesktopFormCard(
                                  icon: Icons.payments_outlined,
                                  title: 'Pricing & Stock Control',
                                  child: Column(
                                    children: [
                                      Row(
                                        spacing: 16,
                                        children: [
                                          Expanded(
                                            child: _DesktopFormField(
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
                                          Expanded(
                                            child: _DesktopFormField(
                                              label: 'Initial Stock',
                                              child: _CsTextField(
                                                controller:
                                                    _initialStockController,
                                                hint: '0',
                                                keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                  decimal: true,
                                                ),
                                                validator: _validateNumber,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: _DesktopFormField(
                                              label: 'Min. Alert Level',
                                              child: _CsTextField(
                                                controller:
                                                    _minLevelController,
                                                hint: '5',
                                                isWarning: true,
                                                keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                  decimal: true,
                                                ),
                                                validator: _validateNumber,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 14,
                                            color: _kSlate400,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'A notification will be sent when stock drops below the minimum level.',
                                            style: AppFonts.regular(
                                              fontSize: 11,
                                              color: _kSlate400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right column
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                // Item preview
                                _SideCard(
                                  title: 'Item Preview',
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _kBorder,
                                          width: 1.5,
                                          strokeAlign:
                                              BorderSide.strokeAlignInside,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 36,
                                            color: _kSlate400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Upload Product Image',
                                            style: AppFonts.semiBold(
                                              fontSize: 12,
                                              color: _kSlate600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'PNG, JPG up to 5MB',
                                            style: AppFonts.regular(
                                              fontSize: 11,
                                              color: _kSlate400,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          OutlinedButton(
                                            onPressed: () {},
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _kSlate700,
                                              side: const BorderSide(
                                                color: _kBorder,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              textStyle: AppFonts.semiBold(
                                                fontSize: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                            ),
                                            child: const Text('Select File'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Storage conditions
                                _SideCard(
                                  title: 'Storage Conditions',
                                  child: Column(
                                    children: [
                                      _StorageToggle(
                                        icon: Icons.ac_unit_outlined,
                                        iconColor: const Color(0xFF3B82F6),
                                        label: 'Requires Cold Chain',
                                        value: _coldChain,
                                        onChanged: (v) =>
                                            setState(() => _coldChain = v),
                                      ),
                                      const SizedBox(height: 8),
                                      _StorageToggle(
                                        icon: Icons.priority_high_rounded,
                                        iconColor: const Color(0xFFF59E0B),
                                        label: 'Controlled Substance',
                                        value: _controlled,
                                        onChanged: (v) =>
                                            setState(() => _controlled = v),
                                      ),
                                      const SizedBox(height: 8),
                                      _StorageToggle(
                                        icon: Icons.event_outlined,
                                        iconColor: const Color(0xFF10B981),
                                        label: 'Track Expiry Date',
                                        value: _trackExpiry,
                                        onChanged: (v) =>
                                            setState(() => _trackExpiry = v),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Pro tip
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
                                      Text(
                                        'Pro Tip',
                                        style: AppFonts.bold(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Keeping accurate inventory helps prevent treatment delays. Items marked with Cold Chain will trigger alerts when stock runs low.',
                                        style: AppFonts.regular(
                                          fontSize: 11,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          height: 1.5,
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
                      // Footer actions
                      const SizedBox(height: 28),
                      const Divider(color: _kBorder),
                      const SizedBox(height: 16),
                      BlocBuilder<AddItemCubit, AddItemState>(
                        builder: (context, state) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: state.isSubmitting
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kSlate700,
                                  side: const BorderSide(color: _kBorder),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: AppFonts.medium(fontSize: 14),
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: state.isSubmitting ? null : _submit,
                                icon: state.isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save_outlined,
                                        size: 17,
                                      ),
                                label: const Text('Save Item'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: AppFonts.medium(fontSize: 14),
                                ),
                              ),
                            ],
                          );
                        },
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

// ── Shared form components ────────────────────────────────────────────────────

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.onCancel,
    required this.onSave,
  });

  final String title;
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
            child: Padding(
              padding: const EdgeInsets.all(4),
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
              title,
              style: AppFonts.semiBold(fontSize: 15, color: _kSlate900),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAmber50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kAmber200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _kAmber700,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kAmber900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _kAmber700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFormCard extends StatelessWidget {
  const _DesktopFormCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
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
          Row(
            children: [
              Icon(icon, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.bold(fontSize: 16, color: _kSlate900),
              ),
            ],
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
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kSlate400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StorageToggle extends StatelessWidget {
  const _StorageToggle({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppFonts.medium(fontSize: 13, color: _kSlate700),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _kPrimary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopFormField extends StatelessWidget {
  const _DesktopFormField({required this.label, required this.child});

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

class _MobileFormField extends StatelessWidget {
  const _MobileFormField({required this.label, required this.child});

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

// ── Shared input primitives ───────────────────────────────────────────────────

class _CsTextField extends StatelessWidget {
  const _CsTextField({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.isWarning = false,
  });

  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: 1,
      style: AppFonts.regular(fontSize: 13, color: _kSlate900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.regular(fontSize: 13, color: _kSlate400),
        filled: true,
        fillColor: isWarning
            ? const Color(0xFFFFFBEB)
            : AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(
            color: isWarning ? const Color(0xFFFDE68A) : _kBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(
            color: isWarning ? const Color(0xFFFDE68A) : _kBorder,
          ),
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
