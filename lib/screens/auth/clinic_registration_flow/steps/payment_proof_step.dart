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

class PaymentProofStep extends StatefulWidget {
  const PaymentProofStep({
    required this.formData,
    required this.formKey,
    super.key,
  });

  final Clinic formData;
  final GlobalKey formKey;

  @override
  State<PaymentProofStep> createState() => _PaymentProofStepState();
}

class _PaymentProofStepState extends State<PaymentProofStep> {
  Future<void> _pickProof(void Function(String path) onSelected) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );

    final file = result?.files.single;
    if (file == null) return;

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) return;
      final ext = (file.extension ?? '').toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mime;name=${file.name};base64,${base64Encode(bytes)}';
      setState(() => onSelected(dataUri));
    } else {
      final path = file.path;
      if (path == null || path.isEmpty) return;
      setState(() => onSelected(path));
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
              "Payment Proof",
              style: AppFonts.bold(fontSize: 24, color: titleColor),
            ),
            4.height,
            Text(
              "Send the amount to the account below, then upload your payment screenshot.",
              style: AppFonts.regular(color: subtitleColor, fontSize: 15),
            ),
            20.height,
            _BankDetailsCard(isDark: isDark),
            20.height,

            Text('Payment Screenshot',
                style: AppFonts.semiBold(fontSize: 14, color: labelColor)),
            8.height,
            FormField<String>(
              initialValue: widget.formData.paymentProofUrl,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Payment screenshot is required";
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
                          Icon(Icons.image_outlined, color: iconColor),
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
                              await _pickProof((path) {
                                widget.formData.paymentProofUrl = path;
                                field.didChange(path);
                              });
                            },
                            text: field.value?.isNotEmpty == true
                                ? "Change Screenshot"
                                : "Upload Screenshot",
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
            12.height,
            Text(
              "Accepted formats: JPG, PNG",
              style: AppFonts.regular(fontSize: 13, color: hintColor),
            ),
            32.height,
          ],
        ),
      ),
    );
  }
}

class _BankDetailsCard extends StatelessWidget {
  final bool isDark;
  const _BankDetailsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.primary.withValues(alpha: 0.05);
    final borderColor = isDark
        ? AppColors.primary.withValues(alpha: 0.25)
        : AppColors.primary.withValues(alpha: 0.2);
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bank Details",
              style: AppFonts.semiBold(fontSize: 14, color: titleColor)),
          12.height,
          _DetailRow(label: "Bank Name", value: "VetHub National Bank", isDark: isDark),
          _DetailRow(label: "Account Name", value: "VetHub Clinics Ltd.", isDark: isDark),
          _DetailRow(label: "Account Number", value: "0123456789", isDark: isDark),
          _DetailRow(label: "Routing Number", value: "110000000", isDark: isDark),
          _DetailRow(label: "Reference", value: "Your clinic name", isDark: isDark),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.38) : AppColors.grey;
    final valueColor =
        isDark ? Colors.white.withValues(alpha: 0.8) : AppColors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.regular(fontSize: 12, color: labelColor),
            ),
          ),
          Text(
            value,
            style: AppFonts.semiBold(fontSize: 12, color: valueColor),
          ),
        ],
      ),
    );
  }
}
