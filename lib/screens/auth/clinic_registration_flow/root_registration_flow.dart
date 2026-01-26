import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/clinic_registration_complete.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/clinic_branding_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/clinic_documents_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/clinic_info_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/review_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/service_and_hours_step.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClinicRegistrationFlow extends StatefulWidget {
  const ClinicRegistrationFlow({super.key});

  @override
  State<ClinicRegistrationFlow> createState() => _ClinicRegistrationFlowState();
}

class _ClinicRegistrationFlowState extends State<ClinicRegistrationFlow> {
  int _currentStep = 0;
  final Clinic _formData = Clinic();

  void nextStep() {
    final currentForm = _formKeys[_currentStep];
    if (currentForm.currentState?.validate() ?? false) {
      currentForm.currentState!.save();

      if (_currentStep < 4) {
        setState(() => _currentStep++);
      }
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.canPop(context) ? NavigatorHelper.pop(context) : null;
    }
  }

  final _infoFormKey = GlobalKey<FormState>();
  final _brandingFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();
  final _servicesFormKey = GlobalKey<FormState>();

  List<GlobalKey<FormState>> get _formKeys => [
    _infoFormKey,
    _brandingFormKey,
    _documentsFormKey,
    _servicesFormKey,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: "Registration"),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<LoggedClinicCubit, LoggedClinicState>(
              builder: (context, state) {
                return PrimaryButton(
                  text: _currentStep == 4 ? "Finish" : "Continue to Next Step",
                  isLoading: state is LoggedClinicLoading,
                  onPressed: () {
                    if (_currentStep < 4) {
                      nextStep();
                    } else {
                      context.read<LoggedClinicCubit>().createClinic(_formData);
                    }
                  },
                );
              },
            ),
            TextButton(
              onPressed: previousStep,
              child: Text(
                "Back",
                style: AppFonts.regular(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocListener<LoggedClinicCubit, LoggedClinicState>(
          listener: (context, state) {
            if (state is LoggedClinicSuccess) {
              NavigatorHelper.push(
                context,
                ClinicRegistrationCompleteScreen(
                  clinicCode: state.clinic.clinicCode!,
                ),
              );
            }
          },
          child: Column(
            children: [
              _ProgressHeader(step: _currentStep),
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    ClinicInfoStep(formData: _formData, formKey: _infoFormKey),
                    ClinicBrandingStep(
                      formData: _formData,
                      formKey: _brandingFormKey,
                    ),
                    ClinicDocumentsStep(
                      formData: _formData,
                      formKey: _documentsFormKey,
                    ),
                    ServicesAndHoursStep(
                      formData: _formData,
                      formKey: _servicesFormKey,
                    ),
                    ReviewStep(formData: _formData),
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

class _ProgressHeader extends StatelessWidget {
  final int step;

  const _ProgressHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("REGISTRATION PROGRESS", style: AppFonts.bold(fontSize: 12)),
          8.height,
          Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: index <= step
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          8.height,
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Step ${step + 1} of 5",
              style: AppFonts.regular(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
