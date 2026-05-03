import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class AddItemResult {
  const AddItemResult({
    required this.name,
    required this.category,
    required this.unit,
  });

  final String name;
  final String? category;
  final String unit;
}

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController(text: 'ea');

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final result = AddItemResult(
      name: _nameController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      unit: _unitController.text.trim().isEmpty
          ? 'ea'
          : _unitController.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
        'Add Item',
        style: AppFonts.semiBold(fontSize: 16, color: AppColors.black),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name',
                style: AppFonts.medium(fontSize: 12, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _nameController,
                hintText: 'e.g. Gauze Pads',
                keyboardType: TextInputType.name,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Category (optional)',
                style: AppFonts.medium(fontSize: 12, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _categoryController,
                hintText: 'e.g. Consumables',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              Text(
                'Unit',
                style: AppFonts.medium(fontSize: 12, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _unitController,
                hintText: 'ea, box, ml, etc.',
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              PrimaryButton(text: 'Add Item', onPressed: _submit),
              const SizedBox(height: 8),
              PrimaryOutlinedButton(
                text: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
