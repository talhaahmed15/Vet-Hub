import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/navigation/page_transition.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/clinic_root.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_summary_screen.dart';
import 'package:clinic_management_app/services/invoice_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final InvoiceDraft? draft;
  final InvoiceListItem? invoice;

  const InvoiceDetailsScreen({super.key, this.draft, this.invoice});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  bool _itemsLoading = false;
  List<InvoiceLineItem> _loadedItems = const [];

  @override
  void initState() {
    super.initState();
    if (widget.draft == null && widget.invoice != null) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _itemsLoading = true);
    try {
      final items = await InvoiceService().fetchInvoiceItems(
        widget.invoice!.id,
      );
      if (!mounted) return;
      setState(() => _loadedItems = items);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Failed to load invoice items.');
      }
    } finally {
      if (mounted) setState(() => _itemsLoading = false);
    }
  }

  Future<void> _shareInvoice() async {
    final invoiceNumber =
        widget.draft?.invoiceNumber ?? widget.invoice?.invoiceNumber ?? 'INV';
    final clientName = widget.draft?.clientName.isNotEmpty == true
        ? widget.draft!.clientName
        : (widget.invoice?.clientName ?? '');
    final clientPhone = widget.draft?.clientPhone.isNotEmpty == true
        ? widget.draft!.clientPhone
        : (widget.invoice?.clientPhone ?? '');
    final dateLabel = widget.draft != null
        ? DateFormat('MMMM d, yyyy').format(DateTime.now())
        : DateFormat(
            'MMMM d, yyyy',
          ).format(widget.invoice?.createdAt ?? DateTime.now());
    final total = widget.draft?.total ?? widget.invoice?.total ?? 0;

    final items = <InvoiceLineItem>[
      if (widget.draft?.consultationEnabled == true)
        InvoiceLineItem(
          id: 'consultation',
          name: 'Consultation Fee',
          type: InvoiceLineItemType.service,
          quantity: widget.draft!.consultationQty,
          unitPrice: widget.draft!.consultationPrice,
        ),
      ...?widget.draft?.items,
      if (widget.draft == null) ..._loadedItems,
    ];

    if (items.isEmpty) {
      AppToast.error(context, 'No line items to share.');
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice #$invoiceNumber',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Issued on $dateLabel'),
              if (clientName.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text(clientName),
              ],
              if (clientPhone.isNotEmpty) pw.Text(clientPhone),
              pw.SizedBox(height: 16),
              pw.Text(
                'Line Items',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              ...items.map(
                (item) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text(item.name)),
                      pw.Text(
                        '${item.quantity} x ${_formatMoney(item.unitPrice)}',
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(_formatMoney(item.total)),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(
                    _formatMoney(total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'invoice-$invoiceNumber.pdf',
        subject: 'Invoice $invoiceNumber',
      );
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Unable to share invoice.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : AppColors.lightGrey;
    final date = widget.draft != null
        ? DateFormat('MMMM d, yyyy').format(DateTime.now())
        : DateFormat(
            'MMMM d, yyyy',
          ).format(widget.invoice?.createdAt ?? DateTime.now());
    final clientName = widget.draft?.clientName.isNotEmpty == true
        ? widget.draft!.clientName
        : (widget.invoice?.clientName ?? '');
    final clientPhone = widget.draft?.clientPhone.isNotEmpty == true
        ? widget.draft!.clientPhone
        : (widget.invoice?.clientPhone ?? '');
    final petName = widget.draft?.petName.isNotEmpty == true
        ? widget.draft!.petName
        : (widget.invoice?.petName ?? '');
    final hasPet = petName.isNotEmpty;
    final editableInvoiceId =
        widget.draft?.invoiceId.isNotEmpty == true
            ? widget.draft!.invoiceId
            : (widget.invoice?.id ?? '');

    Future<void> goToDashboard() async {
      await Navigator.of(context).pushAndRemoveUntil(
        AppPageTransition.build(
          const ClinicRootScreen(initialIndex: 0),
          type: PageTransitionType.cupertino,
        ),
        (route) => false,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          return true;
        }
        await goToDashboard();
        return false;
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: CustomAppBar(
          title: "Invoice Details",
          onBackPressed: () {
            if (Navigator.of(context).canPop()) {
              NavigatorHelper.pop(context);
              return;
            }
            goToDashboard();
          },
          trailing: editableInvoiceId.isNotEmpty
              ? PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      NavigatorHelper.push(
                        context,
                        InvoiceSummaryScreen(invoiceId: editableInvoiceId),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Invoice'),
                    ),
                  ],
                )
              : null,
        ),
        body: ListView(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #${widget.draft?.invoiceNumber ?? widget.invoice?.invoiceNumber ?? 'INV-000'}',
                    style: AppFonts.bold(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issued on $date',
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  if (clientName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(clientName, style: AppFonts.semiBold(fontSize: 13)),
                  ],
                  if (clientPhone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          clientPhone,
                          style: AppFonts.regular(
                            fontSize: 12,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (hasPet) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.pets, size: 14, color: AppColors.grey),
                        const SizedBox(width: 4),
                        Text(
                          petName,
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader('Line Items'),
                  const SizedBox(height: 8),
                  if (widget.draft != null) ...[
                    if (widget.draft!.consultationEnabled)
                      _LineItemRow(
                        title: 'Consultation Fee',
                        subtitle: 'Service Fee',
                        amount: widget.draft!.consultationTotal,
                      ),
                    for (final item in widget.draft!.items)
                      _LineItemRow(
                        title: item.name,
                        subtitle: item.type == InvoiceLineItemType.product
                            ? '${item.quantity}x - ${item.unitLabel ?? ''}'
                            : 'Service Fee',
                        amount: item.total,
                      ),
                  ] else if (_itemsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_loadedItems.isNotEmpty)
                    Column(
                      children: _loadedItems
                          .map(
                            (item) => _LineItemRow(
                              title: item.name,
                              subtitle: item.type == InvoiceLineItemType.product
                                  ? '${item.quantity}x'
                                  : 'Service Fee',
                              amount: item.total,
                            ),
                          )
                          .toList(),
                    )
                  else
                    _LineItemRow(
                      title: 'Invoice details unavailable',
                      subtitle: '- ',
                      amount: widget.invoice?.total ?? 0,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: _TotalsCard(draft: widget.draft, invoice: widget.invoice),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader('Payment Details'),
                  const SizedBox(height: 8),
                  _PaymentDetails(invoice: widget.invoice, draft: widget.draft),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            widget.draft == null && _itemsLoading
                ? null
                : Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.divider)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrimaryIconButton(
                          text: 'Share',
                          icon: Icons.ios_share,
                          onPressed: _shareInvoice,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => goToDashboard(),
                          child: Text(
                            'Return to Dashboard',
                            style: AppFonts.regular(
                              fontSize: 14,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppFonts.semiBold(
        fontSize: 12,
        color: AppColors.darkGrey,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;

  const _LineItemRow({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),

      child: Row(
        children: [
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
          Text(_formatMoney(amount), style: AppFonts.semiBold(fontSize: 14)),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final InvoiceDraft? draft;
  final InvoiceListItem? invoice;

  const _TotalsCard({required this.draft, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final subtotal = draft?.subtotal ?? invoice?.total ?? 0;
    final total = draft?.total ?? invoice?.total ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Total Amount', style: AppFonts.bold(fontSize: 14)),
            ),
            Text(
              _formatMoney(total),
              style: AppFonts.bold(fontSize: 16, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  final InvoiceDraft? draft;
  final InvoiceListItem? invoice;

  const _PaymentDetails({required this.draft, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final method = draft?.paymentMethod ?? invoice?.paymentMethod;
    final label = method == InvoicePaymentMethod.card
        ? 'Card payment'
        : 'Cash payment';
    final detail = method == InvoicePaymentMethod.card
        ? 'Authorized: ${DateFormat('MMM d, h:mm a').format(DateTime.now())}'
        : 'Received in full';

    return Container(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              method == InvoicePaymentMethod.card
                  ? Icons.credit_card
                  : Icons.payments_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppFonts.semiBold(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: AppFonts.regular(
                    fontSize: 12,
                    color: AppColors.darkGrey,
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

String _formatMoney(double value) {
  return NumberFormat.currency(symbol: '\$').format(value);
}
