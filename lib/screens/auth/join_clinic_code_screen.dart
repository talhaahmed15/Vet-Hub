import 'dart:ui';

import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_status/clinic_rejected_screen.dart';
import 'package:clinic_management_app/screens/auth/clinic_status/clinic_under_review_screen.dart';
import 'package:clinic_management_app/screens/auth/login_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/themes/app_images.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:clinic_management_app/widgets/web_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';

class JoinClinicOtpScreen extends StatelessWidget {
  const JoinClinicOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoggedClinicCubit(),
      child: BlocConsumer<LoggedClinicCubit, LoggedClinicState>(
        listener: (context, state) {
          if (state is LoggedClinicSuccess) {
            final status = state.clinic.clinicStatus;
            if (status == "approved" || status == null || status.isEmpty) {
              AppToast.success(context, "Clinic joined successfully!");
              NavigatorHelper.replace(
                context,
                LoginScreen(clinic: state.clinic),
              );
              return;
            }
            if (status == "rejected") {
              NavigatorHelper.push(context, const ClinicRejectedScreen());
              return;
            }
            NavigatorHelper.push(context, const ClinicUnderReviewScreen());
          } else if (state is LoggedClinicFailure) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (Responsive.isDesktop(context)) {
            return _WebLayout(state: state);
          }
          return _MobileLayout(state: state);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WEB  — full-page dark canvas
// ─────────────────────────────────────────────────────────────

class _WebLayout extends StatefulWidget {
  final LoggedClinicState state;
  const _WebLayout({required this.state});

  @override
  State<_WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<_WebLayout> with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _contentCtrl;
  String _enteredCode = '';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _contentCtrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
    parent: _contentCtrl,
    curve: Interval(start, end, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _contentCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLoading = widget.state is LoggedClinicLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _DotGridPainter()),

          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) {
              final t = _bgCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -220 + 90 * t,
                    left: -160 + 70 * t,
                    child: _GlowBlob(
                      size: 640,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  Positioned(
                    bottom: -200 + 70 * t,
                    right: -120 - 50 * t,
                    child: _GlowBlob(
                      size: 560,
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.16),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.35 - 40 * t,
                    right: size.width * 0.18 + 35 * t,
                    child: _GlowBlob(
                      size: 260,
                      color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              );
            },
          ),

          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 72,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Logo ──────────────────────────────
                      FadeTransition(
                        opacity: _fade(0.0, 0.3),
                        child: SlideTransition(
                          position: _slide(0.0, 0.3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(AppLogos.appIcon, height: 48),
                              const SizedBox(width: 11),
                              Text(
                                'VetHub',
                                style: AppFonts.bold(
                                  fontSize: 40,
                                  color: Colors.white.withValues(alpha: 0.88),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Badge ─────────────────────────────
                      FadeTransition(
                        opacity: _fade(0.08, 0.38),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Join Your Clinic',
                            style: AppFonts.medium(
                              fontSize: 12,
                              color: const Color(0xFF90CAF9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Headline ──────────────────────────
                      FadeTransition(
                        opacity: _fade(0.14, 0.52),
                        child: SlideTransition(
                          position: _slide(0.14, 0.52),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Color(0xFFBBDEFB)],
                            ).createShader(bounds),
                            child: Text(
                              'Enter Clinic Code',
                              textAlign: TextAlign.center,
                              style: AppFonts.extraBold(
                                fontSize: 48,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -2.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Subtitle ──────────────────────────
                      FadeTransition(
                        opacity: _fade(0.22, 0.56),
                        child: Text(
                          'Enter the 5-character code provided by your clinic\nadministrator to sync your account.',
                          textAlign: TextAlign.center,
                          style: AppFonts.regular(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.44),
                            height: 1.65,
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Glass card with Pinput ─────────────
                      FadeTransition(
                        opacity: _fade(0.32, 0.72),
                        child: SlideTransition(
                          position: _slide(0.32, 0.72),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _WebPinput(
                                      onChanged: (value) =>
                                          setState(() => _enteredCode = value),
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: (_enteredCode.length == 5 &&
                                                !isLoading)
                                            ? () {
                                                context
                                                    .read<LoggedClinicCubit>()
                                                    .getClinicByCode(
                                                        _enteredCode);
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          disabledBackgroundColor:
                                              AppColors.primary
                                                  .withValues(alpha: 0.35),
                                          shadowColor: AppColors.primary
                                              .withValues(alpha: 0.4),
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'Join Clinic',
                                                style: AppFonts.medium(
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text.rich(
                                      TextSpan(
                                        text: "Don't have a code?  ",
                                        style: AppFonts.regular(
                                          fontSize: 13,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Contact your manager',
                                            style: AppFonts.medium(
                                              fontSize: 13,
                                              color: const Color(0xFF90CAF9),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Back button — rendered last so it sits above the scroll view
          Positioned(
            top: 20,
            left: 24,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fade(0.0, 0.3),
                child: const WebBackButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebPinput extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _WebPinput({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 64,
      height: 64,
      textStyle: AppFonts.bold(fontSize: 22, color: Colors.white),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    final submittedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );

    return Pinput(
      length: 5,
      keyboardType: TextInputType.text,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: focusedTheme,
      submittedPinTheme: submittedTheme,
      showCursor: true,
      cursor: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MOBILE / TABLET  — light themed, centered single-column
// ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatefulWidget {
  final LoggedClinicState state;
  const _MobileLayout({required this.state});

  @override
  State<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<_MobileLayout> {
  String _enteredCode = '';

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state is LoggedClinicLoading;

    final defaultPinTheme = PinTheme(
      width: 60,
      height: 60,
      textStyle: AppFonts.bold(fontSize: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: "Join Clinic"),
      body: PageContent(
        maxWidth: 480,
        fillHeight: true,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      32.height,
                      Text(
                        "Enter Clinic Code",
                        style: AppFonts.bold(fontSize: 22),
                      ),
                      12.height,
                      Text(
                        "Enter the 5-character code provided by your clinic administrator to sync your account.",
                        textAlign: TextAlign.center,
                        style: AppFonts.regular(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                      32.height,
                      Pinput(
                        length: 5,
                        keyboardType: TextInputType.text,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        showCursor: true,
                        onChanged: (value) =>
                            setState(() => _enteredCode = value),
                      ),
                      32.height,
                      PrimaryButton(
                        text: "Join Clinic",
                        isEnabled: _enteredCode.length == 5,
                        isLoading: isLoading,
                        onPressed: () {
                          context
                              .read<LoggedClinicCubit>()
                              .getClinicByCode(_enteredCode);
                        },
                      ),
                      16.height,
                      Text.rich(
                        TextSpan(
                          text: "Don't have a code? ",
                          style: AppFonts.regular(fontSize: 12),
                          children: [
                            TextSpan(
                              text: "Contact your manager",
                              style: AppFonts.bold(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      24.height,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
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

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
