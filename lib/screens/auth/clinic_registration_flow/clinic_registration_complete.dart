import 'package:clinic_management_app/navigation/page_transition.dart';
import 'package:clinic_management_app/screens/auth/clinic_choice_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
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
    return WillPopScope(
      onWillPop: () async {
        await _goToMainScreen(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: CustomAppBar(
          title: "Registration Complete",
          onBackPressed: () => _goToMainScreen(context),
        ),
        body: SafeArea(
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
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.12),
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
            color: Colors.black.withOpacity(0.05),
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
          color: AppColors.primary.withOpacity(0.1),
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
