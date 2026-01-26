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
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  @override
  Widget build(BuildContext context) {
    void toggleDay(String day) {}

    bool isDaySelected(String day) {
      return false;
    }

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Services & Hours", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Let patients know what you offer and when you’re open.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            24.height,

            // Services Offered
            Text('Services Offered', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            SelectableChips(
              items: ["Consultation", "Surgery", "Grooming", "Vaccination"],
              initialSelected:
                  formData.servicesOffered ??
                  [], // use saved services if editing
              onSelectionChanged: (selected) {
                formData.servicesOffered = selected;
              },
            ),

            24.height,

            // Working Hours
            // Text('Working Hours', style: AppFonts.semiBold(fontSize: 12)),
            // 12.height,
            Row(
              children: [
                Expanded(
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return TimePickerField(
                        label: "Opening Time",
                        value: formData.openingTime,
                        onTimeSelected: (time) {
                          setState(() {
                            formData.openingTime = time;
                          });
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
                          setState(() {
                            formData.closingTime = time;
                          });
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

            // Working Days
            Text('Working Days', style: AppFonts.semiBold(fontSize: 12)),
            8.height,
            SelectableChips(
              items: days,
              initialSelected:
                  formData.workingDays ?? [], // preselect if editing
              onSelectionChanged: (selected) {
                formData.workingDays = selected;
              },
            ),

            32.height,
          ],
        ),
      ),
    );
  }
}
