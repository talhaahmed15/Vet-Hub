import 'dart:ui';

import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/root_registration_flow.dart';
import 'package:clinic_management_app/screens/auth/join_clinic_code_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/themes/app_images.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClinicChoiceScreen extends StatelessWidget {
  const ClinicChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return const _WebLayout();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _MobileLayout(isDark: isDark);
  }
}

// ─────────────────────────────────────────────────────────────
// WEB  — full-page dark canvas
// ─────────────────────────────────────────────────────────────

class _WebLayout extends StatefulWidget {
  const _WebLayout();

  @override
  State<_WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<_WebLayout> with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _contentCtrl;

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

    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dot-grid texture
          CustomPaint(painter: _DotGridPainter()),

          // Drifting ambient glow blobs
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

          // Page content
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
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
                              Image.asset(AppLogos.appIcon, height: 60),
                              const SizedBox(width: 11),
                              Text(
                                'VetHub',
                                style: AppFonts.bold(
                                  fontSize: 50,
                                  color: Colors.white.withValues(alpha: 0.88),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

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
                            'Clinic Management Platform',
                            style: AppFonts.medium(
                              fontSize: 12,
                              color: const Color(0xFF90CAF9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

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
                              'Streamline Your\nVeterinary Practice',
                              textAlign: TextAlign.center,
                              style: AppFonts.extraBold(
                                fontSize: 60,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -2.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Subtitle ──────────────────────────
                      FadeTransition(
                        opacity: _fade(0.22, 0.56),
                        child: Text(
                          'Appointments, inventory, patient records and prescriptions\n— everything in one platform.',
                          textAlign: TextAlign.center,
                          style: AppFonts.regular(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.44),
                            height: 1.65,
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),

                      // ── Action cards ──────────────────────
                      FadeTransition(
                        opacity: _fade(0.32, 0.72),
                        child: SlideTransition(
                          position: _slide(0.32, 0.72),
                          child: const _WebActionCards(),
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
    );
  }
}

// ── Action cards row ─────────────────────────────────────────

class _WebActionCards extends StatelessWidget {
  const _WebActionCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.login_rounded,
            title: 'Join an Existing Clinic',
            description:
                'Already part of a clinic? Use your invite code to join and start collaborating with your team.',
            buttonLabel: 'Join Clinic',
            isPrimary: true,
            onPressed: () =>
                NavigatorHelper.push(context, JoinClinicOtpScreen()),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: BlocBuilder<LoggedClinicCubit, LoggedClinicState>(
            builder: (context, state) => _ActionCard(
              icon: Icons.add_business_rounded,
              title: 'Register Your Clinic',
              description:
                  'Setting up a new practice? Register your clinic on VetHub and bring your whole team together.',
              buttonLabel: 'Register Clinic',
              isPrimary: false,
              isLoading: state is LoggedClinicLoading,
              onPressed: () =>
                  NavigatorHelper.push(context, ClinicRegistrationFlow()),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.isPrimary,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(_) => _ctrl.forward();
  void _onExit(_) => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    // Static card content — never rebuilt during animation
    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(widget.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 26),
              Text(
                widget.title,
                style: AppFonts.bold(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.92),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.description,
                style: AppFonts.regular(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.48),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: widget.isPrimary
                    ? ElevatedButton(
                        onPressed: widget.onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          widget.buttonLabel,
                          style: AppFonts.medium(fontSize: 14, color: Colors.white),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: widget.isLoading ? null : widget.onPressed,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : Text(
                                widget.buttonLabel,
                                style: AppFonts.medium(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Stack(
            children: [
              // Static card — BackdropFilter never rebuilt
              child!,
              // Lightweight glow overlay — only opacity changes
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _glowOpacity.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.4,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.07),
                            Colors.transparent,
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
        child: cardContent,
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

// ─────────────────────────────────────────────────────────────
// MOBILE / TABLET  — centered single-column
// ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final bool isDark;
  const _MobileLayout({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      body: PageContent(
        maxWidth: 480,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                40.height,
                Image.asset(AppLogos.appLogoWithoutBg, height: 200),
                0.height,
                Text("Welcome to VetHub", style: AppFonts.bold(fontSize: 26)),
                12.height,
                Text(
                  "Do you already have a clinic you want to join, or would you like to create a new one?",
                  textAlign: TextAlign.center,
                  style: AppFonts.regular(fontSize: 14, color: AppColors.grey),
                ),
                48.height,
                PrimaryButton(
                  text: "Join an Existing Clinic",
                  onPressed: () =>
                      NavigatorHelper.push(context, JoinClinicOtpScreen()),
                ),
                16.height,
                BlocBuilder<LoggedClinicCubit, LoggedClinicState>(
                  builder: (context, state) {
                    return PrimaryOutlinedButton(
                      text: "Register Your Clinic",
                      isLoading: state is LoggedClinicLoading,
                      onPressed: () => NavigatorHelper.push(
                        context,
                        ClinicRegistrationFlow(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
