import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/models/package_plan.dart';
import 'package:clinic_management_app/services/package_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class PackageSelectionStep extends StatefulWidget {
  const PackageSelectionStep({
    required this.formData,
    required this.formKey,
    this.onPackageChanged,
    super.key,
  });

  final Clinic formData;
  final GlobalKey<FormState> formKey;
  final ValueChanged<PackagePlan?>? onPackageChanged;

  @override
  State<PackageSelectionStep> createState() => _PackageSelectionStepState();
}

class _PackageSelectionStepState extends State<PackageSelectionStep> {
  final PackageService _packageService = PackageService();
  late Future<List<PackagePlan>> _packagesFuture;
  PackagePlan? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _packagesFuture = _packageService.fetchPackages();
    _packagesFuture.then((packages) {
      if (!mounted) return;
      _selectDefaultPackage(packages);
    });
  }

  void _selectDefaultPackage(List<PackagePlan> packages) {
    if (_selectedPackage != null || packages.isEmpty) return;
    final existingId = widget.formData.packageId;
    if (existingId != null && existingId.isNotEmpty) {
      final selected = packages.firstWhere(
        (pkg) => pkg.packageId == existingId,
        orElse: () => packages.first,
      );
      setState(() => _selectedPackage = selected);
      widget.onPackageChanged?.call(selected);
    } else {
      final trial = packages.firstWhere(
        (pkg) => pkg.packageKey == 'trial',
        orElse: () => packages.first,
      );
      setState(() => _selectedPackage = trial);
      widget.formData.packageId = trial.packageId;
      widget.formData.packageKey = trial.packageKey;
      widget.formData.packageName = trial.name;
      widget.onPackageChanged?.call(trial);
    }
  }

  void _setSelected(PackagePlan? pkg, FormFieldState<PackagePlan> field) {
    setState(() {
      _selectedPackage = pkg;
      widget.formData.packageId = pkg?.packageId;
      widget.formData.packageKey = pkg?.packageKey;
      widget.formData.packageName = pkg?.name;
    });
    field.didChange(pkg);
    widget.onPackageChanged?.call(pkg);
  }

  String _priceLabel(PackagePlan pkg) {
    if (pkg.priceCents <= 0) return 'Free';
    final price = (pkg.priceCents / 100).toStringAsFixed(2);
    return '\$$price / ${pkg.billingCycle}';
  }

  List<String> _featuresFor(PackagePlan pkg) {
    switch (pkg.packageKey) {
      case 'trial':
        return const [
          'Full access to core features',
          'Limited to one location',
          'Email support',
        ];
      case 'basic':
        return const [
          'Unlimited appointments',
          'Team scheduling',
          'Basic analytics',
        ];
      case 'pro':
        return const [
          'Multi-location support',
          'Automated reminders',
          'Advanced reporting',
        ];
      case 'enterprise':
        return const [
          'Custom integrations',
          'Dedicated success manager',
          'Priority support',
        ];
      default:
        return const [
          'Appointment management',
          'Client records',
          'Billing essentials',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.black;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.grey;

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Choose a Package",
              style: AppFonts.bold(fontSize: 22, color: titleColor),
            ),
            4.height,
            Text(
              "Pick the plan that best fits your clinic today. You can upgrade any time.",
              style: AppFonts.regular(color: subtitleColor, fontSize: 14),
            ),
            24.height,
            FutureBuilder<List<PackagePlan>>(
              future: _packagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    "Unable to load packages. Try again.",
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  );
                }

                final packages = snapshot.data ?? const [];

                return FormField<PackagePlan>(
                  initialValue: _selectedPackage,
                  validator: (value) =>
                      value == null ? "Please select a package" : null,
                  builder: (field) {
                    final selected = _selectedPackage;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...packages.map((pkg) {
                          final isSelected =
                              selected?.packageId == pkg.packageId;
                          return _PackageCard(
                            packagePlan: pkg,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () => _setSelected(pkg, field),
                            priceLabel: _priceLabel(pkg),
                            features: _featuresFor(pkg),
                          );
                        }),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              field.errorText ?? "",
                              style: AppFonts.regular(
                                fontSize: 10,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            32.height,
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.packagePlan,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.priceLabel,
    required this.features,
  });

  final PackagePlan packagePlan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final String priceLabel;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final highlight = isSelected ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.16) : AppColors.divider);
    final bg = isSelected
        ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.06)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.white);
    final nameColor = isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.black;
    final priceTextColor = isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.black;
    final billingColor = isDark ? Colors.white.withValues(alpha: 0.38) : AppColors.grey;
    final featureColor = isDark ? Colors.white.withValues(alpha: 0.6) : AppColors.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: highlight, width: isSelected ? 2 : 1),
          boxShadow: isSelected && isDark
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    packagePlan.name,
                    style: AppFonts.semiBold(fontSize: 16, color: nameColor),
                  ),
                ),
                if (packagePlan.trialDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${packagePlan.trialDays} days free",
                      style: AppFonts.regular(
                          fontSize: 10, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            8.height,
            Row(
              children: [
                Text(priceLabel,
                    style: AppFonts.bold(fontSize: 14, color: priceTextColor)),
                8.width,
                Expanded(
                  child: Text(
                    "Billed ${packagePlan.billingCycle}",
                    style: AppFonts.regular(fontSize: 12, color: billingColor),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
              ],
            ),
            12.height,
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 16),
                    8.width,
                    Expanded(
                      child: Text(
                        feature,
                        style: AppFonts.regular(
                            fontSize: 12, color: featureColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
