import 'package:clinic_management_app/bloc/appointment/appointment_flow_cubit.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/appointment/prescription_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConditionScreen extends StatefulWidget {
  const ConditionScreen({super.key});

  @override
  State<ConditionScreen> createState() => _ConditionScreenState();
}

class _ConditionScreenState extends State<ConditionScreen> {
  static const List<String> _statuses = [
    'Stable',
    'Critical',
    'Improving',
    'Feverish',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selected = 0;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppointmentFlowCubit>().state;
    final index = _statuses.indexOf(state.conditionStatus);
    _selected = index == -1 ? 0 : index;
    _notesController = TextEditingController(text: state.conditionNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.lightGrey;
    final card = AppColors.white;
    final border = AppColors.divider;

    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(title: 'Condition'),
      bottomNavigationBar: _BottomCta(
        text: 'Next to Prescription',
        icon: Icons.arrow_forward,
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) {
            AppToast.error(
              context,
              'Please add condition notes before continuing.',
            );
            return;
          }

          context.read<AppointmentFlowCubit>().updateCondition(
            status: _statuses[_selected],
            notes: _notesController.text.trim(),
          );
          NavigatorHelper.push(
            context,
            BlocProvider.value(
              value: context.read<AppointmentFlowCubit>(),
              child: const PrescriptionScreen(),
            ),
          );
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                  children: [
                    const _ProgressDots(activeIndex: 0),
                    const SizedBox(height: 12),
                    BlocBuilder<AppointmentFlowCubit, AppointmentFlowState>(
                      builder: (context, state) {
                        final subtitleParts = <String>[];
                        if (state.petSpecies.trim().isNotEmpty) {
                          subtitleParts.add(state.petSpecies);
                        }
                        if (state.petBreed.trim().isNotEmpty) {
                          subtitleParts.add(state.petBreed);
                        }
                        if (state.petAge.trim().isNotEmpty) {
                          subtitleParts.add('${state.petAge} yrs');
                        }

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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF0F2F5),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.petName.isEmpty
                                          ? 'Pet'
                                          : state.petName,
                                      style: AppFonts.semiBold(
                                        fontSize: 16,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitleParts.isEmpty
                                          ? 'Condition check'
                                          : subtitleParts.join(' - '),
                                      style: AppFonts.regular(
                                        fontSize: 12,
                                        color: AppColors.darkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              5.width,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'IN CONSULT',
                                  style: AppFonts.bold(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Diagnosis & Condition',
                      style: AppFonts.extraBold(
                        fontSize: 22,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'QUICK STATUS',
                      style: AppFonts.bold(
                        fontSize: 12,
                        color: AppColors.darkGrey,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Chip(
                          text: _statuses[0],
                          selected: _selected == 0,
                          onTap: () => setState(() => _selected = 0),
                        ),
                        _Chip(
                          text: _statuses[1],
                          selected: _selected == 1,
                          onTap: () => setState(() => _selected = 1),
                        ),
                        _Chip(
                          text: _statuses[2],
                          selected: _selected == 2,
                          onTap: () => setState(() => _selected = 2),
                        ),
                        _Chip(
                          text: _statuses[3],
                          selected: _selected == 3,
                          onTap: () => setState(() => _selected = 3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      maxLines: 12,
                      hintText:
                          'Condition notes (e.g. limping on left leg, mild fever, no appetite)',
                      controller: _notesController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Condition notes are required.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _Chip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = _toneFor(text);
    final borderColor = selected
        ? tone
        : (isDark ? const Color(0xFF2A3A4C) : const Color(0xFFE5E7EB));
    final bgColor = selected
        ? tone.withOpacity(isDark ? 0.22 : 0.14)
        : (isDark ? const Color(0xFF121E2A) : AppColors.white);
    final textColor = selected
        ? tone
        : (isDark ? AppColors.white : AppColors.black);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          text,
          style: AppFonts.semiBold(fontSize: 12, color: textColor),
        ),
      ),
    );
  }
}

Color _toneFor(String status) {
  switch (status.toLowerCase()) {
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

class _BottomCta extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _BottomCta({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: PrimaryIconButton(text: text, icon: icon, onPressed: onPressed),
    );
  }
}
