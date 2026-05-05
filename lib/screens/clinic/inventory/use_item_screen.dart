import 'package:clinic_management_app/bloc/inventory_bloc/inventory_txn_cubit.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/inventory_txn_state.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UseItemScreen extends StatefulWidget {
  const UseItemScreen({super.key, required this.item});

  final Item item;

  @override
  State<UseItemScreen> createState() => _UseItemScreenState();
}

class _UseItemScreenState extends State<UseItemScreen> {
  late final TextEditingController _quantityController;
  final _notesController = TextEditingController();

  static const _quickQuantities = <int>[1, 5, 10, 25];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _quantity {
    final parsed = double.tryParse(_quantityController.text.trim());
    if (parsed == null || parsed <= 0) return 1;
    return parsed;
  }

  double get _remaining =>
      (widget.item.onHand - _quantity).clamp(0, double.infinity).toDouble();

  void _setQuantity(num value) {
    setState(() {
      _quantityController.text = value.toString();
    });
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
      txnType: InventoryTxnType.use,
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
            AppToast.success(context, 'Usage recorded.');
            Navigator.of(context).maybePop(true);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: CustomAppBar(title: "Use Item"),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryIconButton(
                    text: 'Confirm Usage',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: state.isSubmitting,
                    onPressed: () => _submit(context),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Remaining stock after use: ${_formatQuantity(_remaining)} ${widget.item.unit.toLowerCase()}',
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
                _ItemCard(item: widget.item),
                const SizedBox(height: 16),
                const _FieldLabel('Quantity Used'),
                const SizedBox(height: 4),
                CustomTextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hintText: '1',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _quickQuantities
                      .map((value) {
                        final isSelected =
                            _quantityController.text.trim() == '$value';
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _QuickQuantityChip(
                            value: value,
                            isSelected: isSelected,
                            onTap: () => _setQuantity(value),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 28),
                // Text(
                //   'Link to Record (Optional)',
                //   style: AppFonts.bold(fontSize: 16, color: AppColors.black),
                // ),
                // const SizedBox(height: 14),
                // const _FieldLabel('Search Patient'),
                // const SizedBox(height: 8),
                // CustomTextField(
                //   controller: _patientController,
                //   textInputAction: TextInputAction.next,
                //   prefixIcon: const Icon(
                //     Icons.pets_outlined,
                //     color: AppColors.primary,
                //   ),
                //   hint: 'e.g Luna (Golden Retriever)',
                // ),
                // const SizedBox(height: 12),
                // const _FieldLabel('Select Appointment'),
                // const SizedBox(height: 8),
                // CustomDropdownField<String>(
                //   value: _appointment,
                //   items: _appointments,
                //   hint: 'None selected',
                //   labelBuilder: (appointment) => appointment,
                //   onChanged: (value) => setState(() => _appointment = value),
                //   decoration: inventoryInputDecoration(
                //     hintText: 'None selected',
                //     prefixIcon: const Icon(
                //       Icons.calendar_today_outlined,
                //       color: AppColors.primary,
                //       size: 20,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 18),
                const _FieldLabel('Notes'),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _notesController,
                  maxLines: 6,
                  hintText: 'Add any additional details here...',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: AppFonts.bold(fontSize: 16, color: AppColors.black),
          ),
          const SizedBox(height: 4),
          Text(
            'In Stock: ${_formatQuantity(item.onHand)} units',
            style: AppFonts.medium(fontSize: 12, color: AppColors.greyBlue),
          ),
        ],
      ),
    );
  }
}

class _QuickQuantityChip extends StatelessWidget {
  const _QuickQuantityChip({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFD6E2F3),
            width: 1,
          ),
        ),
        child: Text(
          '$value',
          style: AppFonts.bold(
            fontSize: 12,
            color: isSelected ? AppColors.white : AppColors.black,
          ),
        ),
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
