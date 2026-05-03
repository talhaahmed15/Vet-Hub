import 'package:clinic_management_app/models/appointment_detail.dart';
import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_summary_screen.dart';
import 'package:clinic_management_app/screens/clinic/appointment/new_appointment_screen.dart';
import 'package:clinic_management_app/screens/clinic/appointment/appointment_used_items_screen.dart';
import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/services/appointment_service.dart';
import 'package:clinic_management_app/services/invoice_service.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_details_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late Future<AppointmentDetail?> _future;
  late Future<InvoiceListItem?> _invoiceFuture;
  final AppointmentService _appointmentService = AppointmentService();

  @override
  void initState() {
    super.initState();
    _future = _appointmentService.fetchAppointmentById(widget.appointmentId);
    _invoiceFuture =
        InvoiceService().fetchInvoiceByAppointmentId(widget.appointmentId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101922) : AppColors.lightGrey,
      appBar: CustomAppBar(
        title: 'Appointment Details',
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: isDark ? AppColors.white : AppColors.black,
          ),
          onSelected: (value) async {
            if (value == 'items') {
              final appointment = await _future;
              if (!mounted) return;
              if (appointment == null) {
                AppToast.error(context, 'Appointment details are unavailable.');
                return;
              }
              NavigatorHelper.push(
                context,
                AppointmentUsedItemsScreen(
                  appointmentId: widget.appointmentId,
                  petName: appointment.petName,
                  ownerName: appointment.ownerName,
                ),
              );
              return;
            }
            if (value == 'follow_up') {
              NavigatorHelper.push(context, const NewAppointmentScreen());
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'items',
              child: Text('Items'),
            ),
            PopupMenuItem(
              value: 'follow_up',
              child: Text('Follow-up'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<AppointmentDetail?>(
          future: _future,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            Widget content;
            if (isLoading) {
              content = const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              content = _EmptyState(
                title: 'Unable to load appointment',
                subtitle: snapshot.error.toString(),
                actionText: 'Retry',
                onAction: () {
                  setState(
                    () => _future = _appointmentService
                        .fetchAppointmentById(widget.appointmentId),
                  );
                },
              );
            } else {
              final appointment = snapshot.data;
              if (appointment == null) {
                content = const _EmptyState(
                  title: 'Appointment not found',
                  subtitle: 'This appointment may have been deleted.',
                  actionText: 'Back',
                  onAction: null,
                );
              } else {
                content = ListView(
                  padding: const EdgeInsets.only(bottom: 5),
                  children: [
                    _ProfileHeader(
                      petName: appointment.petName,
                      petSpecies: appointment.petSpecies,
                      petBreed: appointment.petBreed,
                      ownerName: appointment.ownerName,
                    ),
                    const SizedBox(height: 8),
                    _VisitInfoSection(
                      createdAt: appointment.createdAt,
                      doctorName: appointment.doctorName,
                    ),
                    const SizedBox(height: 8),
                    _VitalsSection(
                      weightKg: appointment.weightKg,
                      temperature: appointment.temperature,
                      heartRate: appointment.heartRate,
                    ),
                    const SizedBox(height: 8),
                    _ReasonSection(reason: appointment.appointmentReason),
                    const SizedBox(height: 8),
                    _ConditionSection(status: appointment.conditionStatus),
                    const SizedBox(height: 8),
                    _PrescriptionsSection(
                      prescriptions: appointment.prescriptions,
                    ),
                    const SizedBox(height: 8),
                    _ClinicalNotesSection(notes: appointment.conditionNotes),
                  ],
                );
              }
            }

            return Column(
              children: [
                Expanded(child: content),
                if (!isLoading)
                  _BottomActions(
                    appointmentId: widget.appointmentId,
                    invoiceFuture: _invoiceFuture,
                    onStartFollowUp: () {
                      NavigatorHelper.push(
                        context,
                        const NewAppointmentScreen(),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String petName;
  final String petSpecies;
  final String petBreed;
  final String ownerName;

  const _ProfileHeader({
    required this.petName,
    required this.petSpecies,
    required this.petBreed,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleParts = [
      petSpecies,
      petBreed,
    ].where((part) => part.trim().isNotEmpty).toList();

    return Container(
      color: isDark ? const Color(0xFF101922) : AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isDark ? const Color(0xFF1A2430) : const Color(0xFFF0F2F5),
            ),
            alignment: Alignment.center,
            child: const Text('\u{1F436}', style: TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      petName.isEmpty ? 'Pet' : petName,
                      style: AppFonts.extraBold(
                        fontSize: 22,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'COMPLETED',
                        style: AppFonts.bold(
                          fontSize: 10,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.isEmpty ? '-' : subtitleParts.join(' - '),
                  style: AppFonts.regular(
                    fontSize: 13,
                    color: isDark ? AppColors.grey : AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ownerName.trim().isEmpty
                      ? 'Pet owner: -'
                      : 'Pet owner: $ownerName',
                  style: AppFonts.regular(
                    fontSize: 13,
                    color: isDark ? AppColors.grey : AppColors.darkGrey,
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

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _CardSection({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF101922) : AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppFonts.bold(
                      fontSize: 16,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _VisitInfoSection extends StatelessWidget {
  final DateTime createdAt;
  final String doctorName;

  const _VisitInfoSection({required this.createdAt, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateFormat('MMM d, yyyy').format(createdAt);
    final time = DateFormat('h:mm a').format(createdAt);

    Widget row(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1F2B38) : const Color(0xFFEDEFF3),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppFonts.regular(
                  fontSize: 13,
                  color: isDark ? AppColors.grey : AppColors.darkGrey,
                ),
              ),
            ),
            Text(
              value,
              style: AppFonts.medium(
                fontSize: 13,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ],
        ),
      );
    }

    return _CardSection(
      title: 'Visit Information',
      child: Column(
        children: [
          row('Date', date),
          row('Time', time),
          row('Doctor', _displayOrDash(doctorName)),
        ],
      ),
    );
  }
}

class _VitalsSection extends StatelessWidget {
  final String weightKg;
  final String temperature;
  final String heartRate;

  const _VitalsSection({
    required this.weightKg,
    required this.temperature,
    required this.heartRate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tile(String label, String value, String unit) {
      final bg = isDark ? const Color(0xFF1A2430) : const Color(0xFFF6F7F9);
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppFonts.bold(
                fontSize: 10,
                color: isDark ? AppColors.grey : AppColors.darkGrey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppFonts.extraBold(
                    fontSize: 22,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _CardSection(
      title: 'Vitals',
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          tile('Weight', _displayOrDash(weightKg), 'kg'),
          tile('Temp', _displayOrDash(temperature), 'F'),
          tile('Heart Rate', _displayOrDash(heartRate), 'bpm'),
        ],
      ),
    );
  }
}

class _PrescriptionsSection extends StatelessWidget {
  final List<AppointmentPrescription> prescriptions;

  const _PrescriptionsSection({required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF1F2B38) : const Color(0xFFEDEFF3);

    Widget rxTile({
      required IconData icon,
      required String name,
      required String details,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
          color: isDark ? const Color(0xFF101922) : AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppFonts.bold(
                      fontSize: 13,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: AppFonts.regular(
                      fontSize: 11,
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.grey : AppColors.darkGrey,
            ),
          ],
        ),
      );
    }

    if (prescriptions.isEmpty) {
      return _CardSection(
        title: 'Prescriptions',
        child: Text(
          '-',
          style: AppFonts.regular(
            fontSize: 13,
            color: isDark ? AppColors.grey : AppColors.darkGrey,
          ),
        ),
      );
    }

    return _CardSection(
      title: 'Prescriptions',
      child: Column(
        children: prescriptions
            .map(
              (rx) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: rxTile(
                  icon: Icons.medication,
                  name: rx.name.trim().isEmpty ? '-' : rx.name,
                  details: _rxDetails(rx),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String _rxDetails(AppointmentPrescription rx) {
    final parts = [
      rx.dosage,
      rx.instructions,
    ].where((part) => part.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '-';
    return parts.join(' - ');
  }
}

class _ClinicalNotesSection extends StatelessWidget {
  final String notes;
  const _ClinicalNotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2430) : const Color(0xFFF6F7F9);

    return _CardSection(
      title: 'Clinical Notes',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3A4C) : const Color(0xFFD6DAE1),
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          notes.trim().isEmpty ? '-' : notes.trim(),
          style: AppFonts.regular(
            fontSize: 13,
            color: isDark ? AppColors.white : AppColors.black,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _ReasonSection extends StatelessWidget {
  final String reason;
  const _ReasonSection({required this.reason});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2430) : const Color(0xFFF6F7F9);

    return _CardSection(
      title: 'Reason for Visit',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3A4C) : const Color(0xFFD6DAE1),
            style: BorderStyle.solid,
          ),
        ),
        child: Text(
          reason.trim().isEmpty ? '-' : reason.trim(),
          style: AppFonts.regular(
            fontSize: 13,
            color: isDark ? AppColors.white : AppColors.black,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _ConditionSection extends StatelessWidget {
  final String status;

  const _ConditionSection({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = status.trim().toLowerCase();
    final label = status.trim().isEmpty ? 'Unknown' : status.trim();
    final chipColor = switch (normalized) {
      'stable' => AppColors.success,
      'critical' => AppColors.error,
      'improving' => AppColors.primary,
      'recovering' => AppColors.primary,
      _ => AppColors.greyBlue,
    };

    return _CardSection(
      title: 'Condition',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: chipColor.withOpacity(0.35)),
            ),
            child: Text(
              label.toUpperCase(),
              style: AppFonts.bold(
                fontSize: 11,
                color: chipColor,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final String appointmentId;
  final Future<InvoiceListItem?> invoiceFuture;
  final VoidCallback onStartFollowUp;
  const _BottomActions({
    required this.appointmentId,
    required this.invoiceFuture,
    required this.onStartFollowUp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F2B38) : const Color(0xFFEDEFF3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: FutureBuilder<InvoiceListItem?>(
        future: invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final existing = snapshot.data;
          final hasInvoice = existing != null && existing.id.isNotEmpty;
          final billingLabel = hasInvoice ? 'View Invoice' : 'Create Invoice';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryIconButton(
                text: billingLabel,
                icon: Icons.receipt_long,
                onPressed: () {
                  if (appointmentId.trim().isEmpty) {
                    AppToast.error(context, 'Appointment id is missing.');
                    return;
                  }
                  if (hasInvoice) {
                    NavigatorHelper.push(
                      context,
                      InvoiceDetailsScreen(invoice: existing),
                    );
                    return;
                  }
                  final invoiceCubit = context.read<InvoiceCubit>();
                  invoiceCubit.startNewInvoice(appointmentId: appointmentId);
                  NavigatorHelper.push(
                    context,
                    InvoiceSummaryScreen(appointmentId: appointmentId),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
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
            const SizedBox(height: 16),
            if (onAction != null)
              OutlinedButton(onPressed: onAction, child: Text(actionText))
            else
              OutlinedButton(
                onPressed: () => NavigatorHelper.pop(context),
                child: const Text('Back'),
              ),
          ],
        ),
      ),
    );
  }
}

String _displayOrDash(String value) {
  return value.trim().isEmpty ? '-' : value.trim();
}
