import 'dart:io';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ClinicDocumentsStep extends StatefulWidget {
  const ClinicDocumentsStep({
    required this.formData,
    required this.formKey,
    super.key,
  });

  final Clinic formData;
  final GlobalKey formKey;

  @override
  State<ClinicDocumentsStep> createState() => _ClinicDocumentsStepState();
}

class _ClinicDocumentsStepState extends State<ClinicDocumentsStep> {
  Future<void> _pickCertificate(void Function(String path) onSelected) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    final path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    setState(() {
      onSelected(path);
    });
  }

  String _fileNameFromPath(String? path) {
    if (path == null || path.isEmpty) {
      return "No file selected";
    }
    return path.split(Platform.pathSeparator).last;
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
            Text("Clinic Documents", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Upload your clinic's certificate for verification.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            24.height,
            Text('Clinic Certificate', style: AppFonts.semiBold(fontSize: 12)),
            8.height,
            FormField<String>(
              initialValue: widget.formData.certificateUrl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Clinic certificate is required";
                }
                return null;
              },
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined),
                          12.width,
                          Expanded(
                            child: Text(
                              _fileNameFromPath(field.value),
                              style: AppFonts.regular(
                                fontSize: 12,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    8.height,
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryOutlinedButton(
                            onPressed: () async {
                              await _pickCertificate((path) {
                                widget.formData.certificateUrl = path;
                                field.didChange(path);
                              });
                            },
                            text:
                                field.value?.isNotEmpty == true
                                    ? "Change Certificate"
                                    : "Select Certificate",
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
            Text(
              "Accepted formats: PDF, JPG, PNG",
              style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
