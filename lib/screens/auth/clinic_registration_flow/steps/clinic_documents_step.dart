import 'dart:convert';
import 'dart:io';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      withData: kIsWeb,
    );

    final file = result?.files.single;
    if (file == null) return;

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) return;
      final ext = (file.extension ?? '').toLowerCase();
      final mime = _mimeFromExtension(ext);
      final dataUri = 'data:$mime;name=${file.name};base64,${base64Encode(bytes)}';
      setState(() => onSelected(dataUri));
    } else {
      final path = file.path;
      if (path == null || path.isEmpty) return;
      setState(() => onSelected(path));
    }
  }

  String _mimeFromExtension(String ext) {
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      default: return 'image/jpeg';
    }
  }

  String _fileNameFromPath(String? path) {
    if (path == null || path.isEmpty) return "No file selected";
    if (path.startsWith('data:')) {
      final match = RegExp(r';name=([^;,]+)').firstMatch(path);
      return match?.group(1) ?? 'Selected file';
    }
    return path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.black;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.45) : AppColors.grey;
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.65) : AppColors.black;
    final fileRowBg =
        isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.white;
    final fileRowBorder =
        isDark ? Colors.white.withValues(alpha: 0.14) : AppColors.divider;
    final fileTextColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : AppColors.darkGrey;
    final iconColor =
        isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.black;
    final hintColor =
        isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.grey;

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Clinic Documents",
              style: AppFonts.bold(fontSize: 24, color: titleColor),
            ),
            4.height,
            Text(
              "Upload your clinic's certificate for verification.",
              style: AppFonts.regular(color: subtitleColor, fontSize: 15),
            ),
            24.height,

            Text('Clinic Certificate',
                style: AppFonts.semiBold(fontSize: 14, color: labelColor)),
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
                        color: fileRowBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: fileRowBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, color: iconColor),
                          12.width,
                          Expanded(
                            child: Text(
                              _fileNameFromPath(field.value),
                              style: AppFonts.regular(
                                fontSize: 14,
                                color: fileTextColor,
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
                            text: field.value?.isNotEmpty == true
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
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFFF5252)
                                : AppColors.error,
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
              style: AppFonts.regular(fontSize: 13, color: hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
