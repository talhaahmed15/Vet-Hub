import 'package:clinic_management_app/bloc/inventory_bloc/inventory_txn_cubit.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/inventory_txn_state.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/screens/clinic/inventory/inventory_ui.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecieveItemScreen extends StatefulWidget {
  const RecieveItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<RecieveItemScreen> createState() => _RecieveItemScreenState();
}

class _RecieveItemScreenState extends State<RecieveItemScreen> {
  late final TextEditingController _quantityController;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _newTotal {
    final parsed = _parseQuantity(_quantityController.text.trim());
    final quantity = parsed ?? 0;
    return (widget.item.onHand + quantity).clamp(0, double.infinity).toDouble();
  }

  double? _parseQuantity(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _submit(BuildContext context) {
    final quantity = _parseQuantity(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      AppToast.error(context, 'Enter a quantity greater than 0.');
      return;
    }

    final note = _notesController.text.trim();
    context.read<InventoryTxnCubit>().submitTxn(
      itemId: widget.item.id,
      txnType: InventoryTxnType.receive,
      quantity: quantity,
      note: note.isEmpty ? null : note,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryTxnCubit(),
      child: BlocConsumer<InventoryTxnCubit, InventoryTxnState>(
        listener: (context, state) {
          final error = state.error;
          if (error != null && error.isNotEmpty) {
            AppToast.error(context, error);
          }
          if (state.submitSuccess) {
            BlocProvider.of<InventoryItemDetailBloc>(
              context,
            ).add(const InventoryItemDetailRefreshed());
            context.read<InventoryItemsBloc>().add(
              InventoryItemRefetched(itemId: widget.item.id),
            );
            AppToast.success(context, 'Stock received.');
            Navigator.of(context).maybePop(true);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: CustomAppBar(title: "Receive New Stock"),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryIconButton(
                    text: 'Confirm Receipt',
                    icon: Icons.inventory_2_outlined,
                    isLoading: state.isSubmitting,
                    isEnabled: !state.isSubmitting,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New stock after receipt: ${_formatQuantity(_newTotal)} ${widget.item.unit.toLowerCase()}',
                    style: AppFonts.medium(
                      fontSize: 12,
                      color: AppColors.greyBlue,
                    ),
                  ),
                ],
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _ProductDetailCard(item: widget.item),
                24.height,
                const InventorySectionHeader('Inventory Data'),
                16.height,
                const _FieldLabel('Quantity Received'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hintText: '0',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.item.unit.toLowerCase(),
                      style: AppFonts.medium(
                        fontSize: 13,
                        color: AppColors.greyBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // const _FieldLabel('Batch/Lot Number'),
                // const SizedBox(height: 4),
                // CustomTextField(
                //   controller: _batchController,
                //   hint: 'Enter batch code',
                //   textInputAction: TextInputAction.next,
                //   suffixIcon: IconButton(
                //     onPressed: () {},
                //     icon: const Icon(
                //       Icons.qr_code_scanner_rounded,
                //       color: AppColors.primary,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 16),
                // const _FieldLabel('Expiry Date'),
                // const SizedBox(height: 4),
                // CustomTextField(
                //   controller: _expiryController,
                //   hint: 'mm/dd/yyyy',
                //   readOnly: true,
                //   onTap: _pickExpiryDate,
                //   suffixIcon: const Icon(
                //     Icons.calendar_today_outlined,
                //     color: AppColors.greyBlue,
                //     size: 18,
                //   ),
                // ),
                // const SizedBox(height: 16),
                // const _FieldLabel('Supplier'),
                // const SizedBox(height: 4),
                // CustomDropdownField<String>(
                //   value: _supplier,
                //   items: _suppliers,
                //   hint: 'Select a supplier',
                //   labelBuilder: (supplier) => supplier,
                //   onChanged: (value) => setState(() => _supplier = value),
                //   icon: const Icon(
                //     Icons.keyboard_arrow_down_rounded,
                //     color: AppColors.greyBlue,
                //   ),
                //   decoration: inventoryInputDecoration(
                //     hintText: 'Select a supplier',
                //   ),
                // ),
                // const SizedBox(height: 16),
                const _FieldLabel('Notes (Optional)'),
                const SizedBox(height: 4),
                CustomTextField(
                  controller: _notesController,
                  maxLines: 6,
                  hintText: 'Add any delivery notes...',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductDetailCard extends StatelessWidget {
  const _ProductDetailCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppFonts.bold(fontSize: 16, color: AppColors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Stock: ${_formatQuantity(item.onHand)} ${item.unit.toLowerCase()}',
                  style: AppFonts.medium(
                    fontSize: 12,
                    color: AppColors.greyBlue,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppFonts.semiBold(fontSize: 14, color: AppColors.black),
    );
  }
}

String _skuFromItem(Item item) {
  final normalized = item.name
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
  final skuSeed = normalized.isEmpty ? item.id : normalized;
  return 'VET-${skuSeed.split('-').take(3).join('-')}';
}

String _formatQuantity(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
