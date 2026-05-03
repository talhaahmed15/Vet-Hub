import 'package:clinic_management_app/models/appointment_filters.dart';
import 'package:clinic_management_app/models/appointment_summary.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/appointment/appointment_details_screen.dart';
import 'package:clinic_management_app/screens/clinic/appointment/filter_appointments_screen.dart';
import 'package:clinic_management_app/screens/clinic/appointment/new_appointment_screen.dart';
import 'package:clinic_management_app/services/appointment_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentAppointmentsScreen extends StatefulWidget {
  const RecentAppointmentsScreen({super.key});

  @override
  State<RecentAppointmentsScreen> createState() =>
      _RecentAppointmentsScreenState();
}

class _RecentAppointmentsScreenState extends State<RecentAppointmentsScreen> {
  late Future<List<AppointmentSummary>> _future;
  final AppointmentService _appointmentService = AppointmentService();
  AppointmentFilters _filters = const AppointmentFilters();
  _QuickRange? _quickRange;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigatorHelper.push(context, NewAppointmentScreen());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: AppColors.lightGrey,
          child: Column(
            children: [
              _TopHeader(
                onOpenFilters: () {
                  _openFilters();
                },
                quickRange: _quickRange,
                onQuickRangeSelected: (range) {
                  if (range == _QuickRange.custom) {
                    _openFilters();
                    return;
                  }
                  _setQuickRange(range);
                },
              ),
              Expanded(
                child: FutureBuilder<List<AppointmentSummary>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return _EmptyState(
                        title: 'Unable to load appointments',
                        subtitle: snapshot.error.toString(),
                        actionText: 'Retry',
                        onAction: () {
                          _loadAppointments();
                        },
                      );
                    }

                    final appointments = snapshot.data ?? const [];
                    if (appointments.isEmpty) {
                      return _EmptyState(
                        title: 'No appointments yet',
                        subtitle: 'Schedule a visit to see it listed here.',
                      );
                    }

                    final grouped = _groupByDay(appointments);
                    final sections = grouped.entries
                        .map((entry) {
                          final label = _sectionTitle(entry.key);
                          final rows = entry.value
                              .map(_rowFromAppointment)
                              .toList(growable: false);
                          return _Section(title: label, children: rows);
                        })
                        .toList(growable: false);

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: sections,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<AppointmentSummary>> _groupByDay(
    List<AppointmentSummary> appointments,
  ) {
    final Map<DateTime, List<AppointmentSummary>> grouped = {};
    for (final appt in appointments) {
      final created = appt.createdAt;
      final key = DateTime(created.year, created.month, created.day);
      grouped.putIfAbsent(key, () => []).add(appt);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sorted = <DateTime, List<AppointmentSummary>>{};
    for (final key in sortedKeys) {
      final items = grouped[key] ?? [];
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      sorted[key] = items;
    }
    return sorted;
  }

  String _sectionTitle(DateTime date) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final yesterdayKey = todayKey.subtract(const Duration(days: 1));
    final dateLabel = DateFormat('MMM d').format(date);

    if (date == todayKey) {
      return 'Today';
    }
    if (date == yesterdayKey) {
      return 'Yesterday, $dateLabel';
    }
    return DateFormat('EEEE, MMM d').format(date);
  }

  _AppointmentRowData _rowFromAppointment(AppointmentSummary appt) {
    final timeLabel = DateFormat('h:mm a').format(appt.createdAt);
    return _AppointmentRowData(
      petName: appt.petName.isEmpty ? 'Pet' : appt.petName,
      ownerName: appt.ownerName.isEmpty ? 'Pet Owner' : appt.ownerName,
      timeLabel: timeLabel,
      status: _ApptStatus.completed,
      avatarEmoji: _emojiForSpecies(appt.petSpecies),
      appointment: appt,
    );
  }

  void _loadAppointments() {
    setState(() {
      _future = _appointmentService.fetchRecentAppointments(
        startDate: _filters.startDate,
        endDate: _filters.endDate,
        species: _filters.species,
        billingStatus: _filters.billingStatus,
        veterinarianId: _filters.veterinarianId,
      );
    });
  }

  Future<void> _openFilters() async {
    final result = await NavigatorHelper.push<AppointmentFilters>(
      context,
      FilterAppointmentsScreen(initialFilters: _filters),
    );
    if (result == null) return;
    setState(() {
      _filters = result;
      _quickRange = _inferQuickRange(result);
    });
    _loadAppointments();
  }

  _QuickRange? _inferQuickRange(AppointmentFilters filters) {
    if (!filters.hasDateRange) return null;
    final start = DateTime(
      filters.startDate!.year,
      filters.startDate!.month,
      filters.startDate!.day,
    );
    final end = DateTime(
      filters.endDate!.year,
      filters.endDate!.month,
      filters.endDate!.day,
    );
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    if (end != todayKey) return _QuickRange.custom;

    final diff = todayKey.difference(start).inDays;
    if (diff == 2) return _QuickRange.last3Days;
    if (diff == 6) return _QuickRange.lastWeek;
    return _QuickRange.custom;
  }

  void _setQuickRange(_QuickRange range) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    DateTime start;
    if (range == _QuickRange.last3Days) {
      start = todayKey.subtract(const Duration(days: 2));
    } else if (range == _QuickRange.lastWeek) {
      start = todayKey.subtract(const Duration(days: 6));
    } else {
      start = todayKey;
    }

    setState(() {
      _quickRange = range;
      _filters = _filters.copyWith(startDate: start, endDate: todayKey);
    });
    _loadAppointments();
  }
}

class _TopHeader extends StatelessWidget {
  final VoidCallback onOpenFilters;
  final _QuickRange? quickRange;
  final ValueChanged<_QuickRange> onQuickRangeSelected;

