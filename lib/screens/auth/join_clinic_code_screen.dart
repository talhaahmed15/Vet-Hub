import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_cubit.dart';
import 'package:clinic_management_app/bloc/logged_clinic/logged_clinic_states.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/clinic_status/clinic_rejected_screen.dart';
import 'package:clinic_management_app/screens/auth/clinic_status/clinic_under_review_screen.dart';
import 'package:clinic_management_app/screens/auth/login_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';

class JoinClinicOtpScreen extends StatefulWidget {
  const JoinClinicOtpScreen({super.key});

  @override
  State<JoinClinicOtpScreen> createState() => _JoinClinicOtpScreenState();
}

class _JoinClinicOtpScreenState extends State<JoinClinicOtpScreen> {
  String enteredCode = '';

  @override
  Widget build(BuildContext context) {
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

            NavigatorHelper.push(
              context,
              const ClinicUnderReviewScreen(),
            );
          } else if (state is LoggedClinicFailure) {
            AppToast.error(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoggedClinicLoading;

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
                            "Enter the 6-digit code provided by your clinic administrator to sync your account.",
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
                            onChanged: (value) {
                              setState(() {
                                enteredCode = value;
                              });
                            },
                            // cursor: '|',
                            showCursor: true,
                          ),
                          32.height,
                          PrimaryButton(
                            text: "Join Clinic",
                            isEnabled: enteredCode.length == 5,
                            isLoading: isLoading,
                            onPressed: () {
                              context.read<LoggedClinicCubit>().getClinicByCode(
                                enteredCode,
                              );
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
        },
      ),
    );
  }
}
