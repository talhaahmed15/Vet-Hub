import 'dart:io';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/services/image_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ClinicBrandingStep extends StatefulWidget {
  const ClinicBrandingStep({
    required this.formData,
    required this.formKey,
    super.key,
  });

  final Clinic formData;
  final GlobalKey formKey;

  @override
  State<ClinicBrandingStep> createState() => _ClinicBrandingStepState();
}

class _ClinicBrandingStepState extends State<ClinicBrandingStep> {
  final ImageService _imageService = ImageService();

  Future<void> _pickImage({
    required void Function(String path) onSelected,
    required void Function(String path) onFieldChanged,
  }) async {
    final path = await _imageService.pickImageFromGallery();
    if (path == null || path.isEmpty) {
      return;
    }
    setState(() {
      onSelected(path);
    });
    onFieldChanged(path);
  }

  Widget _imagePreview(String? path) {
    final hasPath = path != null && path.isNotEmpty;
    final isRemote = hasPath &&
        (path.startsWith('http://') || path.startsWith('https://'));

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: hasPath
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isRemote
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(File(path), fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                "No image selected",
                style: AppFonts.regular(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ),
    );
  }

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
            Text("Clinic Branding", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Customize how your clinic appears to patients.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            24.height,

            /// Clinic Logo
            Text('Clinic Logo', style: AppFonts.semiBold(fontSize: 12)),
            8.height,
            FormField<String>(
              initialValue: widget.formData.logoUrl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Clinic logo is required";
                }
                return null;
              },
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _imagePreview(field.value),
                    8.height,
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryOutlinedButton(
                            onPressed: () => _pickImage(
                              onSelected: (path) {
                                widget.formData.logoUrl = path;
                              },
                              onFieldChanged: field.didChange,
                            ),
                            text:
                                field.value?.isNotEmpty == true
                                    ? "Change Clinic Logo"
                                    : "Select Clinic Logo",
                          ),
                        ),
                      ],
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
            16.height,

            /// Tagline
            Text('Clinic Tagline', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              hintText: "Caring for pets, one visit at a time",
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return "Tagline is required";
                }
                return null;
              },
              onChanged: (val) {
                widget.formData.tagLine = val;
              },
            ),
            16.height,

            /// About
            Text('About Clinic', style: AppFonts.semiBold(fontSize: 12)),
            4.height,
            CustomTextField(
              hintText: "Brief description of your clinic",
              maxLines: 4,
              validator: (val) {
                if (val == null || val.length < 20) {
                  return "Please write at least 20 characters";
                }
                return null;
              },
              onChanged: (val) {
                widget.formData.aboutClinic = val;
              },
            ),
          ],
        ),
      ),
    );
  }
}
