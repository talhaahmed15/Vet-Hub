import 'package:clinic_management_app/bloc/clinic_account_signup/clinic_account_signup_cubit.dart';
import 'package:clinic_management_app/bloc/clinic_account_signup/clinic_account_signup_state.dart';
import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/models/clinic_role.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClinicAccountSignupFlow extends StatefulWidget {
  const ClinicAccountSignupFlow({super.key, this.clinic});

  final Clinic? clinic;

  @override
  State<ClinicAccountSignupFlow> createState() =>
      _ClinicAccountSignupFlowState();
}

class _ClinicAccountSignupFlowState extends State<ClinicAccountSignupFlow> {
  int _currentStep = 0;
  late final ClinicAccountSignupCubit _signupCubit;

  final _infoFormKey = GlobalKey<FormState>();
  final _roleFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ClinicRole _role = ClinicRole.vet;

  List<GlobalKey<FormState>> get _formKeys => [
    _infoFormKey,
    _roleFormKey,
    _securityFormKey,
  ];

  @override
  void initState() {
    super.initState();
    _signupCubit = ClinicAccountSignupCubit();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _signupCubit.close();
    super.dispose();
  }

  void _nextStep() {
    final currentForm = _formKeys[_currentStep];
    if (currentForm.currentState?.validate() ?? false) {
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

    try {
      final clinicCode =
          widget.clinic?.clinicCode ?? await Storage.getClinicCode();
      if (clinicCode == null || clinicCode.isEmpty) {
        throw "Missing clinic code. Please join the clinic again.";
      }

      await _signupCubit.submitAccount(
        clinicCode: clinicCode,
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: _role,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
    } catch (e) {
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _signupCubit,
      child: BlocListener<ClinicAccountSignupCubit, ClinicAccountSignupState>(
        listenWhen: (previous, current) {
          return previous.message != current.message ||
              previous.error != current.error ||
              previous.submitSuccess != current.submitSuccess;
        },
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            AppToast.error(context, state.error!);
          }
          if (state.message != null && state.message!.isNotEmpty) {
            AppToast.success(context, state.message!);
          }
          if (state.submitSuccess) {
            NavigatorHelper.pop(context);
          }
        },
        child: BlocBuilder<ClinicAccountSignupCubit, ClinicAccountSignupState>(
          builder: (context, state) {
            final isLastStep = _currentStep == _formKeys.length - 1;
            final isLoading = isLastStep ? state.isSubmitting : false;
            return Scaffold(
              backgroundColor: AppColors.white,
              appBar: const CustomAppBar(title: "Clinic Account Signup"),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      text: isLastStep ? "Create Account" : "Continue",
                      isLoading: isLoading,
                      onPressed: () {
                        if (isLastStep) {
                          _submit();
                        } else {
                          _nextStep();
                        }
                      },
                    ),
                    TextButton(
                      onPressed: state.isSubmitting ? null : _previousStep,
                      child: Text(
                        "Back",
                        style: AppFonts.regular(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              body: PageContent(
                maxWidth: 480,
                fillHeight: true,
                child: SafeArea(
                  child: Column(
                    children: [
                      _ProgressHeader(
                        step: _currentStep,
                        total: _formKeys.length,
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _currentStep,
                          children: [
                            _AccountInfoStep(
                              formKey: _infoFormKey,
                              fullNameController: _fullNameController,
                              usernameController: _usernameController,
                              phoneController: _phoneController,
                            ),
                            _RoleStep(
                              formKey: _roleFormKey,
                              role: _role,
                              onRoleChanged: (role) =>
                                  setState(() => _role = role),
                            ),
                            _SecurityStep(
                              formKey: _securityFormKey,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    required this.usernameController,
    required this.phoneController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController usernameController;
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
              hintText: "Jane Doe",
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Full name is required";
                }
                return null;
              },
            ),
            16.height,
            Text('Username', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              controller: usernameController,
              hintText: "vetflow_admin",
              keyboardType: TextInputType.text,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Username is required";
                }
                if (val.trim().length < 3) {
                  return "Username must be at least 3 characters";
                }
                return null;
              },
            ),
            16.height,
            Text('Phone Number', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              controller: phoneController,
              hintText: "+1 (555) 000-0000",
              keyboardType: TextInputType.phone,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Phone number is required";
                }
                if (val.trim().length < 5) {
                  return "Enter a valid phone number";
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
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
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
              hintText: "At least 8 characters",
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
              hintText: "Re-enter your password",
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
