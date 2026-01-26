import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/services/clinic_account_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ClinicAccountSignupFlow extends StatefulWidget {
  const ClinicAccountSignupFlow({super.key, this.clinic});

  final Clinic? clinic;

  @override
  State<ClinicAccountSignupFlow> createState() =>
      _ClinicAccountSignupFlowState();
}

class _ClinicAccountSignupFlowState extends State<ClinicAccountSignupFlow> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  bool _isEmailVerified = false;
  String _lastOtpEmail = '';
  String? _pendingAuthUserId;
  String? _verifiedAuthUserId;

  final _infoFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _roleFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );

  ClinicRole _role = ClinicRole.vet;

  List<GlobalKey<FormState>> get _formKeys => [
    _infoFormKey,
    _roleFormKey,
    _securityFormKey,
    _otpFormKey,
  ];

  @override
  void initState() {
    super.initState();
    _lastOtpEmail = _emailController.text.trim().toLowerCase();
    _emailController.addListener(_handleEmailChange);
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailChange);
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleEmailChange() {
    final currentEmail = _emailController.text.trim().toLowerCase();
    if (currentEmail != _lastOtpEmail) {
      _lastOtpEmail = currentEmail;
      if (_isEmailVerified || _otpSent) {
        setState(() {
          _isEmailVerified = false;
          _otpSent = false;
          _pendingAuthUserId = null;
          _verifiedAuthUserId = null;
        });
      }
      for (final controller in _otpControllers) {
        controller.clear();
      }
    }
  }

  void _nextStep() {
    final currentForm = _formKeys[_currentStep];
    if (currentForm.currentState?.validate() ?? false) {
      final otpStepIndex = _formKeys.indexOf(_otpFormKey);
      if (_currentStep == otpStepIndex && !_isEmailVerified) {
        AppToast.error(context, "Please verify your email to continue.");
        return;
      }
      currentForm.currentState?.save();
      if (_currentStep < _formKeys.length - 1) {
        setState(() => _currentStep++);
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      NavigatorHelper.pop(context);
    }
  }

  Future<void> _submit() async {
    final currentForm = _formKeys[_currentStep];
    if (!(currentForm.currentState?.validate() ?? false)) {
      return;
    }

    if (!_isEmailVerified) {
      AppToast.error(context, "Please verify your email to continue.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final clinicCode =
          widget.clinic?.clinicCode ?? await Storage.getClinicCode();
      if (clinicCode == null || clinicCode.isEmpty) {
        throw "Missing clinic code. Please join the clinic again.";
      }

      await ClinicAccountService().createClinicAccount(
        clinicCode: clinicCode,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        authUserId: _verifiedAuthUserId ?? _pendingAuthUserId,
      );

      AppToast.success(context, "Account created successfully");
      NavigatorHelper.pop(context);
    } catch (e) {
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.contains('@');
  }

  String _otpValue() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) {
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      AppToast.error(context, "Enter a valid email before sending OTP.");
      return;
    }

    if (_passwordController.text.length < 8) {
      AppToast.error(context, "Set a valid password before sending OTP.");
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      final result = await ClinicAccountService().sendSignupOtp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _otpSent = true;
        _pendingAuthUserId = result.userId ?? _pendingAuthUserId;
        if (result.isVerified) {
          _isEmailVerified = true;
          _verifiedAuthUserId = result.userId ?? _pendingAuthUserId;
        }
      });
      AppToast.success(
        context,
        result.isVerified
            ? "Email already verified."
            : "OTP sent to ${_emailController.text.trim()}",
      );
    } catch (e) {
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifyingOtp) {
      return;
    }

    final otp = _otpValue();
    if (otp.length != 4 || otp.contains(RegExp(r'[^0-9]'))) {
      AppToast.error(context, "Enter the 4-digit OTP sent to your email.");
      return;
    }

    setState(() => _isVerifyingOtp = true);
    try {
      final verifiedUserId = await ClinicAccountService().verifySignupOtp(
        email: _emailController.text.trim(),
        token: otp,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isEmailVerified = true;
        _verifiedAuthUserId = verifiedUserId ?? _pendingAuthUserId;
      });
      AppToast.success(context, "Email verified successfully.");
    } catch (e) {
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: "Clinic Account Signup"),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              text: _currentStep == _formKeys.length - 1
                  ? "Create Account"
                  : "Continue",
              isLoading: _isSubmitting,
              onPressed: () {
                if (_currentStep == _formKeys.length - 1) {
                  _submit();
                } else {
                  _nextStep();
                }
              },
            ),
            TextButton(
              onPressed: _isSubmitting ? null : _previousStep,
              child: Text(
                "Back",
                style: AppFonts.regular(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(step: _currentStep, total: _formKeys.length),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _AccountInfoStep(
                    formKey: _infoFormKey,
                    fullNameController: _fullNameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                  ),
                  _RoleStep(
                    formKey: _roleFormKey,
                    role: _role,
                    onRoleChanged: (role) => setState(() => _role = role),
                  ),
                  _SecurityStep(
                    formKey: _securityFormKey,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                  ),
                  _EmailVerificationStep(
                    formKey: _otpFormKey,
                    email: _emailController.text.trim(),
                    otpControllers: _otpControllers,
                    otpFocusNodes: _otpFocusNodes,
                    isSending: _isSendingOtp,
                    isVerifying: _isVerifyingOtp,
                    otpSent: _otpSent,
                    isVerified: _isEmailVerified,
                    onSendOtp: _sendOtp,
                    onVerifyOtp: _verifyOtp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SIGNUP PROGRESS", style: AppFonts.bold(fontSize: 12)),
          8.height,
          Row(
            children: List.generate(total, (index) {
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: index <= step
                        ? AppColors.primary
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          8.height,
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Step ${step + 1} of $total",
              style: AppFonts.regular(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoStep extends StatelessWidget {
  const _AccountInfoStep({
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Account Info", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Tell us who's creating this account.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            24.height,
            Text('Full Name', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              controller: fullNameController,
              hint: "Jane Doe",
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Full name is required";
                }
                return null;
              },
            ),
            16.height,
            Text('Email Address', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              controller: emailController,
              hint: "name@clinic.com",
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Email is required";
                }
                if (!val.contains('@')) {
                  return "Enter a valid email";
                }
                return null;
              },
            ),
            16.height,
            Text('Phone Number', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              controller: phoneController,
              hint: "+1 (555) 000-0000",
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailVerificationStep extends StatelessWidget {
  const _EmailVerificationStep({
    required this.formKey,
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.isSending,
    required this.isVerifying,
    required this.otpSent,
    required this.isVerified,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  final GlobalKey<FormState> formKey;
  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool isSending;
  final bool isVerifying;
  final bool otpSent;
  final bool isVerified;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;

  @override
  Widget build(BuildContext context) {
    final hasEmail = email.isNotEmpty;
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Verify Email", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Confirm your email address to protect your account.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            20.height,
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasEmail ? email : "Enter your email to receive an OTP.",
                    style: AppFonts.semiBold(
                      fontSize: 13,
                      color: hasEmail ? AppColors.black : AppColors.grey,
                    ),
                  ),
                ),
                if (isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Verified",
                      style: AppFonts.semiBold(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            24.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(otpControllers.length, (index) {
                return _OtpDigitField(
                  controller: otpControllers[index],
                  focusNode: otpFocusNodes[index],
                  nextFocusNode:
                      index + 1 < otpFocusNodes.length
                          ? otpFocusNodes[index + 1]
                          : null,
                );
              }),
            ),
            20.height,
            PrimaryOutlinedButton(
              text: otpSent ? "Resend OTP" : "Send OTP",
              isLoading: isSending,
              onPressed: onSendOtp,
              isEnabled: !isVerified,
            ),
            12.height,
            PrimaryButton(
              text: isVerified ? "Verified" : "Verify OTP",
              isLoading: isVerifying,
              onPressed: isVerified ? () {} : onVerifyOtp,
            ),
            12.height,
            Text(
              otpSent
                  ? "Didn't receive the code? You can resend it."
                  : "We will send a 4-digit code to your email.",
              style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpDigitField extends StatelessWidget {
  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(counterText: ''),
        style: AppFonts.semiBold(fontSize: 18),
        onChanged: (value) {
          if (value.isNotEmpty) {
            nextFocusNode?.requestFocus();
          }
        },
      ),
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep({
    required this.formKey,
    required this.role,
    required this.onRoleChanged,
  });

  final GlobalKey<FormState> formKey;
  final ClinicRole role;
  final ValueChanged<ClinicRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Role", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Choose the role for this team member.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            24.height,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ClinicRole.values.map((roleItem) {
                final isSelected = roleItem == role;
                return ChoiceChip(
                  label: Text(roleItem.label),
                  selected: isSelected,
                  onSelected: (_) => onRoleChanged(roleItem),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: AppFonts.semiBold(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary : AppColors.darkGrey,
                  ),
                );
              }).toList(),
            ),
            16.height,
            Text(
              "You can change roles later in settings.",
              style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityStep extends StatelessWidget {
  const _SecurityStep({
    required this.formKey,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Security", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Set a secure password for this account.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            24.height,
            Text('Password', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              controller: passwordController,
              hint: "At least 8 characters",
              obscureText: true,
              validator: (val) {
                if (val == null || val.length < 8) {
                  return "Password must be at least 8 characters";
                }
                return null;
              },
            ),
            16.height,
            Text('Confirm Password', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              controller: confirmPasswordController,
              hint: "Re-enter your password",
              obscureText: true,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return "Confirm your password";
                }
                if (val != passwordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
