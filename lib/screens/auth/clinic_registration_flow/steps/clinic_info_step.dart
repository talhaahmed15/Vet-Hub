import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ClinicInfoStep extends StatefulWidget {
  const ClinicInfoStep({
    required this.formData,
    required this.formKey,
    super.key,
  });

  final Clinic formData;
  final GlobalKey formKey;

  @override
  State<ClinicInfoStep> createState() => _ClinicInfoStepState();
}

class _ClinicInfoStepState extends State<ClinicInfoStep> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Clinic Information", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Tell us a bit about your practice to get started.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            24.height,

            /// Clinic Name
            Text('Clinic Name', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              hintText: "e.g., Happy Paws Veterinary",
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Clinic name is required";
                }
                if (val.length < 3) {
                  return "Clinic name must be at least 3 characters";
                }
                return null;
              },
              onChanged: (val) {
                widget.formData.clinicName = val;
              },
            ),
            16.height,

            /// Address
            Text('Clinic Address', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              hintText: "123 Vet Street, City, State",
              keyboardType: TextInputType.streetAddress,
              prefixIcon: const Icon(Icons.location_on_outlined),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Address is required";
                }
                return null;
              },
              onChanged: (val) {
                widget.formData.clinicAddress = val;
              },
            ),
            16.height,

            /// Contact
            Text('Contact Number', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              hintText: "+1 (555) 000-0000",
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Contact number is required";
                }
                if (val.length < 7) {
                  return "Enter a valid phone number";
                }
                return null;
              },
              onChanged: (val) {
                widget.formData.contactNumber = val;
              },
            ),
            16.height,

            /// Website
            Text('Website', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              hintText: "www.happypaws.com",
              prefixIcon: const Icon(Icons.link),
              validator: (val) {
                if (val == null || val.isEmpty) return null;
                final uri = Uri.tryParse(val);
                if (uri == null || !val.contains("www")) {
                  return "Enter a valid website URL";
                }
                return null;
              },
              onChanged: (val) {
                widget.formData.website = val;
              },
            ),
            16.height,

            32.height,
          ],
        ),
      ),
    );
  }
}
