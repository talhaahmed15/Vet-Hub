import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_registration_flow/root_registration_flow.dart';
import 'package:clinic_management_app/screens/auth/join_clinic_code_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/themes/app_images.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClinicChoiceScreen extends StatelessWidget {
  const ClinicChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            children: [
              40.height,
              Container(
                // decoration: BoxDecoration(
                //   color: AppColors.primary.withOpacity(0.25),
                //   borderRadius: .circular(36),
                // ),
                child: Image.asset(AppLogos.appLogoWithoutBg, height: 200),
              ),
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
                onPressed: () {
                  NavigatorHelper.push(context, JoinClinicOtpScreen());
                },
              ),
              16.height,
              BlocBuilder<LoggedClinicCubit, LoggedClinicState>(
                builder: (context, state) {
                  return PrimaryOutlinedButton(
                    text: "Register Your Clinic",
                    isLoading: state is LoggedClinicLoading,
                    onPressed: () {
                      NavigatorHelper.push(context, ClinicRegistrationFlow());
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
