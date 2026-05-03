import 'package:clinic_management_app/bloc/inventory_bloc/add_item_cubit.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/add_item_state.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_consts.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
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
  final _minLevelController = TextEditingController();
  final _unitController = TextEditingController();
  String? _selectedCategory;

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
    if (form == null || !form.validate()) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
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
      child: Scaffold(
        appBar: CustomAppBar(title: "Add New Item"),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<AddItemCubit, AddItemState>(
            builder: (context, state) {
              return PrimaryButton(
                text: "Save Item",
                isLoading: state.isSubmitting,
                onPressed: _submit,
              );
            },
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
                  Container(
                    padding: .symmetric(vertical: 16, horizontal: 24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: AppColors.primary.withOpacity(0.15),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        10.height,
                        Text(
                          "Upload Item Photo",
                          style: AppFonts.semiBold(fontSize: 14),
                          textAlign: .center,
                        ),
                        2.5.height,
                        Text(
                          "Add a photo of the product for easier identification",
                          style: AppFonts.regular(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                          textAlign: .center,
                        ),
                      ],
                    ),
                  ),
                  16.height,
                  Text("Item name", style: AppFonts.semiBold(fontSize: 12)),
                  4.height,
                  CustomTextField(
                    controller: _nameController,
                    hintText: "e.g Amoxicillin",
                    validator: _validateRequired,
                  ),
                  16.height,
                  Text("Category", style: AppFonts.semiBold(fontSize: 12)),
                  4.height,
                  CustomDropdownField<String>(
                    items: inventoryCategories,
                    value: _selectedCategory,
                    hintText: 'Select category',
                    labelBuilder: (value) => value,
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
                  16.height,
                  Text("Price", style: AppFonts.semiBold(fontSize: 12)),
                  4.height,
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
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              "Initial Stock",
                              style: AppFonts.semiBold(fontSize: 12),
                            ),
                            4.height,
                            CustomTextField(
                              controller: _initialStockController,
                              hintText: "0",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: _validateNumber,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              "Min Level",
                              style: AppFonts.semiBold(fontSize: 12),
                            ),
                            4.height,
                            CustomTextField(
                              controller: _minLevelController,
                              hintText: "5",
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
                  16.height,
                  Text(
                    "Unit of Measure",
                    style: AppFonts.semiBold(fontSize: 12),
                  ),
                  4.height,
                  CustomTextField(
                    controller: _unitController,
                    hintText: "mg, ml, ea, etc.",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
