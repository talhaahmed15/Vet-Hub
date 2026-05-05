import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool agreeToTerms = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,

      appBar: CustomAppBar(title: "Signup"),
      body: PageContent(
        maxWidth: 480,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                24.height,
                _TitleSection(),
                32.height,
                _NameInput(),
                16.height,
                _EmailInput(),
                16.height,
                _PasswordInput(),
                16.height,
                _TermsCheckbox(
                  agreeToTerms: agreeToTerms,
                  onChanged: (val) => setState(() => agreeToTerms = val ?? false),
                ),
                const SizedBox(height: 24),
                PrimaryButton(text: "Create Account", onPressed: () {}),
                const SizedBox(height: 24),
                _DividerText(text: "Are you a clinic owner?".toUpperCase()),
                16.height,
                PrimaryOutlinedButton(
                  text: "Register your Clinic",
                  onPressed: () {},
                  isEnabled: true,
                ),
                const SizedBox(height: 32),
                // _FooterSection(),
                // const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- SECTIONS ----------

class _BackHeader extends StatelessWidget {
  const _BackHeader();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios,
              color: isDark ? AppColors.white : AppColors.black,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Sign Up',
          style: AppFonts.bold(
            fontSize: 18,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get Started',
          style: AppFonts.bold(
            fontSize: 24,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        4.height,
        Text(
          'Manage your clinic with ease',
          style: AppFonts.regular(
            fontSize: 16,
            color: isDark ? AppColors.grey : AppColors.darkGrey,
          ),
        ),
      ],
    );
  }
}

class _NameInput extends StatelessWidget {
  const _NameInput();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.findAncestorStateOfType<_SignupScreenState>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: AppFonts.semiBold(
            fontSize: 12,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        CustomTextField(
          controller: state.nameController,
          hintText: 'John Doe',
          keyboardType: TextInputType.name,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _EmailInput extends StatelessWidget {
  const _EmailInput();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.findAncestorStateOfType<_SignupScreenState>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: AppFonts.semiBold(
            fontSize: 12,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        CustomTextField(
          controller: state.emailController,
          hintText: 'name@clinic.com',
          keyboardType: TextInputType.emailAddress,
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
    final state = context.findAncestorStateOfType<_SignupScreenState>()!;

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
          controller: state.passwordController,
          hintText: 'At least 8 characters',
          keyboardType: TextInputType.text,
          isDark: isDark,
          obscureText: true,
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool agreeToTerms;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({required this.agreeToTerms, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: .center,
      mainAxisAlignment: .start,
      children: [
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: agreeToTerms,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ),
        10.width,
        Expanded(
          child: Text.rich(
            TextSpan(
              text: "I agree to the ",
              style: AppFonts.regular(
                fontSize: 12,
                color: isDark ? AppColors.grey : AppColors.darkGrey,
              ),
              children: [
                TextSpan(
                  text: "Terms of Service",
                  style: AppFonts.bold(color: AppColors.primary, fontSize: 12),
                ),
                TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy.",
                  style: AppFonts.bold(color: AppColors.primary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerText extends StatelessWidget {
  final String text;
  const _DividerText({required this.text});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: AppFonts.regular(
              fontSize: 12,
              color: isDark ? AppColors.grey : AppColors.darkGrey,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Text.rich(
        TextSpan(
          text: "Already have an account? ",
          style: AppFonts.regular(
            fontSize: 12,
            color: isDark ? AppColors.grey : AppColors.darkGrey,
          ),
          children: [
            TextSpan(
              text: 'Log In',
              style: AppFonts.bold(color: AppColors.primary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
