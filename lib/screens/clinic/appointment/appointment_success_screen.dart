import 'package:clinic_management_app/bloc/appointment/appointment_flow_cubit.dart';
import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/clinic_root.dart';
import 'package:clinic_management_app/screens/clinic/appointment/appointment_used_items_screen.dart';
import 'package:clinic_management_app/screens/clinic/invoice/invoice_summary_screen.dart';
import 'package:clinic_management_app/services/appointment_summary_pdf.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

class AppointmentSuccessScreen extends StatelessWidget {
  const AppointmentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : AppColors.lightGrey;
    final card = isDark ? const Color(0xFF121E2A) : AppColors.white;
    final border = isDark ? const Color(0xFF1A2430) : AppColors.divider;

    return BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
      builder: (context, state) {
        final isSuccess = state.saveStatus == AppointmentSaveStatus.success;

        return PopScope(
          canPop: !isSuccess,
          child: Scaffold(
            backgroundColor: bg,
            appBar: CustomAppBar(
              onBackPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const ClinicRootScreen(initialIndex: 0),
                ),
                (route) => false,
              ),
              title: 'Appointment Status',
            ),
            body: PageContent(
              maxWidth: 700,
              fillHeight: true,
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      children: [
                        BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
                          builder: (context, state) {
                            final isSuccess =
                                state.saveStatus ==
                                AppointmentSaveStatus.success;
                            final title = isSuccess
                                ? 'Appointment Completed!'
                                : 'Appointment Not Saved';
                            final subtitle = isSuccess
                                ? 'The visit has been successfully logged.'
                                : (state.saveError ??
                                      'We could not save this appointment.');

                            return Column(
                              children: [
                                _Celebration(
                                  isDark: isDark,
                                  success: isSuccess,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.extraBold(
                                    fontSize: 22,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.regular(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.grey
                                        : AppColors.darkGrey,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
                          builder: (context, state) {
                            final petLine = [state.petName, state.petBreed]
                                .where((part) => part.trim().isNotEmpty)
                                .join(' - ');

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1A2430)
                                          : const Color(0xFFF0F2F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '\u{1F436}',
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Patient Details',
                                          style: AppFonts.medium(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.grey
                                                : AppColors.darkGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          petLine.isEmpty
                                              ? 'Pet visit'
                                              : petLine,
                                          style: AppFonts.bold(
                                            fontSize: 16,
                                            color: isDark
                                                ? AppColors.white
                                                : AppColors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          state.ownerName.isEmpty
                                              ? 'Pet Owner'
                                              : state.ownerName,
                                          style: AppFonts.regular(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.grey
                                                : AppColors.darkGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
                          builder: (context, state) {
                            final isSuccess =
                                state.saveStatus ==
                                AppointmentSaveStatus.success;
                            if (!isSuccess) {
                              return PrimaryIconButton(
                                text: 'Try Again',
                                icon: Icons.refresh,
                                onPressed: () => context
                                    .read<AppointmentFlowCubit>()
                                    .completeAppointment(),
                              );
                            }

                            return Column(
                              children: [
                                PrimaryIconButton(
                                  text: 'Create Invoice',
                                  icon: Icons.payments,
                                  onPressed: () {
                                    final appointmentId = state.appointmentId;
                                    if (appointmentId == null ||
                                        appointmentId.isEmpty) {
                                      AppToast.error(
                                        context,
                                        'Appointment is missing an id.',
                                      );
                                      return;
                                    }

                                    final invoiceCubit = context
                                        .read<InvoiceCubit>();
                                    invoiceCubit.startNewInvoice(
                                      appointmentId: appointmentId,
                                    );
                                    NavigatorHelper.push(
                                      context,
                                      InvoiceSummaryScreen(
                                        appointmentId: appointmentId,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                PrimaryIconButton(
                                  text: 'Log Used Items',
                                  icon: Icons.inventory_2,
                                  onPressed: () {
                                    final appointmentId = state.appointmentId;
                                    if (appointmentId == null ||
                                        appointmentId.isEmpty) {
                                      AppToast.error(
                                        context,
                                        'Appointment is missing an id.',
                                      );
                                      return;
                                    }
                                    NavigatorHelper.push(
                                      context,
                                      AppointmentUsedItemsScreen(
                                        appointmentId: appointmentId,
                                        petName: state.petName,
                                        ownerName: state.ownerName,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                PrimaryIconButton(
                                  backgroundColor: AppColors.divider,
                                  foregroundColor: AppColors.black,
                                  icon: Icons.print,
                                  text: 'Print Summary',
                                  shadowColor: AppColors.black,
                                  onPressed: () async {
                                    try {
                                      final pdfBytes =
                                          await AppointmentSummaryPdf.build(
                                            state: state,
                                          );
                                      await Printing.layoutPdf(
                                        onLayout: (_) async => pdfBytes,
                                      );
                                    } catch (error) {
                                      AppToast.error(
                                        context,
                                        'Failed to print summary: $error',
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                PrimaryIconButton(
                                  text: 'Email to Customer',
                                  backgroundColor: AppColors.divider,
                                  foregroundColor: AppColors.black,
                                  shadowColor: AppColors.black,
                                  icon: Icons.email,
                                  onPressed: () async {
                                    try {
                                      final pdfBytes =
                                          await AppointmentSummaryPdf.build(
                                            state: state,
                                          );
                                      final petName =
                                          state.petName.trim().isEmpty
                                          ? 'pet'
                                          : state.petName
                                                .trim()
                                                .toLowerCase()
                                                .replaceAll(' ', '-');
                                      await Printing.sharePdf(
                                        bytes: pdfBytes,
                                        filename:
                                            'appointment-summary-$petName.pdf',
                                        subject: 'Appointment Summary',
                                      );
                                    } catch (error) {
                                      AppToast.error(
                                        context,
                                        'Failed to prepare email: $error',
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ClinicRootScreen(initialIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            'Return to Dashboard',
                            style: AppFonts.semiBold(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.grey
                                  : AppColors.darkGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Celebration extends StatelessWidget {
  final bool isDark;
  final bool success;
  const _Celebration({required this.isDark, required this.success});

  @override
  Widget build(BuildContext context) {
    final bgColor = success
        ? AppColors.primary.withValues(alpha: 0.12)
        : (isDark ? const Color(0xFF2A3A4C) : const Color(0xFFE2E8F0));
    final iconColor = success ? AppColors.primary : AppColors.darkGrey;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            ),
            Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                color: success ? AppColors.primary : AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.task_alt : Icons.error_outline,
                size: 44,
                color: success ? AppColors.white : iconColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
