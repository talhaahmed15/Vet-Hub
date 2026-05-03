import 'dart:developer';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/auth/account_status/account_blocked_screen.dart';
import 'package:clinic_management_app/screens/auth/account_status/account_under_review_screen.dart';
import 'package:clinic_management_app/screens/auth/app_start_screen.dart';
import 'package:clinic_management_app/screens/auth/clinic_account_signup_flow/clinic_account_signup_flow.dart';
import 'package:clinic_management_app/screens/clinic/clinic_root.dart';
import 'package:clinic_management_app/services/auth_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/utils/url_utils.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/social_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clinic_management_app/bloc/login/login_cubit.dart';
import 'package:clinic_management_app/bloc/login/login_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.clinic});

  final Clinic? clinic;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late final LoginCubit _loginCubit;

  @override
  void initState() {
    super.initState();
    _loginCubit = LoginCubit();
  }

  @override
  void dispose() {
    _loginCubit.close();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty) {
      AppToast.error(context, "Username is required.");
      return;
    }
    if (password.isEmpty) {
      AppToast.error(context, "Password is required.");
      return;
    }

    try {
      final clinicCode =
          widget.clinic?.clinicCode ?? await Storage.getClinicCode();
      if (clinicCode == null || clinicCode.isEmpty) {
        throw "Missing clinic code. Please join the clinic again.";
      }

      await _loginCubit.login(
        clinicCode: clinicCode,
        username: username,
        password: password,
        clinicId: widget.clinic?.clinicId,
      );
    } catch (e) {
      AppToast.error(context, e.toString());
    }
  }

  Future<void> _changeClinic() async {
    try {
      await AuthService().signOutAndClear(clearClinic: true);
      if (!mounted) return;
      NavigatorHelper.replace(context, const AppStartScreen());
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    }
  }

  void _routeByStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'active') {
      NavigatorHelper.replace(context, const ClinicRootScreen());
    } else if (normalized == 'blocked') {
      NavigatorHelper.replace(
        context,
        AccountBlockedScreen(clinic: widget.clinic),
      );
    } else {
      NavigatorHelper.replace(
        context,
        AccountUnderReviewScreen(clinic: widget.clinic),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _loginCubit,
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            AppToast.error(context, state.message);
          }
          if (state is LoginSuccess) {
            _routeByStatus(state.accountStatus);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.black : AppColors.white,
            body: Center(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      12.height,
                      _ClinicHeader(clinic: widget.clinic),
                      12.height,
                      Divider(color: AppColors.lightGrey),
                      12.height,
                      _WelcomeText(),
                      32.height,
                      _UsernameInput(),
                      16.height,
                      _PasswordInput(),
                      32.height,
                      _SignInButton(isLoading: state is LoginLoading),
                      32.height,
                      _DividerText(),
                      32.height,
                      _SocialButtons(),
                      16.height,
                      _FooterSection(clinic: widget.clinic),
                      24.height,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ---------- SECTIONS ----------

class _ClinicHeader extends StatelessWidget {
  const _ClinicHeader({this.clinic});

  final Clinic? clinic;

  @override
  Widget build(BuildContext context) {
    final logoUrl = clinic?.logoUrl;
    final clinicName = (clinic?.clinicName ?? '').trim();
    final displayName = clinicName.isNotEmpty ? clinicName : 'Vet Hub';
    final hasRemoteLogo =
        logoUrl != null &&
        logoUrl.isNotEmpty &&
        (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'));
    final safeLogoUrl = hasRemoteLogo ? sanitizeRemoteUrl(logoUrl!) : null;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              height: 70,
              width: 70,
              child: hasRemoteLogo
                  ? ClipOval(
                      child: Image.network(
                        safeLogoUrl ?? logoUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, e) {
                          log(e.toString());
                          return Icon(
                            Icons.pets,
                            size: 48,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    )
                  : Icon(Icons.pets, size: 48, color: AppColors.primary),
            ),
          ),
          12.height,
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: AppFonts.semiBold(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: AppFonts.semiBold(fontSize: 24),
        ),
        SizedBox(height: 4),
        Text(
          'Log in to manage your clinic and patients',
          textAlign: TextAlign.center,
          style: AppFonts.regular(fontSize: 14, color: AppColors.darkGrey),
        ),
      ],
    );
  }
}

class _UsernameInput extends StatelessWidget {
  const _UsernameInput();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: AppFonts.semiBold(
            fontSize: 12,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        CustomTextField(
          controller: context
              .findAncestorStateOfType<_LoginScreenState>()!
              .usernameController,
          hintText: "vetflow_admin",
          keyboardType: TextInputType.text,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: AppFonts.semiBold(
            fontSize: 12,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        CustomTextField(
          controller: context
              .findAncestorStateOfType<_LoginScreenState>()!
              .passwordController,
          hintText: 'Enter your password',
          keyboardType: TextInputType.text,
          isDark: isDark,
          obscureText: true,
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginScreenState>()!;
    return PrimaryButton(
      text: "Sign In",
      isLoading: isLoading,
      onPressed: state._signIn,
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or continue with',
            style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          icon: Icons.g_translate,
          label: 'Continue with Google',
          backgroundColor: AppColors.white,
          textColor: AppColors.black,
          borderColor: AppColors.divider,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        SocialButton(
          icon: Icons.apple,
          label: 'Continue with Apple',
          backgroundColor: AppColors.black,
          textColor: AppColors.white,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({this.clinic});

  final Clinic? clinic;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginScreenState>();
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: "Don't have an account? ",
            style: AppFonts.regular(color: AppColors.darkGrey, fontSize: 12),
            children: [
              TextSpan(
                text: 'Sign Up',
                style: AppFonts.bold(color: AppColors.primary, fontSize: 12),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // Navigate to Sign Up
                    NavigatorHelper.push(
                      context,
                      ClinicAccountSignupFlow(clinic: clinic),
                    );
                    // or GoRouter / Riverpod logic
                  },
              ),
            ],
          ),
        ),

        if (clinic != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: state?._changeClinic,
            child: Text(
              "Change clinic",
              style: AppFonts.semiBold(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'By logging in, you agree to our Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: AppFonts.regular(color: AppColors.grey, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
