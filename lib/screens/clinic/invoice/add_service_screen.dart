import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/bloc/invoice/invoice_state.dart';
import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  late final TextEditingController _consultationPriceController;

  @override
  void initState() {
    super.initState();
    final draft = context.read<InvoiceCubit>().state.draft;
    _consultationPriceController = TextEditingController(
      text: draft.consultationPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _consultationPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : AppColors.lightGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(title: "Add Service"),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          final draft = state.draft;
          _syncConsultationPrice(draft.consultationPrice);
          final serviceItems = draft.items
              .where((item) => item.type == InvoiceLineItemType.service)
              .toList(growable: false);

          return ListView(
            children: [
              _ConsultationCard(
                enabled: draft.consultationEnabled,
                price: draft.consultationPrice,
                quantity: draft.consultationQty,
                priceController: _consultationPriceController,
                onToggle: (value) =>
                    context.read<InvoiceCubit>().toggleConsultation(value),
                onPriceChanged: (value) =>
                    context.read<InvoiceCubit>().updateConsultationPrice(value),
                onQtyChanged: (value) =>
                    context.read<InvoiceCubit>().updateConsultationQty(value),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ADDED SERVICES',
                  style: AppFonts.semiBold(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final item in serviceItems) ...[
                _ServiceRow(
                  item: item,
                  nameController: _controllerFor(item.id, item.name),
                  priceController: _priceControllerFor(item.id, item.unitPrice),
                  onNameChanged: (value) => context
                      .read<InvoiceCubit>()
                      .updateLineItem(id: item.id, name: value),
                  onPriceChanged: (value) => context
                      .read<InvoiceCubit>()
                      .updateLineItem(id: item.id, unitPrice: value),
                  onRemove: () =>
                      context.read<InvoiceCubit>().removeLineItem(item.id),
                ),
                if (item == serviceItems.last)
                  Container(color: AppColors.white, height: 16),
              ],
              _AddServiceCard(
                onTap: () => context.read<InvoiceCubit>().addService(
                  name: '',
                  unitPrice: 0,
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryFooter(draft: state.draft),
                const SizedBox(height: 10),
                PrimaryIconButton(
                  text: 'Finalize Invoice',
                  icon: Icons.receipt_long,
                  onPressed: () => NavigatorHelper.pop(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TextEditingController _controllerFor(String id, String value) {
    return _nameControllers.putIfAbsent(id, () {
      final controller = TextEditingController(text: value);
      return controller;
    });
  }

  TextEditingController _priceControllerFor(String id, double value) {
    return _priceControllers.putIfAbsent(id, () {
      final controller = TextEditingController(
        text: value == 0 ? '' : value.toStringAsFixed(2),
      );
      return controller;
    });
  }

  void _syncConsultationPrice(double value) {
    final next = value.toStringAsFixed(2);
    if (_consultationPriceController.text != next) {
      _consultationPriceController.text = next;
    }
  }
}

class _ConsultationCard extends StatelessWidget {
  final bool enabled;
  final double price;
  final int quantity;
  final TextEditingController priceController;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<int> onQtyChanged;

  const _ConsultationCard({
    required this.enabled,
    required this.price,
    required this.quantity,
    required this.priceController,
    required this.onToggle,
    required this.onPriceChanged,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STANDARD FEE',
                      style: AppFonts.semiBold(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consultation Fee',
                      style: AppFonts.bold(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Professional advice & review',
                      style: AppFonts.regular(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: AppColors.primary,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hintText: 'Price',
                    keyboardType: TextInputType.number,
                    controller: priceController,
                    onChanged: (value) => onPriceChanged(_parseDouble(value)),
                  ),
                ),
                const SizedBox(width: 12),
                _QtyControl(quantity: quantity, onChanged: onQtyChanged),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final InvoiceLineItem item;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback onRemove;

  const _ServiceRow({
    required this.item,
    required this.nameController,
    required this.priceController,
    required this.onNameChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        // border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: nameController,
                  hintText: 'Service name',
                  onChanged: onNameChanged,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: CustomTextField(
                  controller: priceController,
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => onPriceChanged(_parseDouble(value)),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, color: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddServiceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddServiceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Add New Service',
                style: AppFonts.semiBold(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QtyControl({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onChanged(quantity > 1 ? quantity - 1 : 1),
            icon: const Icon(Icons.remove),
          ),
          Text(quantity.toString(), style: AppFonts.semiBold(fontSize: 14)),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _SummaryFooter extends StatelessWidget {
  final InvoiceDraft draft;

  const _SummaryFooter({required this.draft});

  @override
  Widget build(BuildContext context) {
    final lineSummary = draft.consultationEnabled
        ? 'Consultation + ${draft.items.length} Service'
        : '${draft.items.length} Service';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LINE ITEMS',
                style: AppFonts.semiBold(
                  fontSize: 12,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(lineSummary, style: AppFonts.semiBold(fontSize: 14)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'INVOICE TOTAL',
              style: AppFonts.semiBold(fontSize: 12, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMoney(draft.total),
              style: AppFonts.bold(fontSize: 18, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }
}

double _parseDouble(String input) {
  final cleaned = input.replaceAll('\$', '').trim();
  return double.tryParse(cleaned) ?? 0;
}

String _formatMoney(double value) {
  return NumberFormat.currency(symbol: '\$').format(value);
}
