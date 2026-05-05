import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/login_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountBlockedScreen extends StatelessWidget {
  const AccountBlockedScreen({super.key, this.clinic});

  final Clinic? clinic;

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) {
      return;
    }
    NavigatorHelper.replace(context, LoginScreen(clinic: clinic));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageContent(
        maxWidth: 480,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: AppColors.error),
              20.height,
              Text(
                "Account Blocked",
                style: AppFonts.semiBold(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              12.height,
              Text(
                "Your account has been blocked. Please contact your clinic administrator.",
                style: AppFonts.regular(fontSize: 13, color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              28.height,
              PrimaryButton(
                text: "Back to Login",
                onPressed: () => _signOut(context),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
