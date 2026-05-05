import 'package:clinic_management_app/bloc/appointment/appointment_flow_cubit.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/appointment/appointment_summary_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _showForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _dosageController.clear();
    _instructionsController.clear();
  }

  void _savePrescription() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppToast.error(context, 'Please fix the highlighted fields.');
      return;
    }

    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final instructions = _instructionsController.text.trim();

    context.read<AppointmentFlowCubit>().addPrescription(
      PrescriptionDraft(name: name, dosage: dosage, instructions: instructions),
    );

    _clearForm();
    setState(() => _showForm = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : AppColors.lightGrey;
    final card = isDark ? const Color(0xFF121E2A) : AppColors.white;
    final border = isDark ? const Color(0xFF1A2430) : AppColors.divider;

    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(title: 'Prescription'),
      bottomNavigationBar: _BottomBar(
        onNext: () => NavigatorHelper.push(
          context,
          BlocProvider.value(
            value: context.read<AppointmentFlowCubit>(),
            child: const AppointmentSummaryScreen(),
          ),
        ),
      ),
      body: PageContent(
        maxWidth: 700,
        fillHeight: true,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
                children: [
                  const _ProgressDots(activeIndex: 1),
                  const SizedBox(height: 12),
                  _PetMiniCard(card: card, border: border),
                  const SizedBox(height: 20),
                  Text(
                    'Prescriptions',
                    style: AppFonts.extraBold(
                      fontSize: 22,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
                    builder: (context, state) {
                      if (state.prescriptions.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: border),
                          ),
                          child: Text(
                            'No prescriptions added yet.',
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
                          for (int i = 0; i < state.prescriptions.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == state.prescriptions.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: _RxTile(
                                icon: Icons.medication,
                                title: state.prescriptions[i].name,
                                subtitle: state.prescriptions[i].dosage.isEmpty
                                    ? state.prescriptions[i].instructions
                                    : '${state.prescriptions[i].dosage} - ${state.prescriptions[i].instructions}',
                                card: card,
                                border: border,
                                onRemove: () => context
                                    .read<AppointmentFlowCubit>()
                                    .removePrescription(i),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setState(() => _showForm = !_showForm),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Add Prescription',
                                  style: AppFonts.bold(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.black,
                                  ),
                                ),
                              ),
                              Text(
                                _showForm ? 'Hide' : 'Add',
                                style: AppFonts.semiBold(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (_showForm) ...[
                            const SizedBox(height: 12),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  CustomTextField(
                                    hintText:
                                        'Medication name (e.g. Carprofen)',
                                    controller: _nameController,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Medication name is required.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    hintText: 'Dosage (e.g. 25mg)',
                                    controller: _dosageController,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    hintText:
                                        'Instructions (e.g. 1 tablet twice daily for 7 days)',
                                    maxLines: 3,
                                    controller: _instructionsController,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Instructions are required.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            PrimaryOutlinedButton(
                              text: 'Save Prescription',
                              onPressed: _savePrescription,
                            ),
                          ],
                        ],
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
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int activeIndex;
  const _ProgressDots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark ? const Color(0xFF2A3A4C) : const Color(0xFFE3E7EC);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          height: 6,
          width: 46,
          margin: EdgeInsets.only(right: i == 2 ? 0 : 10),
          decoration: BoxDecoration(
            color: i == activeIndex ? AppColors.primary : inactive,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _PetMiniCard extends StatelessWidget {
  final Color card;
  final Color border;
  const _PetMiniCard({required this.card, required this.border});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
      builder: (context, state) {
        final subtitle = state.appointmentReason.trim().isEmpty
            ? 'Visit in progress'
            : state.appointmentReason.trim();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF1A2430)
                      : const Color(0xFFF0F2F5),
                ),
                alignment: Alignment.center,
                child: const Text('\u{1F436}', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.petName.isEmpty ? 'Pet' : state.petName,
                    style: AppFonts.semiBold(
                      fontSize: 16,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RxTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color card;
  final Color border;
  final VoidCallback onRemove;

  const _RxTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.card,
    required this.border,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
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
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onNext;
  const _BottomBar({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101922) : AppColors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1A2430) : AppColors.divider,
          ),
        ),
      ),
      child: PrimaryButton(text: 'Next to Summary', onPressed: onNext),
    );
  }
}
