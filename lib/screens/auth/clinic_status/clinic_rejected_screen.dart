import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/settings_module/help_center/help_center_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ClinicRejectedScreen extends StatelessWidget {
  const ClinicRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: "Clinic Status"),
      body: PageContent(
        maxWidth: 480,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                48.height,
                _RejectedIcon(),
                32.height,
                Text(
                  "Clinic Not Approved",
                  style: AppFonts.bold(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                12.height,
                Text(
                  "This clinic registration was rejected. "
                  "Please contact your administrator for the next steps.",
                  textAlign: TextAlign.center,
                  style: AppFonts.regular(fontSize: 14, color: AppColors.darkGrey),
                ),
                32.height,
                PrimaryOutlinedButton(
                  text: "Contact Support",
                  onPressed: () {
                    NavigatorHelper.push(
                      context,
                      const HelpCenterScreen(),
                    );
                  },
                ),
                12.height,
                PrimaryButton(
                  text: "Back",
                  onPressed: () {
                    NavigatorHelper.pop(context);
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

class _RejectedIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.error.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Container(
          height: 56,
          width: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error,
          ),
          child: const Icon(Icons.close, size: 32, color: AppColors.white),
        ),
      ),
    );
  }
}
