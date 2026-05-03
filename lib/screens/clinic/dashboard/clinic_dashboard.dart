import 'dart:developer';
import 'dart:ui' as ui;

import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/models/appointment_summary.dart';
import 'package:clinic_management_app/models/client.dart';
import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/models/enums/item_status_enum.dart';
import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/appointment/new_appointment_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/add_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/inventory_screen.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_summary_screen.dart';
import 'package:clinic_management_app/services/appointment_service.dart';
import 'package:clinic_management_app/services/invoice_service.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ClinicDashboardScreen extends StatefulWidget {
  const ClinicDashboardScreen({super.key});

  @override
  State<ClinicDashboardScreen> createState() => _ClinicDashboardScreenState();
}

class _ClinicDashboardScreenState extends State<ClinicDashboardScreen> {
  late Future<Clinic?> _clinicFuture;
  late Future<_DashboardMetrics> _dashboardFuture;

  _DashboardRange _earningsRange = _DashboardRange.today;

  final AppointmentService _appointmentService = AppointmentService();
  final ItemsService _itemsService = ItemsService();
  final InvoiceService _invoiceService = InvoiceService();

  @override
  void initState() {
    super.initState();
    _clinicFuture = _loadClinic();
    _dashboardFuture = _loadDashboardData();
  }

  Future<Clinic?> _loadClinic() async {
    final data = await Storage.getClinicData();
    if (data == null) return null;
    return Clinic.fromMap(data);
  }

  Future<_DashboardMetrics> _loadDashboardData() async {
    final results = await Future.wait([
      _appointmentService.fetchRecentAppointments(limit: 200),
      _appointmentService.fetchClients(),
      _invoiceService.fetchInvoices(),
      _itemsService.fetchItems(limit: 200),
    ]);

    final appointments = results[0] as List<AppointmentSummary>;
    final clients = results[1] as List<Client>;
    final invoices = results[2] as List<InvoiceListItem>;
    final items = results[3] as List<Item>;

    return _DashboardMetrics.fromData(
      appointments: appointments,
      clients: clients,
      invoices: invoices,
      items: items,
    );
  }

