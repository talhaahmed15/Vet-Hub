import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class TxnResult {
  const TxnResult({
    required this.txnType,
    required this.quantity,
    required this.note,
  });

  final InventoryTxnType txnType;
  final double quantity;
  final String? note;
}

class TxnDialog extends StatefulWidget {
  const TxnDialog({
    super.key,
    required this.itemName,
    required this.unit,
    this.initialTxnType,
  });

  final String itemName;
  final String unit;
  final InventoryTxnType? initialTxnType;

  @override
  State<TxnDialog> createState() => _TxnDialogState();
}

class _TxnDialogState extends State<TxnDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  late InventoryTxnType _txnType;

  @override
  void initState() {
    super.initState();
    _txnType = widget.initialTxnType ?? InventoryTxnType.receive;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final quantity = _parseQuantity(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      return;
    }

    final result = TxnResult(
      txnType: _txnType,
      quantity: quantity,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  double? _parseQuantity(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_txnType.label} - ${widget.itemName}';
    final isTypeLocked = widget.initialTxnType != null;

    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
        title,
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
                'Transaction type',
                style: AppFonts.medium(fontSize: 12, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<InventoryTxnType>(
                initialValue: _txnType,
                style: AppFonts.regular(fontSize: 12, color: AppColors.black),
                decoration: _decoration(),
                items: InventoryTxnType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isTypeLocked
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _txnType = value);
                      },
              ),
              const SizedBox(height: 12),
              Text(
                _txnType == InventoryTxnType.adjust
                    ? 'Set on hand to'
                    : 'Quantity',
                style: AppFonts.medium(fontSize: 12, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _quantityController,
                autofocus: true,
                style: AppFonts.regular(fontSize: 12, color: AppColors.black),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  hintText: '0.000',
                  suffixText: widget.unit,
                  helperText: _txnType == InventoryTxnType.adjust
                      ? 'This will set the on-hand value.'
                      : 'Enter a positive quantity.',
                ),
                validator: (value) {
                  final quantity = _parseQuantity(value ?? '');
                  if (quantity == null) {
                    return 'Enter a valid number.';
                  }
                  if (quantity <= 0) {
                    return 'Quantity must be greater than 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Note (optional)',
                style: AppFonts.medium(fontSize: 12, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                style: AppFonts.regular(fontSize: 12, color: AppColors.black),
                textInputAction: TextInputAction.done,
                decoration: _decoration(hintText: 'Reason / reference'),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              PrimaryButton(text: 'Save', onPressed: _submit),
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

  InputDecoration _decoration({
    String? hintText,
    String? suffixText,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixText: suffixText,
      helperText: helperText,
      helperStyle: AppFonts.regular(fontSize: 10, color: AppColors.grey),
      hintStyle: AppFonts.regular(fontSize: 12, color: AppColors.grey),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }
}
