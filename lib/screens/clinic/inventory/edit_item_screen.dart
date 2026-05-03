import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _categoryController = TextEditingController(
      text: widget.item.category ?? '',
    );
    _priceController = TextEditingController(
      text: widget.item.price > 0 ? widget.item.price.toStringAsFixed(2) : '',
    );
    _unitController = TextEditingController(text: widget.item.unit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed < 0) {
      return 'Must be 0 or more.';
    }
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
      final category = _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim();
      final unit = _unitController.text.trim().isEmpty
          ? 'ea'
          : _unitController.text.trim();
      final price = _parseDouble(_priceController.text.trim());

      await context.read<ItemsService>().updateItem(
        id: widget.item.id,
        name: name,
        category: category,
        unit: unit,
        price: price,
      );

      context.read<InventoryItemDetailBloc>().add(
        const InventoryItemDetailRefreshed(),
      );
      context.read<InventoryItemsBloc>().add(
        InventoryItemRefetched(itemId: widget.item.id),
      );

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
    return Scaffold(
      appBar: CustomAppBar(title: 'Edit Item'),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PrimaryButton(
          text: 'Save Changes',
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                16.height,
                Text("Item name", style: AppFonts.semiBold(fontSize: 12)),
                CustomTextField(
                  controller: _nameController,
                  hintText: "e.g Amoxicillin",
                  validator: _validateRequired,
                ),
                16.height,
                Text("Category", style: AppFonts.semiBold(fontSize: 12)),
                CustomTextField(
                  controller: _categoryController,
                  hintText: "Select category",
                ),
                16.height,
                Text("Price", style: AppFonts.semiBold(fontSize: 12)),
                CustomTextField(
                  controller: _priceController,
                  hintText: "0.00",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final requiredError = _validateRequired(value);
                    if (requiredError != null) return requiredError;
                    return _validateNumber(value);
                  },
                ),
                16.height,
                Text("Unit of Measure", style: AppFonts.semiBold(fontSize: 12)),
                CustomTextField(
                  controller: _unitController,
                  hintText: "mg, ml, ea, etc.",
                ),
                16.height,
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Prices are used when adding products to invoices.',
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.darkGrey,
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
}
