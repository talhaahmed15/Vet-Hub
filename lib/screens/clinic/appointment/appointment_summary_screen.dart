import 'package:clinic_management_app/bloc/appointment/appointment_flow_cubit.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/appointment/appointment_success_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppointmentSummaryScreen extends StatelessWidget {
  const AppointmentSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : AppColors.lightGrey;
    final card = isDark ? const Color(0xFF121E2A) : AppColors.white;
    final border = isDark ? const Color(0xFF1A2430) : AppColors.divider;

    return BlocListener<AppointmentFlowCubit, AppointmentFlowState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus &&
          (current.saveStatus == AppointmentSaveStatus.success ||
              current.saveStatus == AppointmentSaveStatus.failure),
      listener: (context, state) {
        NavigatorHelper.push(
          context,
          BlocProvider.value(
            value: context.read<AppointmentFlowCubit>(),
            child: const AppointmentSuccessScreen(),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: CustomAppBar(title: 'Appointment Summary'),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 140),
                  children: [
                    const SizedBox(height: 12),
                    const _ProgressDots(activeIndex: 2),
                    _SectionHeader('Pet Owner & Pet Details', paddingTop: 16),
                    _OwnerPetRow(card: card, border: border),
                    const SizedBox(height: 10),
                    _SectionHeader('Appointment Reason'),
                    _TextCard(
                      card: card,
                      border: border,
                      child: BlocBuilder<AppointmentFlowCubit,
                          AppointmentFlowState>(
                        builder: (context, state) {
                          return Text(
                            state.appointmentReason.trim().isEmpty
                                ? 'No reason provided.'
                                : state.appointmentReason.trim(),
                            style: AppFonts.regular(
                              fontSize: 12,
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          );
                        },
                      ),
                    ),
                    _SectionHeader('Clinical Condition'),
                    _TextCard(
                      card: card,
                      border: border,
                      child: BlocBuilder<AppointmentFlowCubit,
                          AppointmentFlowState>(
                        builder: (context, state) {
                          final status = state.conditionStatus.trim().isEmpty
                              ? 'Not specified'
                              : state.conditionStatus;
                          final notes = state.conditionNotes.trim().isEmpty
                              ? 'No condition notes added.'
                              : state.conditionNotes.trim();
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final tone = _statusTone(status);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: tone.withValues(
                                    alpha: isDark ? 0.22 : 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: tone.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: AppFonts.bold(
                                    fontSize: 11,
                                    color: tone,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notes,
                                style: AppFonts.regular(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.grey
                                      : AppColors.darkGrey,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    _SectionHeader('Prescriptions'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: border),
                      ),
                      child: BlocBuilder<AppointmentFlowCubit,
                          AppointmentFlowState>(
                        builder: (context, state) {
                          if (state.prescriptions.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                'No prescriptions added.',
                                style: AppFonts.regular(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.grey
                                      : AppColors.darkGrey,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              for (int i = 0;
                                  i < state.prescriptions.length;
                                  i++)
                                Column(
                                  children: [
                                    _RxRow(
                                      icon: Icons.medication,
                                      title: state.prescriptions[i].name,
                                      subtitle: state.prescriptions[i]
                                              .dosage
                                              .trim()
                                              .isEmpty
                                          ? state.prescriptions[i].instructions
                                          : '${state.prescriptions[i].dosage} - ${state.prescriptions[i].instructions}',
                                    ),
                                    if (i != state.prescriptions.length - 1)
                                      const Divider(height: 1),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
                builder: (context, state) {
                  void handleComplete() {
                    if (state.ownerName.trim().isEmpty) {
                      AppToast.error(context, 'Pet owner name is missing.');
                      return;
                    }
                    if (state.petName.trim().isEmpty) {
                      AppToast.error(context, 'Pet name is missing.');
                      return;
                    }
                    if (state.conditionNotes.trim().isEmpty) {
                      AppToast.error(context, 'Condition notes are required.');
                      return;
                    }

                    context.read<AppointmentFlowCubit>().completeAppointment();
                  }

                  return _BottomBar(
                    onComplete: handleComplete,
                    isLoading: state.saveStatus == AppointmentSaveStatus.saving,
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

class _ProgressDots extends StatelessWidget {
  final int activeIndex;
  const _ProgressDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark ? const Color(0xFF2A3A4C) : const Color(0xFFE5E7EB);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 6,
          width: 48,
          decoration: BoxDecoration(
            color: i == activeIndex ? AppColors.primary : inactive,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final double paddingTop;
  final double paddingBottom;
  final double horizontal;
  const _SectionHeader(
    this.text, {
    this.paddingTop = 18,
    this.paddingBottom = 4,
    this.horizontal = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        paddingTop,
        horizontal,
        paddingBottom,
      ),
      child: Text(
        text,
        style: AppFonts.bold(
          fontSize: 16,
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final Color card;
  final Color border;
  final Widget child;
  const _TextCard({
    required this.card,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class _OwnerPetRow extends StatelessWidget {
  final Color card;
  final Color border;
  const _OwnerPetRow({required this.card, required this.border});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
        builder: (context, state) {
          final petInfo = [
            state.petName,
            state.petBreed,
          ].where((part) => part.trim().isNotEmpty).join(' - ');

          final ownerInfo = [
            state.ownerName,
            state.ownerPhone,
          ].where((part) => part.trim().isNotEmpty).join(' - ');

          return Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF1A2430)
                      : const Color(0xFFF0F2F5),
                ),
                alignment: Alignment.center,
                child: const Text('\u{1F436}', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petInfo.isEmpty ? 'Pet' : petInfo,
                      style: AppFonts.semiBold(
                        fontSize: 16,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownerInfo.isEmpty ? 'Pet Owner' : ownerInfo,
                      style: AppFonts.regular(
                        fontSize: 12,
                        color: isDark ? AppColors.grey : AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RxRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _RxRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.semiBold(
                    fontSize: 14,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppFonts.regular(
                    fontSize: 12,
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

class _BottomBar extends StatelessWidget {
  final VoidCallback onComplete;
  final bool isLoading;
  const _BottomBar({required this.onComplete, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
          ),
        ),
      ),
      child: PrimaryIconButton(
        text: 'Complete Appointment',
        icon: Icons.task_alt,
        onPressed: onComplete,
        isLoading: isLoading,
        isEnabled: !isLoading,
      ),
    );
  }
}

Color _statusTone(String status) {
  switch (status.trim().toLowerCase()) {
    case 'critical':
      return AppColors.error;
    case 'feverish':
      return AppColors.warning;
    case 'improving':
      return AppColors.primary;
    case 'stable':
      return AppColors.success;
    default:
      return AppColors.greyBlue;
  }
}
