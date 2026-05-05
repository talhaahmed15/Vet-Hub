import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/bloc/invoice/invoice_state.dart';
import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_details_screen.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_summary_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InvoiceCubit>().loadInvoices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final cubit = context.read<InvoiceCubit>();
          cubit.startNewInvoice();
          NavigatorHelper.push(context, const InvoiceSummaryScreen());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: PageContent(
        maxWidth: 1200,
        fillHeight: true,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
            _Header(isDark: isDark),
            Expanded(
              child: BlocBuilder<InvoiceCubit, InvoiceState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null) {
                    return _EmptyState(
                      title: 'Unable to load invoices',
                      subtitle: state.error!,
                      actionText: 'Retry',
                      onAction: () => context.read<InvoiceCubit>().loadInvoices(),
                    );
                  }

                  final invoices = state.invoices;
                  if (invoices.isEmpty) {
                    return _EmptyState(
                      title: 'No invoices yet',
                      subtitle: 'Create a new invoice to get started.',
                      actionText: 'New Invoice',
                      onAction: () {
                        final cubit = context.read<InvoiceCubit>();
                        cubit.startNewInvoice();
                        NavigatorHelper.push(
                          context,
                          const InvoiceSummaryScreen(),
                        );
                      },
                    );
                  }

                  return _InvoiceList(invoices: invoices);
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDark;

  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Invoices',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                Icons.more_horiz,
                color: isDark ? AppColors.grey : AppColors.darkGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SearchBar(isDark: isDark),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool isDark;

  const _SearchBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2430) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 20,
            color: isDark ? AppColors.grey : AppColors.darkGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search invoice or pet owner...',
              style: AppFonts.regular(
                fontSize: 14,
                color: isDark ? AppColors.grey : AppColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<InvoiceListItem> invoices;

  const _InvoiceList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(child: Text('No invoices'));
    }

    final grouped = <DateTime, List<InvoiceListItem>>{};
    for (final invoice in invoices) {
      final d = invoice.createdAt;
      final key = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(key, () => []).add(invoice);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
      children: [
        for (final day in sortedKeys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              _dayLabel(day),
              style: AppFonts.semiBold(fontSize: 12, color: AppColors.darkGrey),
            ),
          ),
          ...grouped[day]!.map((invoice) => _InvoiceRow(invoice: invoice)),
        ],
      ],
    );
  }

  String _dayLabel(DateTime day) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    if (day == todayKey) {
      return 'TODAY - ${DateFormat('MMM d, yyyy').format(day).toUpperCase()}';
    }
    return DateFormat('MMM d, yyyy').format(day).toUpperCase();
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceListItem invoice;

  const _InvoiceRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a').format(invoice.createdAt);
    final statusLabel = invoice.paymentMethod == InvoicePaymentMethod.cash
        ? 'CASH'
        : 'CREDIT';
    final statusColor = invoice.paymentMethod == InvoicePaymentMethod.cash
        ? AppColors.success
        : AppColors.primary;

    return InkWell(
      onTap: () {
        NavigatorHelper.push(
          context,
          InvoiceDetailsScreen(invoice: invoice),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: AppFonts.semiBold(fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppFonts.semiBold(
                            fontSize: 10,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.clientName.isEmpty
                        ? 'Pet owner'
                        : invoice.clientName,
                    style: AppFonts.regular(fontSize: 13),
                  ),
                  if (invoice.petName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.pets, size: 14, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          invoice.petName,
                          style: AppFonts.regular(
                            fontSize: 12,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatMoney(invoice.total),
                  style: AppFonts.semiBold(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 46, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(title, style: AppFonts.semiBold(fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppFonts.regular(fontSize: 12, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  return NumberFormat.currency(symbol: '\$').format(value);
}
