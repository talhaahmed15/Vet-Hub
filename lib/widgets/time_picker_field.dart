import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_dialogs.dart';
import 'package:flutter/material.dart';

class TimePickerField extends StatelessWidget {
  final String? label;
  final String? value;
  final ValueChanged<String> onTimeSelected;
  final String? Function(String?)? validator;

  const TimePickerField({
    super.key,
    this.label,
    this.value,
    required this.onTimeSelected,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Text(label!, style: AppFonts.semiBold(fontSize: 12)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final selectedTime = await AppDialog.pickTime(context: context);
                if (selectedTime != null) {
                  onTimeSelected(selectedTime);
                  state.didChange(selectedTime); // ✅ Update FormField state
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: state.hasError ? AppColors.error : AppColors.divider,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: AppColors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value ?? "Select Time",
                      style: AppFonts.regular(
                        fontSize: 12,
                        color: value != null ? AppColors.black : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  state.errorText ?? "",
                  style: AppFonts.regular(color: AppColors.error, fontSize: 10),
                ),
              ),
          ],
        );
      },
    );
  }
}
