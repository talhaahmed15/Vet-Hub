import 'package:clinic_management_app/bloc/inventory_bloc/add_item_cubit.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/add_item_state.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_consts.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/themes/app_icons.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final _unitController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _initialStockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final unit = _unitController.text.trim().isEmpty
        ? 'ea'
        : _unitController.text.trim();

    context.read<AddItemCubit>().addItem(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      unit: unit,
      price: _parseDouble(_priceController.text.trim()),
      initialStock: _parseDouble(_initialStockController.text.trim()),
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

  String? _validateRequiredNumber(String? value) {
    final r = _validateRequired(value);
    if (r != null) return r;
    return _validateNumber(value);
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
      appBar: CustomAppBar(
        title: 'Add New Item',
        trailing: BlocBuilder<AddItemCubit, AddItemState>(
          builder: (context, state) => TextButton(
            onPressed: state.isSubmitting ? null : _submit,
            child: state.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: AppFonts.semiBold(
                      fontSize: 14,
                      color: AppColors.primaryDeep,
                    ),
                  ),
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
                _FieldLabel('Item Name'),
                CustomTextField(
                  controller: _nameController,
                  hintText: 'e.g. Rabies Vaccine (3-Year)',
                  validator: _validateRequired,
                ),
                const SizedBox(height: 14),
                _FieldLabel('Category'),
                CustomDropdownField<String>(
                  items: inventoryCategories,
                  value: _selectedCategory,
                  hintText: 'Select category',
                  labelBuilder: (v) => v,
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 14),
                _FieldLabel('Selling Price (\$)'),
                CustomTextField(
                  controller: _priceController,
                  hintText: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateRequiredNumber,
                ),
                const SizedBox(height: 14),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Initial Stock'),
                          CustomTextField(
                            controller: _initialStockController,
                            hintText: '0',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _validateNumber,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Unit of Measure'),
                          CustomTextField(
                            controller: _unitController,
                            hintText: 'mg, ml, ea, vial…',
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
      ),
    );
  }

  // ── Desktop ───────────────────────────────────────────────────────────────

  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Breadcrumb(items: const ['Inventory', 'Add New Item']),
                          const SizedBox(height: 6),
                          Text(
                            'New Inventory Entry',
                            style: AppFonts.extraBold(
                              fontSize: 26,
                              color: AppColors.slate900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            'Register medical supplies, medications, or clinic equipment.',
                            style: AppFonts.regular(
                              fontSize: 13,
                              color: AppColors.slate500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _DesktopFormCard(
                            iconAsset: AppIcons.stethoscope,
                            title: 'Basic Information',
                            child: Column(
                              children: [
                                _FieldLabel('Item Name'),
                                CustomTextField(
                                  controller: _nameController,
                                  hintText: 'e.g. Rabies Vaccine (3-Year)',
                                  validator: _validateRequired,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  spacing: 16,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _FieldLabel('Category'),
                                          CustomDropdownField<String>(
                                            items: inventoryCategories,
                                            value: _selectedCategory,
                                            hintText: 'Select Category',
                                            labelBuilder: (v) => v,
                                            onChanged: (v) => setState(
                                              () => _selectedCategory = v,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _FieldLabel('Unit of Measure'),
                                          CustomTextField(
                                            controller: _unitController,
                                            hintText: 'vial, tab, mg, ml, ea…',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _DesktopFormCard(
                            iconAsset: AppIcons.walletMoney,
                            title: 'Pricing & Stock',
                            child: Row(
                              spacing: 16,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel('Selling Price (\$)'),
                                      CustomTextField(
                                        controller: _priceController,
                                        hintText: '0.00',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: _validateRequiredNumber,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _FieldLabel('Initial Stock'),
                                      CustomTextField(
                                        controller: _initialStockController,
                                        hintText: '0',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: _validateNumber,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

// ── Desktop chrome ────────────────────────────────────────────────────────────

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
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          InkWell(
            onTap: onCancel,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AppIcons.show(
                AppIcons.squareArrowLeft,
                size: 20,
                color: AppColors.slate500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppFonts.semiBold(fontSize: 15, color: AppColors.slate900),
            ),
          ),
          BlocBuilder<AddItemCubit, AddItemState>(
            builder: (context, state) {
              return FilledButton.icon(
                onPressed: state.isSubmitting ? null : onSave,
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : AppIcons.show(
                        AppIcons.clipboardAdd,
                        size: 17,
                        color: Colors.white,
                      ),
                label: const Text('Save Item'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: AppFonts.medium(fontSize: 13),
                ),
              );
            },
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
            color: isLast ? AppColors.slate900 : AppColors.slate400,
            fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      );
      if (!isLast) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AppIcons.show(
              AppIcons.squareArrowRight,
              size: 12,
              color: AppColors.slate400,
            ),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: widgets),
    );
  }
}

class _DesktopFormCard extends StatelessWidget {
  const _DesktopFormCard({
    required this.iconAsset,
    required this.title,
    required this.child,
  });

  final String iconAsset;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcons.show(iconAsset, size: 20, color: AppColors.primaryDeep),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppFonts.bold(fontSize: 16, color: AppColors.slate900),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.slate700,
        ),
      ),
    );
  }
}
