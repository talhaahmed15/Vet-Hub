import 'dart:ui';

import 'package:clinic_management_app/navigation/page_transition.dart';
import 'package:clinic_management_app/screens/auth/clinic_choice_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClinicRegistrationCompleteScreen extends StatelessWidget {
  final String clinicCode;
  final String? clinicStatus;

  const ClinicRegistrationCompleteScreen({
    super.key,
    required this.clinicCode,
    this.clinicStatus,
  });

  Future<void> _goToMainScreen(BuildContext context) async {
    await Navigator.of(context).pushAndRemoveUntil(
      AppPageTransition.build(
        const ClinicChoiceScreen(),
        type: PageTransitionType.cupertino,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _WebCompleteLayout(
        clinicCode: clinicCode,
        clinicStatus: clinicStatus,
        onGetStarted: () => _goToMainScreen(context),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _goToMainScreen(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          title: "Registration Complete",
          onBackPressed: () => _goToMainScreen(context),
        ),
        body: PageContent(
          maxWidth: 480,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  48.height,
                  _SuccessIcon(),
                  32.height,
                  _TitleSection(status: clinicStatus),
                  32.height,
                  _ClinicCodeCard(code: clinicCode),
                  20.height,
                  _CopyButton(code: clinicCode),
                  10.height,
                  PrimaryButton(
                    text: "Get Started",
                    onPressed: () => _goToMainScreen(context),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      "You can always find this code in your clinic settings.",
                      textAlign: TextAlign.center,
                      style: AppFonts.regular(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WEB COMPLETE LAYOUT
// ─────────────────────────────────────────────────────────────

class _WebCompleteLayout extends StatefulWidget {
  final String clinicCode;
  final String? clinicStatus;
  final VoidCallback onGetStarted;

  const _WebCompleteLayout({
    required this.clinicCode,
    required this.clinicStatus,
    required this.onGetStarted,
  });

  @override
  State<_WebCompleteLayout> createState() => _WebCompleteLayoutState();
}

class _WebCompleteLayoutState extends State<_WebCompleteLayout>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  String get _titleText =>
      widget.clinicStatus == 'pending_review' ? 'Under Review' : "You're All Set!";

  String get _subtitleText => widget.clinicStatus == 'pending_review'
      ? 'Your clinic is under review. Our team will approve it within a few hours. Share the code with your staff in the meantime.'
      : 'Your veterinary clinic has been successfully registered. Share the code with your staff to give them access.';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dot-grid
          CustomPaint(painter: _CompleteDotGridPainter()),

          // Glow blobs
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) {
              final t = _bgCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    top: -200 + 90 * t,
                    left: -120 + 60 * t,
                    child: _CompleteGlowBlob(
                      size: 600,
                      color: AppColors.primary.withValues(alpha: 0.11),
                    ),
                  ),
                  Positioned(
                    bottom: -180 + 70 * t,
                    right: -100 - 50 * t,
                    child: _CompleteGlowBlob(
                      size: 520,
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.15),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.3 - 40 * t,
                    right: size.width * 0.2 + 30 * t,
                    child: _CompleteGlowBlob(
                      size: 240,
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
                    ),
                  ),
                ],
              );
            },
          ),

          // Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success ring
                      FadeTransition(
                        opacity: _fade(0.0, 0.35),
                        child: SlideTransition(
                          position: _slide(0.0, 0.35),
                          child: _WebSuccessRing(
                            pulseCtrl: _pulseCtrl,
                            isPending:
                                widget.clinicStatus == 'pending_review',
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Title
                      FadeTransition(
                        opacity: _fade(0.2, 0.5),
                        child: SlideTransition(
                          position: _slide(0.2, 0.5),
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Color(0xFFBBDEFB)],
                            ).createShader(bounds),
                            child: Text(
                              _titleText,
                              textAlign: TextAlign.center,
                              style: AppFonts.extraBold(
                                fontSize: 44,
                                color: Colors.white,
                                letterSpacing: -1.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Subtitle
                      FadeTransition(
                        opacity: _fade(0.28, 0.58),
                        child: Text(
                          _subtitleText,
                          textAlign: TextAlign.center,
                          style: AppFonts.regular(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.45),
                            height: 1.7,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Code card
                      FadeTransition(
                        opacity: _fade(0.38, 0.68),
                        child: SlideTransition(
                          position: _slide(0.38, 0.68),
                          child: _WebCodeCard(code: widget.clinicCode),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      FadeTransition(
                        opacity: _fade(0.52, 0.82),
                        child: SlideTransition(
                          position: _slide(0.52, 0.82),
                          child: _WebCompleteActions(
                            code: widget.clinicCode,
                            onGetStarted: widget.onGetStarted,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      FadeTransition(
                        opacity: _fade(0.65, 0.9),
                        child: Text(
                          'You can always find this code in your clinic settings.',
                          textAlign: TextAlign.center,
                          style: AppFonts.regular(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.25),
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
    );
  }
}

class _WebSuccessRing extends StatelessWidget {
  final AnimationController pulseCtrl;
  final bool isPending;

  const _WebSuccessRing({
    required this.pulseCtrl,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPending ? AppColors.warning : const Color(0xFF4CAF50);

    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (context, child) {
        final pulse = pulseCtrl.value;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 120 + 12 * pulse,
                height: 120 + 12 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.15 * (1 - pulse)),
                    width: 1,
                  ),
                ),
              ),
              // Mid ring
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
              ),
              // Inner filled circle
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  isPending
                      ? Icons.hourglass_empty_rounded
                      : Icons.check_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WebCodeCard extends StatelessWidget {
  final String code;

  const _WebCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'CLINIC CODE',
                style: AppFonts.semiBold(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 14),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.primary,
                    const Color(0xFF90CAF9),
                  ],
                ).createShader(bounds),
                child: Text(
                  code,
                  style: AppFonts.extraBold(
                    fontSize: 38,
                    color: Colors.white,
                    letterSpacing: 6,
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

class _WebCompleteActions extends StatelessWidget {
  final String code;
  final VoidCallback onGetStarted;

  const _WebCompleteActions({
    required this.code,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _WebCopyButton(code: code),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _WebGetStartedButton(onPressed: onGetStarted),
        ),
      ],
    );
  }
}

class _WebCopyButton extends StatefulWidget {
  final String code;
  const _WebCopyButton({required this.code});

  @override
  State<_WebCopyButton> createState() => _WebCopyButtonState();
}

class _WebCopyButtonState extends State<_WebCopyButton> {
  bool _hover = false;
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    AppToast.success(context, "Clinic code copied");
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _copy,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _hover
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hover ? 0.25 : 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _copied ? 'Copied!' : 'Copy Code',
                style: AppFonts.medium(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebGetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _WebGetStartedButton({required this.onPressed});

  @override
  State<_WebGetStartedButton> createState() => _WebGetStartedButtonState();
}

class _WebGetStartedButtonState extends State<_WebGetStartedButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _hover
                ? AppColors.primary.withValues(alpha: 0.85)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: _hover ? 0.45 : 0.3),
                blurRadius: _hover ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get Started',
                style: AppFonts.medium(fontSize: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Background helpers
// ─────────────────────────────────────────────────────────────

class _CompleteDotGridPainter extends CustomPainter {
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

class _CompleteGlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _CompleteGlowBlob({required this.size, required this.color});

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
// Mobile widgets (unchanged)
// ─────────────────────────────────────────────────────────────

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Container(
          height: 56,
          width: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Icon(Icons.check, size: 32, color: AppColors.white),
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final String? status;
  const _TitleSection({this.status});

  String _subtitleText() {
    if (status == "pending_review") {
      return "Your veterinary clinic is under review. Our admins will review it within a couple of hours.";
    }
    return "Your veterinary clinic has been successfully registered. "
        "Share this code with your staff to give them access.";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("You're all set!", style: AppFonts.bold(fontSize: 26)),
        12.height,
        Text(
          _subtitleText(),
          textAlign: TextAlign.center,
          style: AppFonts.regular(fontSize: 14, color: AppColors.darkGrey),
        ),
      ],
    );
  }
}

class _ClinicCodeCard extends StatelessWidget {
  final String code;
  const _ClinicCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "CLINIC CODE",
            style: AppFonts.semiBold(
              fontSize: 12,
              letterSpacing: 1,
              color: AppColors.grey,
            ),
          ),
          12.height,
          Text(
            code,
            style: AppFonts.bold(
              fontSize: 32,
              color: AppColors.primary,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String code;
  const _CopyButton({required this.code});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        AppToast.success(context, "Clinic code copied");
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.copy, color: AppColors.primary),
            8.width,
            Text(
              "Copy Clinic Code",
              style: AppFonts.semiBold(fontSize: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
