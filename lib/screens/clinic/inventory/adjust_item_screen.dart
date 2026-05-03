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

class AdjustItemScreen extends StatefulWidget {
  const AdjustItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<AdjustItemScreen> createState() => _AdjustItemScreenState();
}

class _AdjustItemScreenState extends State<AdjustItemScreen> {
  late final TextEditingController _quantityController;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: _formatQuantity(widget.item.onHand),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _currentOnHand => widget.item.onHand;

  double get _newTotal {
    final parsed = double.tryParse(_quantityController.text.trim());
    if (parsed == null) {
      return _currentOnHand;
    }
    return parsed.clamp(0, double.infinity).toDouble();
  }

  double get _difference => _newTotal - _currentOnHand;

  double? _parseQuantity(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _step(double delta) {
    final next = (_newTotal + delta).clamp(0, double.infinity).toDouble();
    setState(() {
      _quantityController.text = _formatQuantity(next);
    });
  }

  void _submit(BuildContext context) {
    final parsed = _parseQuantity(_quantityController.text);
    if (parsed == null || parsed < 0) {
      AppToast.error(context, 'Enter a valid quantity.');
      return;
    }

    final note = _notesController.text.trim();
    context.read<InventoryTxnCubit>().submitTxn(
      itemId: widget.item.id,
      txnType: InventoryTxnType.adjust,
      quantity: _newTotal,
      note: note.isEmpty ? null : note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final differenceColor = _difference == 0
        ? const Color(0xFF5D7FA6)
        : AppColors.primary;

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
            AppToast.success(context, 'Inventory adjusted.');
            Navigator.of(context).maybePop(true);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: CustomAppBar(title: "Adjust Inventory"),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryIconButton(
                    text: 'Update Inventory Count',
                    isLoading: state.isSubmitting,
                    isEnabled: !state.isSubmitting,
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New total after adjustment: ${_formatQuantity(_newTotal)} ${widget.item.unit.toLowerCase()}',
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
                _ItemSummaryCard(item: widget.item),
                24.height,
                const InventorySectionHeader('Adjustment Details'),
                16.height,
                _FieldLabel('New Total Quantity'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onPressed: () => _step(-1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: AppFonts.bold(
                          fontSize: 18,
                          color: AppColors.black,
                        ),
                        decoration: inventoryInputDecoration(hintText: '0'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onPressed: () => _step(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF8AA4C2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Difference: ',
                      style: AppFonts.regular(
                        fontSize: 12,
                        color: AppColors.greyBlue,
                      ),
                    ),
                    Text(
                      '${_difference > 0 ? '+' : ''}${_formatQuantity(_difference)} units',
                      style: AppFonts.bold(
                        fontSize: 12,
                        color: differenceColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _difference == 0 ? '(No change)' : '',
                      style: AppFonts.regular(
                        fontSize: 12,
                        color: AppColors.greyBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     const _FieldLabel('Reason for Adjustment'),
                //     Text(
                //       '*Required',
                //       style: AppFonts.medium(
                //         fontSize: 10,
                //         color: AppColors.error,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 4),
                // CustomDropdownField<String>(
                //   value: _reason,
                //   items: _reasons,
                //   hint: 'Select a reason...',
                //   labelBuilder: (reason) => reason,
                //   onChanged: (value) => setState(() => _reason = value),
                //   icon: const Icon(
                //     Icons.keyboard_arrow_down_rounded,
                //     color: AppColors.greyBlue,
                //   ),
                //   decoration: inventoryInputDecoration(
                //     hintText: 'Select a reason...',
                //   ),
                // ),
                // const SizedBox(height: 16),
                const _FieldLabel('Note'),
                const SizedBox(height: 4),
                CustomTextField(
                  controller: _notesController,
                  maxLines: 6,
                  hintText: 'Provide more context for this change...',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ItemSummaryCard extends StatelessWidget {
  const _ItemSummaryCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
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
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.bold(fontSize: 16, color: AppColors.black),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.greyBlue,
                    ),
                    children: [
                      const TextSpan(text: 'Current: '),
                      TextSpan(
                        text:
                            '${_formatQuantity(item.onHand)} ${item.unit.toLowerCase()}',
                        style: AppFonts.bold(
                          fontSize: 12,
                          color: AppColors.black,
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
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
        ),
        child: Icon(icon, size: 22),
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
