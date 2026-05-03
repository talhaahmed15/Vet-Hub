import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/models/package_plan.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/clinic_registration_complete.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/clinic_branding_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/clinic_documents_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/clinic_info_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/package_selection_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/payment_proof_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/review_step.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/steps/service_and_hours_step.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
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
    final steps = _getSteps();
    final currentForm = steps[_currentStep].formKey;
    if (currentForm.currentState?.validate() ?? false) {
      currentForm.currentState!.save();

      if (_currentStep < steps.length - 1) {
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
  final _packageFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _reviewFormKey = GlobalKey<FormState>();

  bool get _isTrialSelected => _formData.packageKey == "trial";

  void _handlePackageChange(PackagePlan? _) {
    setState(() {
      final steps = _getSteps();
      if (_currentStep >= steps.length) {
        _currentStep = steps.length - 1;
      }
    });
  }

  List<_StepEntry> _getSteps() {
    return [
      _StepEntry(
        _infoFormKey,
        ClinicInfoStep(formData: _formData, formKey: _infoFormKey),
      ),
      _StepEntry(
        _brandingFormKey,
        ClinicBrandingStep(formData: _formData, formKey: _brandingFormKey),
      ),
      _StepEntry(
        _documentsFormKey,
        ClinicDocumentsStep(formData: _formData, formKey: _documentsFormKey),
      ),
      _StepEntry(
        _servicesFormKey,
        ServicesAndHoursStep(formData: _formData, formKey: _servicesFormKey),
      ),
      _StepEntry(
        _packageFormKey,
        PackageSelectionStep(
          formData: _formData,
          formKey: _packageFormKey,
          onPackageChanged: _handlePackageChange,
        ),
      ),
      if (!_isTrialSelected)
        _StepEntry(
          _paymentFormKey,
          PaymentProofStep(formData: _formData, formKey: _paymentFormKey),
        ),
      _StepEntry(
        _reviewFormKey,
        Form(
          key: _reviewFormKey,
          child: ReviewStep(formData: _formData),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
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
                  text:
                      _currentStep == steps.length - 1
                          ? "Finish"
                          : "Continue to Next Step",
                  isLoading: state is LoggedClinicLoading,
                  onPressed: () {
                    if (_currentStep < steps.length - 1) {
                      nextStep();
                    } else {
                      _formData.clinicStatus ??= "pending_review";
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
                  clinicStatus: state.clinic.clinicStatus,
                ),
              );
            } else if (state is LoggedClinicFailure) {
              AppToast.error(
                context,
                state.message.isNotEmpty
                    ? state.message
                    : "Failed to create clinic. Please try again.",
              );
            }
          },
          child: Column(
            children: [
              _ProgressHeader(step: _currentStep, totalSteps: steps.length),
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: steps.map((step) => step.child).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepEntry {
  final GlobalKey<FormState> formKey;
  final Widget child;

  const _StepEntry(this.formKey, this.child);
}

class _ProgressHeader extends StatelessWidget {
  final int step;
  final int totalSteps;

  const _ProgressHeader({
    required this.step,
    required this.totalSteps,
  });

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
              children: List.generate(totalSteps, (index) {
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
              "Step ${step + 1} of $totalSteps",
              style: AppFonts.regular(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
