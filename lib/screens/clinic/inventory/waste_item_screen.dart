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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WasteItemScreen extends StatefulWidget {
  const WasteItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<WasteItemScreen> createState() => _WasteItemScreenState();
}

class _WasteItemScreenState extends State<WasteItemScreen> {
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
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
    if (quantity > widget.item.onHand) {
      AppToast.error(context, 'Not enough stock on hand.');
      return;
    }

    final note = _notesController.text.trim();
    context.read<InventoryTxnCubit>().submitTxn(
      itemId: widget.item.id,
      txnType: InventoryTxnType.waste,
      quantity: quantity,
      note: note.isEmpty ? null : note,
    );
  }

  double get _quantity {
    final parsed = double.tryParse(_quantityController.text.trim());
    if (parsed == null || parsed <= 0) return 1;
    return parsed;
  }

  double get _remaining =>
      (widget.item.onHand - _quantity).clamp(0, double.infinity).toDouble();

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
            AppToast.success(context, 'Waste recorded.');
            Navigator.of(context).maybePop(true);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: CustomAppBar(title: "Record Waste"),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryIconButton(
                    text: 'Confirm Adjustment',
                    icon: Icons.check_circle_rounded,
                    isLoading: state.isSubmitting,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining stock after waste: ${_formatQuantity(_remaining)} ${widget.item.unit.toLowerCase()}',
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
                Text(
                  'Use this form to adjust inventory levels for items that are no longer usable. This action cannot be undone.',
                  style: AppFonts.medium(
                    fontSize: 12,
                    color: AppColors.greyBlue,
                  ),
                ),
                const SizedBox(height: 16),
                _CurrentlyTrackingCard(item: widget.item),
                const SizedBox(height: 24),
                const InventorySectionHeader('Waste Details'),
                const SizedBox(height: 16),
                const _FieldLabel('Quantity Wasted'),
                const SizedBox(height: 4),
                CustomTextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: '1',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // const _FieldLabel('Reason for Waste'),
                // const SizedBox(height: 4),
                // CustomDropdownField<String>(
                //   value: _reason,
                //   items: _reasons,
                //   hint: 'Select reason',
                //   labelBuilder: (reason) => reason,
                //   onChanged: (value) => setState(() => _reason = value),
                //   icon: const Icon(
                //     Icons.unfold_more_rounded,
                //     color: AppColors.greyBlue,
                //   ),
                //   decoration: inventoryInputDecoration(
                //     hintText: 'Select reason',
                //   ),
                // ),
                // const SizedBox(height: 16),
                const _FieldLabel('Notes (Optional)'),
                const SizedBox(height: 4),
                CustomTextField(
                  controller: _notesController,
                  maxLines: 6,
                  hintText: 'Add additional details about the waste incident...',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurrentlyTrackingCard extends StatelessWidget {
  const _CurrentlyTrackingCard({required this.item});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppFonts.bold(fontSize: 16, color: AppColors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stock: ${_formatQuantity(item.onHand)} ${item.unit.toLowerCase()}',
                  style: AppFonts.medium(
                    fontSize: 12,
                    color: AppColors.greyBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: AppColors.primary,
              size: 30,
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

String _formatQuantity(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
