import 'dart:io';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/outline_button.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:file_picker/file_picker.dart';
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
            Text("Payment Proof", style: AppFonts.bold(fontSize: 22)),
            4.height,
            Text(
              "Send the amount to the account below, then upload your payment screenshot.",
              style: AppFonts.regular(color: AppColors.grey, fontSize: 14),
            ),
            20.height,
            _BankDetailsCard(),
            20.height,
            Text('Payment Screenshot', style: AppFonts.semiBold(fontSize: 12)),
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
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined),
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
                              await _pickProof((path) {
                                widget.formData.paymentProofUrl = path;
                                field.didChange(path);
                              });
                            },
                            text:
                                field.value?.isNotEmpty == true
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
                            fontSize: 10,
                            color: AppColors.error,
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
              style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
            ),
            32.height,
          ],
        ),
      ),
    );
  }
}

class _BankDetailsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bank Details", style: AppFonts.semiBold(fontSize: 14)),
          12.height,
          _DetailRow(label: "Bank Name", value: "VetHub National Bank"),
          _DetailRow(label: "Account Name", value: "VetHub Clinics Ltd."),
          _DetailRow(label: "Account Number", value: "0123456789"),
          _DetailRow(label: "Routing Number", value: "110000000"),
          _DetailRow(label: "Reference", value: "Your clinic name"),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
            ),
          ),
          Text(
            value,
            style: AppFonts.semiBold(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