  void _reloadDashboard() {
    setState(() {
      _clinicFuture = _loadClinic();
      _dashboardFuture = _loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(clinicFuture: _clinicFuture),
              24.height,
              FutureBuilder<_DashboardMetrics>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _DashboardLoading();
                  }
                  if (snapshot.hasError) {
                    return _DashboardError(onRetry: _reloadDashboard);
                  }

                  final data = snapshot.data ?? const _DashboardMetrics.empty();
                  final earningsSummary = _RevenueSummary.fromData(
                    data: data,
                    range: _earningsRange,
                  );
                  final trendSummary = _TrendSummary.fromData(
                    data: data,
                    range: _DashboardRange.week,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatsRow(
                        left: _StatCardData(
                          title: "TODAY'S APPTS",
                          value: data.todayAppointments.toString(),
                          icon: Icons.calendar_today_outlined,
                        ),
                        right: _StatCardData(
                          title: 'TOTAL APPTS',
                          value: data.totalAppointments.toString(),
                          icon: Icons.event_note_outlined,
                        ),
                      ),
                      12.height,
                      _StatsRow(
                        left: _StatCardData(
                          title: 'TOTAL CUSTOMERS',
                          value: data.totalCustomers.toString(),
                          icon: Icons.group_outlined,
                        ),
                        right: _StatCardData(
                          title: 'LOW STOCK',
                          value: data.lowStockCount.toString(),
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      16.height,
                      _RevenueCard(
                        range: _earningsRange,
                        onRangeChanged: (range) {
                          setState(() => _earningsRange = range);
                        },
                        revenueTotal: earningsSummary.revenue,
                      ),
                      16.height,
                      _AppointmentTrends(
                        totalCount: trendSummary.total,
                        dataPoints: trendSummary.dataPoints,
                        dateLabels: trendSummary.dateLabels,
                      ),
                      24.height,
                      _QuickActions(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Future<Clinic?> clinicFuture;

  const _Header({required this.clinicFuture});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    return FutureBuilder<Clinic?>(
      future: clinicFuture,
      builder: (context, snapshot) {
        final clinic = snapshot.data;
        final clinicName = clinic?.clinicName?.trim();
        final displayName = clinicName != null && clinicName.isNotEmpty
            ? clinicName
            : 'Vet Clinic';
        final logoUrl = clinic?.logoUrl?.trim();
        final hasRemoteLogo =
            logoUrl != null &&
            logoUrl.isNotEmpty &&
            (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'));

        return Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: hasRemoteLogo
                  ? ClipOval(
                      child: Image.network(
                        logoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, error) {
                          log('Logo load error: $error');
                          return const Icon(
                            Icons.pets,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.pets, color: AppColors.primary),
            ),
            12.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppFonts.semiBold(fontSize: 16)),
                2.height,
                Text(
                  dateLabel,
                  style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DashboardMetrics {
  final List<AppointmentSummary> appointments;
  final List<InvoiceListItem> invoices;
  final int todayAppointments;
  final int totalAppointments;
  final int totalCustomers;
  final int lowStockCount;

  const _DashboardMetrics({
    required this.appointments,
    required this.invoices,
    required this.todayAppointments,
    required this.totalAppointments,
    required this.totalCustomers,
    required this.lowStockCount,
  });

  const _DashboardMetrics.empty()
    : appointments = const [],
      invoices = const [],
      todayAppointments = 0,
      totalAppointments = 0,
      totalCustomers = 0,
      lowStockCount = 0;

  factory _DashboardMetrics.fromData({
    required List<AppointmentSummary> appointments,
    required List<Client> clients,
    required List<InvoiceListItem> invoices,
    required List<Item> items,
  }) {
    final today = _dayKey(DateTime.now());
    final todayAppointments = _countAppointmentsForDay(appointments, today);

    final lowStockCount = items.where((item) {
      final status = statusFor(item.onHand, minThresholdFor(item.category));
      return status == InventoryStatus.lowStock ||
          status == InventoryStatus.outOfStock;
    }).length;

    return _DashboardMetrics(
      appointments: appointments,
      invoices: invoices,
      todayAppointments: todayAppointments,
      totalAppointments: appointments.length,
      totalCustomers: clients.length,
      lowStockCount: lowStockCount,
    );
  }
}

DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

int _countAppointmentsForDay(
  List<AppointmentSummary> appointments,
  DateTime day,
) {
  return appointments.where((appt) => _dayKey(appt.createdAt) == day).length;
}

int _countAppointmentsInRange(
  List<AppointmentSummary> appointments, {
  required DateTime start,
  required DateTime end,
}) {
  return appointments.where((appt) {
    final key = _dayKey(appt.createdAt);
    return (key.isAtSameMomentAs(start) || key.isAfter(start)) &&
        (key.isAtSameMomentAs(end) || key.isBefore(end));
  }).length;
}

double _sumInvoicesInRange(
  List<InvoiceListItem> invoices, {
  required DateTime start,
  required DateTime end,
}) {
  return invoices
      .where((invoice) {
        final key = _dayKey(invoice.createdAt);
        return (key.isAtSameMomentAs(start) || key.isAfter(start)) &&
            (key.isAtSameMomentAs(end) || key.isBefore(end));
      })
      .fold(0, (sum, invoice) => sum + invoice.total);
}

List<int> _buildRangeCounts(
  List<AppointmentSummary> appointments,
  DateTime start,
  DateTime end,
) {
  final totalDays = end.difference(start).inDays + 1;
  return List<int>.generate(totalDays, (index) {
    final day = start.add(Duration(days: index));
    return _countAppointmentsForDay(appointments, day);
  });
}

List<String> _buildRangeLabels(
  DateTime start,
  DateTime end,
  _DashboardRange range,
) {
  final totalDays = end.difference(start).inDays + 1;
  final format = DateFormat('MMM d');
  if (totalDays <= 1) {
    return [format.format(start)];
  }

  final labels = <String>[];
  for (int i = 0; i < totalDays; i += 1) {
    final day = start.add(Duration(days: i));
    if (range == _DashboardRange.month) {
      if (i == 0 || i == totalDays - 1 || i % 7 == 0) {
        labels.add(format.format(day));
      } else {
        labels.add('');
      }
    } else if (range == _DashboardRange.week) {
      labels.add(DateFormat('EEE').format(day));
    } else {
      labels.add(format.format(day));
    }
  }
  return labels;
}

class _RevenueSummary {
  final double revenue;

  const _RevenueSummary({required this.revenue});

  factory _RevenueSummary.fromData({
    required _DashboardMetrics data,
    required _DashboardRange range,
  }) {
    final today = _dayKey(DateTime.now());
    final span = _rangeSpanDays(range);
    final rangeStart = today.subtract(Duration(days: span - 1));
    final current = _sumInvoicesInRange(
      data.invoices,
      start: rangeStart,
      end: today,
    );

    return _RevenueSummary(revenue: current);
  }
}

class _TrendSummary {
  final int total;
  final List<int> dataPoints;
  final List<String> dateLabels;

  const _TrendSummary({
    required this.total,
    required this.dataPoints,
    required this.dateLabels,
  });

  factory _TrendSummary.fromData({
    required _DashboardMetrics data,
    required _DashboardRange range,
  }) {
    final today = _dayKey(DateTime.now());
    final span = _rangeSpanDays(range);
    final start = today.subtract(Duration(days: span - 1));
    final points = _buildRangeCounts(data.appointments, start, today);
    final labels = _buildRangeLabels(start, today, range);
    final total = points.fold(0, (sum, value) => sum + value);

    return _TrendSummary(total: total, dataPoints: points, dateLabels: labels);
  }
}

enum _DashboardRange { today, week, month }

String _rangeLabel(_DashboardRange range) {
  return switch (range) {
    _DashboardRange.today => 'Today',
    _DashboardRange.week => 'Week',
    _DashboardRange.month => 'Month',
  };
}

int _rangeSpanDays(_DashboardRange range) {
  return switch (range) {
    _DashboardRange.today => 1,
    _DashboardRange.week => 7,
    _DashboardRange.month => 30,
  };
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Text(
            'Unable to load dashboard data.',
            style: AppFonts.semiBold(fontSize: 14),
          ),
          8.height,
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _StatCardData left;
  final _StatCardData right;

  const _StatsRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(data: left)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(data: right)),
      ],
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: AppColors.primary, size: 18),
              8.width,
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.regular(fontSize: 11),
                ),
              ),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(data.value, style: AppFonts.bold(fontSize: 22)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final _DashboardRange range;
  final ValueChanged<_DashboardRange> onRangeChanged;
  final double revenueTotal;

  const _RevenueCard({
    required this.range,
    required this.onRangeChanged,
    required this.revenueTotal,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: AppColors.primary),
              8.width,
              Text('INVOICE EARNINGS', style: AppFonts.regular(fontSize: 11)),
              const Spacer(),
              _RangeSelector(selected: range, onSelected: onRangeChanged),
            ],
          ),
          16.height,
          Text(
            NumberFormat.currency(symbol: '\$').format(revenueTotal),
            style: AppFonts.bold(fontSize: 28),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTrends extends StatelessWidget {
  final int totalCount;
  final List<int> dataPoints;
  final List<String> dateLabels;

  const _AppointmentTrends({
    required this.totalCount,
    required this.dataPoints,
    required this.dateLabels,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Appointment Trends',
                style: AppFonts.semiBold(fontSize: 16),
              ),
            ],
          ),
          16.height,
          Text('$totalCount Total', style: AppFonts.bold(fontSize: 22)),
          24.height,
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _BarChartPainter(dataPoints, dateLabels),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> points;
  final List<String> labels;

  _BarChartPainter(this.points, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    final safePoints = points.isEmpty ? const [0] : points;
    final maxValue = safePoints.reduce((a, b) => a > b ? a : b);
    final height = size.height;
    final width = size.width;
    final barCount = safePoints.length;
    final topLabelHeight = 14.0;
    final bottomLabelHeight = 14.0;
    final chartHeight = (height - topLabelHeight - bottomLabelHeight - 6).clamp(
      20.0,
      height,
    );
    final gap = barCount > 1 ? width * 0.06 : width * 0.2;
    final totalGap = gap * (barCount - 1);
    final barWidth = barCount > 0
        ? ((width - totalGap) / barCount).clamp(6.0, 20.0)
        : width;
    final startX = barCount > 0
        ? (width - (barWidth * barCount + totalGap)) / 2
        : 0.0;

    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i += 1) {
      final value = safePoints[i].toDouble();
      final normalized = maxValue == 0 ? 0 : (value / maxValue);
      final barHeight = (normalized * chartHeight).clamp(2.0, chartHeight);
      final x = startX + i * (barWidth + gap);
      final y = topLabelHeight + (chartHeight - barHeight);
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);

      final countPainter = TextPainter(
        text: TextSpan(
          text: value.toInt().toString(),
          style: AppFonts.regular(fontSize: 10, color: AppColors.grey),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 1,
      )..layout(maxWidth: barWidth + 8);
      final countX = x + (barWidth - countPainter.width) / 2;
      countPainter.paint(canvas, Offset(countX, 0));

      final labelText = i < labels.length ? labels[i] : '';
      if (labelText.isNotEmpty) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: AppFonts.regular(fontSize: 10, color: AppColors.grey),
          ),
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 1,
        )..layout(maxWidth: barWidth + 12);
        final labelX = x + (barWidth - labelPainter.width) / 2;
        final labelY = topLabelHeight + chartHeight + 4;
        labelPainter.paint(canvas, Offset(labelX, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RangeSelector extends StatelessWidget {
  final _DashboardRange selected;
  final ValueChanged<_DashboardRange> onSelected;

  const _RangeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_DashboardRange>(
      onSelected: onSelected,
      splashRadius: 18,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => _DashboardRange.values
          .map(
            (range) => PopupMenuItem<_DashboardRange>(
              value: range,
              height: 36,
              child: Text(_rangeLabel(range), style: AppFonts.regular()),
            ),
          )
          .toList(growable: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _rangeLabel(selected),
              style: AppFonts.regular(fontSize: 12, color: AppColors.primary),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppFonts.semiBold(fontSize: 18)),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionItem(
              icon: Icons.calendar_today,
              label: 'Add Appt',
              primary: true,
              onTap: () {
                NavigatorHelper.push(context, NewAppointmentScreen());
              },
            ),
            _ActionItem(
              icon: Icons.receipt_long,
              label: 'New Invoice',
              onTap: () {
                context.read<InvoiceCubit>().startNewInvoice();
                NavigatorHelper.push(context, const InvoiceSummaryScreen());
              },
            ),
            _ActionItem(
              icon: Icons.add_box_outlined,
              label: 'Add Item',
              onTap: () {
                NavigatorHelper.push(context, const AddItemScreen());
              },
            ),
            _ActionItem(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              onTap: () {
                NavigatorHelper.push(context, const InventoryListScreen());
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary ? AppColors.primary : AppColors.white,
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(
              icon,
              color: primary ? AppColors.white : AppColors.black,
            ),
          ),
        ),
        8.height,
        Text(label, style: AppFonts.regular(fontSize: 12)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }
}
