import 'dart:ui';

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
import 'package:clinic_management_app/themes/app_images.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
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
        formKey: _infoFormKey,
        child: ClinicInfoStep(formData: _formData, formKey: _infoFormKey),
        label: 'Clinic Info',
        subtitle: 'Name, address & contact',
        icon: Icons.local_hospital_outlined,
      ),
      _StepEntry(
        formKey: _brandingFormKey,
        child: ClinicBrandingStep(formData: _formData, formKey: _brandingFormKey),
        label: 'Branding',
        subtitle: 'Logo, tagline & about',
        icon: Icons.palette_outlined,
      ),
      _StepEntry(
        formKey: _documentsFormKey,
        child: ClinicDocumentsStep(formData: _formData, formKey: _documentsFormKey),
        label: 'Documents',
        subtitle: 'Certificate upload',
        icon: Icons.description_outlined,
      ),
      _StepEntry(
        formKey: _servicesFormKey,
        child: ServicesAndHoursStep(formData: _formData, formKey: _servicesFormKey),
        label: 'Services & Hours',
        subtitle: 'What you offer & when',
        icon: Icons.schedule_outlined,
      ),
      _StepEntry(
        formKey: _packageFormKey,
        child: PackageSelectionStep(
          formData: _formData,
          formKey: _packageFormKey,
          onPackageChanged: _handlePackageChange,
        ),
        label: 'Package',
        subtitle: 'Choose your plan',
        icon: Icons.workspace_premium_outlined,
      ),
      if (!_isTrialSelected)
        _StepEntry(
          formKey: _paymentFormKey,
          child: PaymentProofStep(formData: _formData, formKey: _paymentFormKey),
          label: 'Payment',
          subtitle: 'Upload proof of payment',
          icon: Icons.payment_outlined,
        ),
      _StepEntry(
        formKey: _reviewFormKey,
        child: Form(
          key: _reviewFormKey,
          child: ReviewStep(formData: _formData),
        ),
        label: 'Review',
        subtitle: 'Confirm & submit',
        icon: Icons.fact_check_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();

    void handleNext() {
      if (_currentStep < steps.length - 1) {
        nextStep();
      } else {
        final reviewKey = steps.last.formKey;
        if (reviewKey.currentState?.validate() ?? true) {
          _formData.clinicStatus ??= "pending_review";
          context.read<LoggedClinicCubit>().createClinic(_formData);
        }
      }
    }

    void blocListener(BuildContext ctx, LoggedClinicState state) {
      if (state is LoggedClinicSuccess) {
        NavigatorHelper.push(
          ctx,
          ClinicRegistrationCompleteScreen(
            clinicCode: state.clinic.clinicCode!,
            clinicStatus: state.clinic.clinicStatus,
          ),
        );
      } else if (state is LoggedClinicFailure) {
        AppToast.error(
          ctx,
          state.message.isNotEmpty
              ? state.message
              : "Failed to create clinic. Please try again.",
        );
      }
    }

    if (Responsive.isDesktop(context)) {
      return BlocListener<LoggedClinicCubit, LoggedClinicState>(
        listener: blocListener,
        child: BlocBuilder<LoggedClinicCubit, LoggedClinicState>(
          builder: (context, state) => _WebRegistrationLayout(
            steps: steps,
            currentStep: _currentStep,
            isLoading: state is LoggedClinicLoading,
            onNext: handleNext,
            onBack: previousStep,
          ),
        ),
      );
    }

    // ── Mobile layout ────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: "Registration"),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocConsumer<LoggedClinicCubit, LoggedClinicState>(
              listener: blocListener,
              builder: (context, state) => PrimaryButton(
                text: _currentStep == steps.length - 1
                    ? "Finish"
                    : "Continue to Next Step",
                isLoading: state is LoggedClinicLoading,
                onPressed: handleNext,
              ),
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
      body: PageContent(
        maxWidth: 480,
        fillHeight: true,
        child: SafeArea(
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

// ─────────────────────────────────────────────────────────────
// Step entry model
// ─────────────────────────────────────────────────────────────

class _StepEntry {
  final GlobalKey<FormState> formKey;
  final Widget child;
  final String label;
  final String subtitle;
  final IconData icon;

  const _StepEntry({
    required this.formKey,
    required this.child,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────
// WEB REGISTRATION LAYOUT
// ─────────────────────────────────────────────────────────────

class _WebRegistrationLayout extends StatefulWidget {
  final List<_StepEntry> steps;
  final int currentStep;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _WebRegistrationLayout({
    required this.steps,
    required this.currentStep,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_WebRegistrationLayout> createState() => _WebRegistrationLayoutState();
}

class _WebRegistrationLayoutState extends State<_WebRegistrationLayout>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _stepCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      duration: const Duration(seconds: 14),
      vsync: this,
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _stepCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(_WebRegistrationLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _stepCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final step = widget.steps[widget.currentStep];
    final isLastStep = widget.currentStep == widget.steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dot-grid texture
          CustomPaint(painter: _RegDotGridPainter()),

          // Animated glow blobs
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) {
              final t = _bgCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -180 + 80 * t,
                    left: -100 + 60 * t,
                    child: _RegGlowBlob(
                      size: 580,
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  Positioned(
                    bottom: -180 + 60 * t,
                    right: -100 - 40 * t,
                    child: _RegGlowBlob(
                      size: 500,
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.14),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.4 - 30 * t,
                    right: size.width * 0.25 + 25 * t,
                    child: _RegGlowBlob(
                      size: 220,
                      color: AppColors.primary.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────
                FadeTransition(
                  opacity: _fade(0.0, 0.4),
                  child: _WebTopBar(
                    currentStep: widget.currentStep,
                    totalSteps: widget.steps.length,
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                // ── Main row ────────────────────────────────
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 28,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Step sidebar
                            FadeTransition(
                              opacity: _fade(0.1, 0.55),
                              child: SlideTransition(
                                position: _slide(0.1, 0.55),
                                child: SizedBox(
                                  width: 248,
                                  child: _WebStepSidebar(
                                    steps: widget.steps,
                                    currentStep: widget.currentStep,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 28),

                            // Right: Form panel
                            Expanded(
                              child: FadeTransition(
                                opacity: _fade(0.2, 0.65),
                                child: SlideTransition(
                                  position: _slide(0.2, 0.65),
                                  child: _WebFormPanel(
                                    steps: widget.steps,
                                    currentStep: widget.currentStep,
                                    stepCtrl: _stepCtrl,
                                    currentStepEntry: step,
                                    isLastStep: isLastStep,
                                    isLoading: widget.isLoading,
                                    onNext: widget.onNext,
                                    onBack: widget.onBack,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────

class _WebTopBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _WebTopBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      child: Row(
        children: [
          Image.asset(AppLogos.appIcon, height: 26),
          const SizedBox(width: 9),
          Text(
            'VetHub',
            style: AppFonts.bold(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.88),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 14,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(width: 10),
          Text(
            'Clinic Registration',
            style: AppFonts.regular(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.13),
                width: 1,
              ),
            ),
            child: Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: AppFonts.medium(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Step sidebar
// ─────────────────────────────────────────────────────────────

class _WebStepSidebar extends StatelessWidget {
  final List<_StepEntry> steps;
  final int currentStep;

  const _WebStepSidebar({
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.11),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'PROGRESS',
                style: AppFonts.semiBold(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 20),

              // Steps list
              ...List.generate(steps.length, (i) {
                final status = i < currentStep
                    ? _StepStatus.completed
                    : i == currentStep
                        ? _StepStatus.active
                        : _StepStatus.pending;
                return _WebStepItem(
                  entry: steps[i],
                  index: i,
                  status: status,
                  isLast: i == steps.length - 1,
                );
              }),

              const Spacer(),

              // Bottom tip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your data is encrypted and secure.',
                        style: AppFonts.regular(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                          height: 1.5,
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

enum _StepStatus { completed, active, pending }

class _WebStepItem extends StatelessWidget {
  final _StepEntry entry;
  final int index;
  final _StepStatus status;
  final bool isLast;

  const _WebStepItem({
    required this.entry,
    required this.index,
    required this.status,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == _StepStatus.completed;
    final isActive = status == _StepStatus.active;

    final badgeColor = isCompleted || isActive
        ? AppColors.primary
        : Colors.white.withValues(alpha: 0.08);

    final labelColor = isActive
        ? Colors.white.withValues(alpha: 0.92)
        : isCompleted
            ? AppColors.primary.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.32);

    final subtitleColor = isActive
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge column + connector
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isActive
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                    : isActive
                        ? Icon(entry.icon, color: Colors.white, size: 14)
                        : Text(
                            '${index + 1}',
                            style: AppFonts.semiBold(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isCompleted
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 12),

        // Labels
        Padding(
          padding: EdgeInsets.only(
            top: 5,
            bottom: isLast ? 0 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.label,
                style: AppFonts.semiBold(
                  fontSize: 13,
                  color: labelColor,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  style: AppFonts.regular(
                    fontSize: 11,
                    color: subtitleColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Form panel
// ─────────────────────────────────────────────────────────────

class _WebFormPanel extends StatelessWidget {
  final List<_StepEntry> steps;
  final int currentStep;
  final AnimationController stepCtrl;
  final _StepEntry currentStepEntry;
  final bool isLastStep;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _WebFormPanel({
    required this.steps,
    required this.currentStep,
    required this.stepCtrl,
    required this.currentStepEntry,
    required this.isLastStep,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glass card with form content
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.065),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.13),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Step header strip
                    _StepHeaderStrip(entry: currentStepEntry),

                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),

                    // Form content
                    Expanded(
                      child: Theme(
                        data: ThemeData(
                          brightness: Brightness.dark,
                          colorScheme: ColorScheme.dark(
                            primary: AppColors.primary,
                            surface: Colors.white.withValues(alpha: 0.08),
                          ),
                          fontFamily: AppFonts.inter,
                        ),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: stepCtrl,
                            curve: Curves.easeOut,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: IndexedStack(
                                index: currentStep,
                                children:
                                    steps.map((s) => s.child).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action bar
        _WebActionBar(
          currentStep: currentStep,
          totalSteps: steps.length,
          isLastStep: isLastStep,
          isLoading: isLoading,
          onNext: onNext,
          onBack: onBack,
        ),
      ],
    );
  }
}

class _StepHeaderStrip extends StatelessWidget {
  final _StepEntry entry;

  const _StepHeaderStrip({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Icon(entry.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.label,
                style: AppFonts.bold(
                  fontSize: 17,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                entry.subtitle,
                style: AppFonts.regular(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebActionBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isLastStep;
  final bool isLoading;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _WebActionBar({
    required this.currentStep,
    required this.totalSteps,
    required this.isLastStep,
    required this.isLoading,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.11),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Back button
              _GhostButton(
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                iconLeading: true,
                onTap: onBack,
              ),

              const Spacer(),

              // Progress dots
              Row(
                children: List.generate(totalSteps, (i) {
                  final isActive = i == currentStep;
                  final isDone = i < currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : isDone
                              ? AppColors.primary.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Continue / Finish button
              _PrimaryWebButton(
                label: isLastStep ? 'Submit' : 'Continue',
                icon: isLastStep
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                isLoading: isLoading,
                onTap: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool iconLeading;
  final VoidCallback onTap;

  const _GhostButton({
    required this.label,
    required this.icon,
    required this.iconLeading,
    required this.onTap,
  });

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hover ? 0.25 : 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.iconLeading) ...[
                Icon(
                  widget.icon,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 7),
              ],
              Text(
                widget.label,
                style: AppFonts.medium(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              if (!widget.iconLeading) ...[
                const SizedBox(width: 7),
                Icon(
                  widget.icon,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryWebButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryWebButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PrimaryWebButton> createState() => _PrimaryWebButtonState();
}

class _PrimaryWebButtonState extends State<_PrimaryWebButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.primary.withValues(alpha: 0.85)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _hover ? 0.45 : 0.3),
                blurRadius: _hover ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing...',
                  style: AppFonts.medium(fontSize: 14, color: Colors.white),
                ),
              ] else ...[
                Text(
                  widget.label,
                  style: AppFonts.medium(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(width: 7),
                Icon(widget.icon, color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared background helpers (local to this file)
// ─────────────────────────────────────────────────────────────

class _RegDotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const spacing = 26.0;
    const radius = 1.1;

    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RegGlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _RegGlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mobile progress header (unchanged)
// ─────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int step;
  final int totalSteps;

  const _ProgressHeader({required this.step, required this.totalSteps});

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
                    color:
                        index <= step ? AppColors.primary : AppColors.divider,
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
              style: AppFonts.regular(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
