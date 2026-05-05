import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/selectable_chips.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:clinic_management_app/widgets/time_picker_field.dart';
import 'package:flutter/material.dart';

class ServicesAndHoursStep extends StatelessWidget {
  const ServicesAndHoursStep({
    required this.formData,
    required this.formKey,
    super.key,
  });

  final Clinic formData;
  final GlobalKey formKey;

  final List<String> days = const [
    "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun",
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.black;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.grey;
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.65) : AppColors.black;

    const defaultWorkingDays = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    final hasWorkingDays =
        formData.workingDays != null && formData.workingDays!.isNotEmpty;
    final initialWorkingDays = hasWorkingDays
        ? List<String>.from(formData.workingDays!)
        : List<String>.from(defaultWorkingDays);
    if (!hasWorkingDays) {
      formData.workingDays = List<String>.from(initialWorkingDays);
    }

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Services & Hours",
              style: AppFonts.bold(fontSize: 22, color: titleColor),
            ),
            4.height,
            Text(
              "Let patients know what you offer and when you're open.",
              style: AppFonts.regular(color: subtitleColor, fontSize: 14),
            ),
            24.height,

            Text('Services Offered',
                style: AppFonts.semiBold(fontSize: 12, color: labelColor)),
            4.height,
            SelectableChips(
              items: ["Consultation", "Surgery", "Grooming", "Vaccination"],
              initialSelected: formData.servicesOffered ?? [],
              onSelectionChanged: (selected) {
                formData.servicesOffered = selected;
              },
            ),

            24.height,

            Row(
              children: [
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return TimePickerField(
                        label: "Opening Time",
                        value: formData.openingTime,
                        onTimeSelected: (time) {
                          setState(() => formData.openingTime = time);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select opening time";
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ),
                12.width,
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return TimePickerField(
                        label: "Closing Time",
                        value: formData.closingTime,
                        onTimeSelected: (time) {
                          setState(() => formData.closingTime = time);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select closing time";
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            16.height,

            Text('Working Days',
                style: AppFonts.semiBold(fontSize: 12, color: labelColor)),
            8.height,
            FormField<List<String>>(
              initialValue: initialWorkingDays,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please select working days";
                }
                return null;
              },
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableChips(
                      items: days,
                      initialSelected: field.value ?? initialWorkingDays,
                      onSelectionChanged: (selected) {
                        formData.workingDays = selected;
                        field.didChange(selected);
                      },
                    ),
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
            ),

            32.height,
          ],
        ),
      ),
    );
  }
}
