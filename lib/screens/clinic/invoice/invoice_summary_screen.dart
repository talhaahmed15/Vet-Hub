import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/bloc/invoice/invoice_state.dart';
import 'package:clinic_management_app/models/client.dart';
import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/invoice/add_product_screen.dart';
import 'package:clinic_management_app/screens/clinic/invoice/add_service_screen.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_details_screen.dart';
import 'package:clinic_management_app/services/appointment_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:clinic_management_app/widgets/search_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class InvoiceSummaryScreen extends StatefulWidget {
  final String? appointmentId;
  final String? invoiceId;

  const InvoiceSummaryScreen({super.key, this.appointmentId, this.invoiceId});

  @override
  State<InvoiceSummaryScreen> createState() => _InvoiceSummaryScreenState();
}

class _InvoiceSummaryScreenState extends State<InvoiceSummaryScreen> {
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final AppointmentService _appointmentService = AppointmentService();
  final FocusNode _clientFocusNode = FocusNode();
  List<Client> _clients = const [];
  bool _clientsLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoiceId != null && widget.invoiceId!.isNotEmpty) {
      context.read<InvoiceCubit>().loadInvoiceForEdit(widget.invoiceId!);
    } else {
      context.read<InvoiceCubit>().startNewInvoice(
        appointmentId: widget.appointmentId,
      );
    }
    _loadClients();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : AppColors.lightGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(title: "Invoice Summary"),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final draft = state.draft;
          if (_clientNameController.text != draft.clientName) {
            _clientNameController.text = draft.clientName;
            _clientNameController.selection = TextSelection.fromPosition(
              TextPosition(offset: _clientNameController.text.length),
            );
          }
          if (_clientPhoneController.text != draft.clientPhone) {
            _clientPhoneController.text = draft.clientPhone;
            _clientPhoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: _clientPhoneController.text.length),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (draft.appointmentId == null ||
                        draft.appointmentId!.isEmpty) ...[
                      _ClientCard(
                        controller: _clientNameController,
                        phoneController: _clientPhoneController,
                        focusNode: _clientFocusNode,
                        clients: _clients,
                        loading: _clientsLoading,
                        selectedClientId: draft.clientId,
                        selectedClientName: draft.clientName,
                        onSelected: (client) =>
                            context.read<InvoiceCubit>().updateClient(
                              clientId: client.id,
                              clientName: client.fullName,
                              clientPhone: client.phone ?? '',
                            ),
                        onQueryChanged: (value) {
                          if (value == draft.clientName &&
                              draft.clientId.isNotEmpty) {
                            return;
                          }
                          context.read<InvoiceCubit>().updateClient(
                            clientId: '',
                            clientName: value,
                            clientPhone: _clientPhoneController.text,
                          );
                        },
                        onPhoneChanged: (value) {
                          context.read<InvoiceCubit>().updateClient(
                            clientId: draft.clientId,
                            clientName: _clientNameController.text,
                            clientPhone: value,
                          );
                        },
                        onClear: () {
                          _clientNameController.clear();
                          _clientPhoneController.clear();
                          context.read<InvoiceCubit>().updateClient(
                            clientId: '',
                            clientName: '',
                            clientPhone: '',
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (draft.hasPet) ...[
                      _PatientCard(
                        draft: draft,
                        showEditProfile:
                            draft.appointmentId == null ||
                            draft.appointmentId!.isEmpty,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SectionTitle(
                        title: 'Services & Products',
                        trailing: Text(
                          '${_lineItemCount(draft)} Items',
                          style: AppFonts.semiBold(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LineItemsList(draft: draft),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _AddButton(
                              icon: Icons.add,
                              label: 'Service',
                              onPressed: () {
                                NavigatorHelper.push(
                                  context,
                                  const AddServiceScreen(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AddButton(
                              icon: Icons.shopping_cart_outlined,
                              label: 'Product',
                              onPressed: () {
                                NavigatorHelper.push(
                                  context,
                                  const AddProductScreen(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _SectionTitle(title: 'Payment Method'),
                          const SizedBox(height: 10),

                          _PaymentToggle(
                            selected: draft.paymentMethod,
                            onChanged: (method) => context
                                .read<InvoiceCubit>()
                                .setPaymentMethod(method),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              _BottomBar(
                total: draft.total,
                isLoading: state.finalizing,
                onConfirm: () async {
                  if (state.finalizing) return;
                  if ((draft.appointmentId == null ||
                          draft.appointmentId!.isEmpty) &&
                      draft.clientId.trim().isEmpty &&
                      draft.clientName.trim().isEmpty) {
                      AppToast.error(
                        context,
                        'Please select or enter a pet owner name before finalizing.',
                      );
                    return;
                  }
                  if (!draft.consultationEnabled && draft.items.isEmpty) {
                    AppToast.error(
                      context,
                      'Please add at least one service or product.',
                    );
                    return;
                  }
                  await context.read<InvoiceCubit>().finalizeInvoice();
                  if (!context.mounted) return;
                  NavigatorHelper.replace(
                    context,
                    InvoiceDetailsScreen(draft: draft),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadClients() async {
    setState(() => _clientsLoading = true);
    try {
      final clients = await _appointmentService.fetchClients();
      if (!mounted) return;
      setState(() => _clients = clients);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to load pet owners.');
    } finally {
      if (mounted) setState(() => _clientsLoading = false);
    }
  }

  int _lineItemCount(InvoiceDraft draft) {
    var count = draft.items.length;
    if (draft.consultationEnabled) {
      count += 1;
    }
    return count;
  }
}

class _PatientCard extends StatelessWidget {
  final InvoiceDraft draft;
  final bool showEditProfile;

  const _PatientCard({required this.draft, required this.showEditProfile});

  @override
  Widget build(BuildContext context) {
    final petName = draft.petName.isEmpty ? 'Patient' : draft.petName;
    final ownerName = draft.clientName.isEmpty ? '-' : draft.clientName;
    final species = draft.petSpecies.isEmpty
        ? ''
        : draft.petSpecies.toUpperCase();
    final petEmoji = _petEmoji(draft.petSpecies);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PATIENT DETAILS',
                  style: AppFonts.semiBold(
                    fontSize: 11,
                    color: AppColors.darkGrey,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(petName, style: AppFonts.bold(fontSize: 20)),
                    const SizedBox(width: 8),
                    if (species.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          species,
                          style: AppFonts.semiBold(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pet owner: $ownerName',
                  style: AppFonts.regular(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
                if (showEditProfile) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.divider),
                      foregroundColor: AppColors.black,
                    ),
                    child: Text(
                      'Edit Profile',
                      style: AppFonts.semiBold(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0C7),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(petEmoji, style: const TextStyle(fontSize: 40)),
          ),
        ],
      ),
    );
  }

  String _petEmoji(String speciesRaw) {
    final species = speciesRaw.trim().toLowerCase();
    if (species.contains('dog') || species.contains('canine')) {
      return '\u{1F436}';
    }
    if (species.contains('cat') || species.contains('feline')) {
      return '\u{1F431}';
    }
    return '\u{1F43E}';
  }
}

class _ClientCard extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController phoneController;
  final FocusNode focusNode;
  final List<Client> clients;
  final bool loading;
  final String selectedClientId;
  final String selectedClientName;
  final ValueChanged<Client> onSelected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onClear;

  const _ClientCard({
    required this.controller,
    required this.phoneController,
    required this.focusNode,
    required this.clients,
    required this.loading,
    required this.selectedClientId,
    required this.selectedClientName,
    required this.onSelected,
    required this.onQueryChanged,
    required this.onPhoneChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = controller.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? clients
        : clients
              .where(
                (client) =>
                    client.fullName.toLowerCase().contains(query) ||
                    (client.phone ?? '').toLowerCase().contains(query),
              )
              .toList(growable: false);
    final showSuggestions =
        !loading && focusNode.hasFocus && filtered.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PET OWNER DETAILS',
            style: AppFonts.semiBold(
              fontSize: 11,
              color: AppColors.darkGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          const SizedBox(height: 4),
          SearchTextField(
            controller: controller,
            focusNode: focusNode,
            hint: 'Search pet owners...',
            enabled: !loading,
            onChanged: onQueryChanged,
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          if (showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121E2A) : AppColors.white,
                border: Border.all(
                  color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final client = filtered[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      client.fullName,
                      style: AppFonts.medium(
                        fontSize: 13,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    subtitle: client.phone == null || client.phone!.isEmpty
                        ? null
                        : Text(
                            client.phone!,
                            style: AppFonts.regular(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.grey
                                  : AppColors.darkGrey,
                            ),
                          ),
                    onTap: () {
                      controller.text = client.fullName;
                      onSelected(client);
                      focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          CustomTextField(
            hintText: 'Pet owner phone (e.g. 555-123-4567)',
            keyboardType: TextInputType.phone,
            onChanged: onPhoneChanged,
            controller: phoneController,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppFonts.semiBold(fontSize: 14))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _LineItemsList extends StatelessWidget {
  final InvoiceDraft draft;

  const _LineItemsList({required this.draft});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (draft.consultationEnabled) {
      items.add(
        _LineItemTile(
          title: 'General Consultation',
          subtitle: 'Service Fee',
          price: draft.consultationTotal,
          onRemove: () =>
              context.read<InvoiceCubit>().toggleConsultation(false),
        ),
      );
    }

    for (final item in draft.items) {
      items.add(
        _LineItemTile(
          title: item.name,
          subtitle: item.type == InvoiceLineItemType.product
              ? 'Product - Qty: ${item.quantity}'
              : 'Service Fee',
          price: item.total,
          onRemove: () => context.read<InvoiceCubit>().removeLineItem(item.id),
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          'No products or services added.',
          style: AppFonts.regular(fontSize: 12, color: AppColors.darkGrey),
        ),
      );
    }

    return Column(children: items);
  }
}

class _LineItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double price;
  final VoidCallback onRemove;

  const _LineItemTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.semiBold(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppFonts.regular(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatMoney(price), style: AppFonts.semiBold(fontSize: 14)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onRemove,
                child: Text(
                  'REMOVE',
                  style: AppFonts.bold(fontSize: 10, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AddButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          splashColor: AppColors.primary.withOpacity(0.2),
          highlightColor: AppColors.primary.withOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppFonts.semiBold(
                    fontSize: 14,
                    color: AppColors.primary,
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

class _PaymentToggle extends StatelessWidget {
  final InvoicePaymentMethod selected;
  final ValueChanged<InvoicePaymentMethod> onChanged;

  const _PaymentToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        _PaymentOption(
          label: 'Cash',
          icon: Icons.payments_outlined,
          selected: selected == InvoicePaymentMethod.cash,
          onTap: () => onChanged(InvoicePaymentMethod.cash),
        ),
        _PaymentOption(
          label: 'Credit Card',
          icon: Icons.credit_card,
          selected: selected == InvoicePaymentMethod.card,
          onTap: () => onChanged(InvoicePaymentMethod.card),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? AppColors.white : AppColors.darkGrey;
    final iconColor = selected ? AppColors.white : AppColors.darkGrey;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: selected ? Border.all(color: AppColors.primary) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.semiBold(fontSize: 13, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final VoidCallback onConfirm;

  const _BottomBar({
    required this.total,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Amount',
                  style: AppFonts.semiBold(fontSize: 14),
                ),
              ),
              Text(
                _formatMoney(total),
                style: AppFonts.bold(fontSize: 18, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PrimaryIconButton(
            text: 'Confirm & Finalize',
            icon: Icons.receipt_long,
            isLoading: isLoading,
            isEnabled: !isLoading,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
  return NumberFormat.currency(symbol: '\$').format(value);
}