  const _TopHeader({
    required this.onOpenFilters,
    required this.quickRange,
    required this.onQuickRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF101922) : AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Appointments',
                  style: AppFonts.bold(
                    fontSize: 22,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
              IconButton(
                onPressed: onOpenFilters,
                icon: Icon(
                  Icons.tune,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SearchField(),
          const SizedBox(height: 12),
          _ChipsRow(selected: quickRange, onSelected: onQuickRangeSelected),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2430) : const Color(0xFFF0F2F5);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bg,
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
              'Search appointments',
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

class _ChipsRow extends StatelessWidget {
  final _QuickRange? selected;
  final ValueChanged<_QuickRange> onSelected;

  const _ChipsRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget chip({
      required bool selected,
      required IconData icon,
      required String label,
      required _QuickRange choice,
    }) {
      final bg = selected
          ? AppColors.primary
          : (isDark ? const Color(0xFF1A2430) : const Color(0xFFF0F2F5));
      final fg = selected
          ? AppColors.white
          : (isDark ? AppColors.white : AppColors.black);

      return InkWell(
        onTap: () => onSelected(choice),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? null
                : Border.all(
                    color: isDark
                        ? const Color(0xFF2A3A4C)
                        : const Color(0xFFE3E6EA),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label, style: AppFonts.semiBold(fontSize: 12, color: fg)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            selected: selected == _QuickRange.last3Days,
            icon: Icons.calendar_today,
            label: 'Last 3 Days',
            choice: _QuickRange.last3Days,
          ),
          const SizedBox(width: 8),
          chip(
            selected: selected == _QuickRange.lastWeek,
            icon: Icons.calendar_view_week,
            label: 'Last Week',
            choice: _QuickRange.lastWeek,
          ),
          const SizedBox(width: 8),
          chip(
            selected: selected == _QuickRange.custom,
            icon: Icons.event,
            label: 'Custom Date',
            choice: _QuickRange.custom,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_AppointmentRowData> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: AppFonts.bold(
              fontSize: 16,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
        ),
        ...children.map((e) => _AppointmentRow(data: e)),
      ],
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final _AppointmentRowData data;
  const _AppointmentRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark ? const Color(0xFF101922) : AppColors.white;

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: () {
          NavigatorHelper.push(
            context,
            AppointmentDetailsScreen(appointmentId: data.appointment.id),
          );
        },
        splashColor: AppColors.primary.withOpacity(0.15),
        highlightColor: AppColors.primary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _AvatarCircle(emoji: data.avatarEmoji),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.petName,
                      style: AppFonts.semiBold(
                        fontSize: 16,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pet owner: ${data.ownerName}',
                      style: AppFonts.regular(
                        fontSize: 12,
                        color: isDark ? AppColors.grey : AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (data.status == _ApptStatus.completed)
                    Text(
                      'Completed',
                      style: AppFonts.bold(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    data.timeLabel,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String emoji;
  const _AvatarCircle({required this.emoji});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      width: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1A2430) : const Color(0xFFF0F2F5),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3A4C) : const Color(0xFFE3E6EA),
        ),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note,
              size: 48,
              color: isDark ? AppColors.grey : AppColors.darkGrey,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppFonts.bold(
                fontSize: 18,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppFonts.regular(
                fontSize: 12,
                color: isDark ? AppColors.grey : AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ApptStatus { completed, none }

class _AppointmentRowData {
  final String petName;
  final String ownerName;
  final String timeLabel;
  final _ApptStatus status;
  final String avatarEmoji;
  final AppointmentSummary appointment;

  const _AppointmentRowData({
    required this.petName,
    required this.ownerName,
    required this.timeLabel,
    required this.status,
    required this.avatarEmoji,
    required this.appointment,
  });
}

enum _QuickRange { last3Days, lastWeek, custom }

String _emojiForSpecies(String species) {
  final normalized = species.toLowerCase();
  if (normalized.contains('dog')) {
    return '\u{1F436}';
  }
  if (normalized.contains('cat')) {
    return '\u{1F431}';
  }
  if (normalized.contains('bird')) {
    return '\u{1F426}';
  }
  if (normalized.contains('rabbit')) {
    return '\u{1F430}';
  }
  return '\u{1F43E}';
}
