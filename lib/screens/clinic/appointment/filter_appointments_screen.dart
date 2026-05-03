import 'package:clinic_management_app/models/appointment_filters.dart';
import 'package:clinic_management_app/models/clinic_user.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/services/appointment_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_consts.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_dropdown_field.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterAppointmentsScreen extends StatefulWidget {
  final AppointmentFilters? initialFilters;

  const FilterAppointmentsScreen({super.key, this.initialFilters});

  @override
  State<FilterAppointmentsScreen> createState() =>
      _FilterAppointmentsScreenState();
}

class _FilterAppointmentsScreenState extends State<FilterAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  DateTimeRange? _range;
  String _selectedSpecies = 'All';
  String _billingStatus = 'all';
  String _selectedVetId = 'all';
  List<ClinicUser> _vets = const [];
  bool _vetsLoading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    if (initial != null) {
      if (initial.startDate != null && initial.endDate != null) {
        _range = DateTimeRange(
          start: initial.startDate!,
          end: initial.endDate!,
        );
      }
      if (initial.species != null && initial.species!.isNotEmpty) {
        _selectedSpecies = initial.species!;
      }
      if (initial.billingStatus != null && initial.billingStatus!.isNotEmpty) {
        _billingStatus = initial.billingStatus!;
      }
      if (initial.veterinarianId != null &&
          initial.veterinarianId!.isNotEmpty) {
        _selectedVetId = initial.veterinarianId!;
      }
    }
    _loadVets();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101922) : AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onClose: () => NavigatorHelper.pop(context),
              onReset: _resetFilters,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: AppFonts.bold(
                        fontSize: 16,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select the timeframe for appointments',
                      style: AppFonts.regular(
                        fontSize: 13,
                        color: isDark ? AppColors.grey : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateRangeCard(range: _range, onTap: _pickDateRange),
                    const SizedBox(height: 24),
                    Text(
                      'Veterinarian',
                      style: AppFonts.bold(
                        fontSize: 16,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomDropdownField<String>(
                      items: _vetOptionIds(),
                      value: _selectedVetId,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedVetId = value);
                      },
                      hintText: '',
                      labelBuilder: _vetLabelFor,
                      enabled: !_vetsLoading,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pet Species',
                      style: AppFonts.bold(
                        fontSize: 16,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SpeciesRow(
                      selected: _selectedSpecies,
                      onChanged: (value) =>
                          setState(() => _selectedSpecies = value),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Billing Status',
                      style: AppFonts.bold(
                        fontSize: 16,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BillingSegment(
                      value: _billingStatus,
                      onChanged: (value) =>
                          setState(() => _billingStatus = value),
                    ),
                  ],
                ),
              ),
            ),
            _BottomApply(
              onApply: () {
                NavigatorHelper.pop(
                  context,
                  AppointmentFilters(
                    startDate: _range?.start,
                    endDate: _range?.end,
                    species: _selectedSpecies == 'All'
                        ? null
                        : _selectedSpecies,
                    billingStatus: _billingStatus,
                    veterinarianId:
                        _selectedVetId == 'all' ? null : _selectedVetId,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _range = null;
      _selectedSpecies = 'All';
      _billingStatus = 'all';
      _selectedVetId = 'all';
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Future<void> _loadVets() async {
    setState(() => _vetsLoading = true);
    try {
      final vets = await _appointmentService.fetchClinicUsers();
      if (!mounted) return;
      setState(() {
        _vets = vets;
        if (_selectedVetId != 'all' &&
            !_vets.any((vet) => vet.id == _selectedVetId)) {
          _selectedVetId = 'all';
        }
      });
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to load veterinarians.');
    } finally {
      if (mounted) setState(() => _vetsLoading = false);
    }
  }

  List<String> _vetOptionIds() {
    return <String>[
      'all',
      ..._vets.map((vet) => vet.id),
    ];
  }

  String _vetLabelFor(String id) {
    if (id == 'all') return 'All';
    final vet = _vets.firstWhere(
      (entry) => entry.id == id,
      orElse: () => const ClinicUser(id: '', fullName: 'Veterinarian'),
    );
    return vet.fullName.isEmpty ? 'Veterinarian' : vet.fullName;
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onReset;

  const _TopBar({required this.onClose, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF223042) : AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Filter Appointments',
                style: AppFonts.semiBold(
                  fontSize: 16,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onReset,
            child: Text(
              'Reset',
              style: AppFonts.bold(fontSize: 14, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeCard extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;

  const _DateRangeCard({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF223042) : AppColors.divider;
    final bg = isDark ? const Color(0xFF141E2A) : const Color(0xFFF6F7F8);
    final labelColor = isDark ? AppColors.grey : AppColors.darkGrey;

    final formatter = DateFormat('MMM d, yyyy');
    final rangeLabel = range == null
        ? 'Select dates'
        : '${formatter.format(range!.start)} - ${formatter.format(range!.end)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: labelColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                rangeLabel,
                style: AppFonts.semiBold(
                  fontSize: 14,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SpeciesRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData iconFor(String label) {
      switch (label.toLowerCase()) {
        case 'dog':
          return Icons.pets;
        case 'cat':
          return Icons.pets;
        case 'bird':
          return Icons.flutter_dash;
        default:
          return Icons.all_inclusive;
      }
    }

    Widget tile({required String label}) {
      final isSelected = selected == label;
      final border = isSelected
          ? AppColors.primary
          : (isDark ? const Color(0xFF223042) : AppColors.divider);
      final bg = isSelected
          ? AppColors.primary.withOpacity(isDark ? 0.14 : 0.08)
          : (isDark ? const Color(0xFF141E2A) : AppColors.white);
      final fg = isSelected
          ? AppColors.primary
          : (isDark ? AppColors.grey : AppColors.darkGrey);

      return InkWell(
        onTap: () => onChanged(label),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: isSelected ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconFor(label), color: fg, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppFonts.semiBold(
                  fontSize: 12,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.grey : AppColors.darkGrey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: appointmentSpeciesOptions
            .map((label) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: tile(label: label),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _BillingSegment extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _BillingSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF141E2A) : const Color(0xFFF0F2F5);

    Widget seg(String label, {bool selected = false, required String value}) {
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? (isDark ? const Color(0xFF1A2430) : AppColors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: selected
                  ? AppFonts.bold(fontSize: 13, color: AppColors.primary)
                  : AppFonts.medium(
                      fontSize: 13,
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg('All', selected: value == 'all', value: 'all'),
          seg('Billed', selected: value == 'billed', value: 'billed'),
          seg('Unbilled', selected: value == 'unbilled', value: 'unbilled'),
        ],
      ),
    );
  }
}

class _BottomApply extends StatelessWidget {
  final VoidCallback onApply;
  const _BottomApply({required this.onApply});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF223042) : AppColors.divider,
          ),
        ),
      ),
      child: PrimaryButton(text: 'Apply Filters', onPressed: onApply),
    );
  }
}
