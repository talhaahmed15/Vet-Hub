import 'dart:io';

import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/services/clinic_service.dart';
import 'package:clinic_management_app/services/image_service.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/primary_button.dart';
import 'package:clinic_management_app/widgets/selectable_chips.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:clinic_management_app/widgets/time_picker_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({super.key});

  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taglineController = TextEditingController();
  final _aboutController = TextEditingController();

  final ClinicService _clinicService = ClinicService();
  final ImageService _imageService = ImageService();
  final List<String> _days = const [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];
  final List<String> _servicesCatalog = const [
    "Consultation",
    "Surgery",
    "Grooming",
    "Vaccination",
  ];

  Clinic? _clinic;
  bool _loading = true;
  bool _saving = false;
  String? _logoPath;
  String? _certificatePath;
  List<String> _services = [];
  List<String> _workingDays = [];
  String? _openingTime;
  String? _closingTime;

  @override
  void initState() {
    super.initState();
    _loadClinic();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _taglineController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadClinic() async {
    final data = await Storage.getClinicData();
    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    var clinic = Clinic.fromMap(data);
    final code = clinic.clinicCode?.trim();
    if (code != null && code.isNotEmpty) {
      final refreshed = await _clinicService.getClinicByCode(code);
      if (refreshed != null) {
        clinic = refreshed;
        await Storage.saveClinic(refreshed);
      }
    }

    _clinic = clinic;
    _populateControllers(clinic);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _populateControllers(Clinic clinic) {
    _nameController.text = clinic.clinicName ?? '';
    _addressController.text = clinic.clinicAddress ?? '';
    _phoneController.text = clinic.contactNumber ?? '';
    _websiteController.text = clinic.website ?? '';
    _taglineController.text = clinic.tagLine ?? '';
    _aboutController.text = clinic.aboutClinic ?? '';
    _logoPath = clinic.logoUrl;
    _certificatePath = clinic.certificateUrl;
    _services = List<String>.from(clinic.servicesOffered ?? []);
    _workingDays = List<String>.from(clinic.workingDays ?? []);
    _openingTime = clinic.openingTime;
    _closingTime = clinic.closingTime;
  }

  Future<void> _pickLogo({
    required void Function(String path) onSelected,
    required void Function(String path) onFieldChanged,
  }) async {
    final path = await _imageService.pickImageFromGallery();
    if (path == null || path.isEmpty) {
      return;
    }
    setState(() {
      _logoPath = path;
      onSelected(path);
    });
    onFieldChanged(path);
  }

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
      _certificatePath = path;
      onSelected(path);
    });
  }

  Widget _imagePreview(String? path) {
    final hasPath = path != null && path.isNotEmpty;
    final isRemote = hasPath &&
        (path.startsWith('http://') || path.startsWith('https://'));

    return CircleAvatar(
      radius: 42,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: hasPath
          ? ClipOval(
              child: isRemote
                  ? Image.network(
                      path,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grey,
                          size: 28,
                        );
                      },
                    )
                  : Image.file(
                      File(path),
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grey,
                          size: 28,
                        );
                      },
                    ),
            )
          : const Icon(
              Icons.photo_outlined,
              color: AppColors.grey,
              size: 28,
            ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final clinic = _clinic;
    if (clinic == null) return;

    setState(() => _saving = true);
    try {
      final updated = clinic.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        logoUrl: _logoPath,
        certificateUrl: _certificatePath,
        tagLine: _taglineController.text.trim().isEmpty
            ? null
            : _taglineController.text.trim(),
        aboutClinic: _aboutController.text.trim().isEmpty
            ? null
            : _aboutController.text.trim(),
        servicesOffered: _services,
        workingDays: _workingDays,
        openingTime: _openingTime,
        closingTime: _closingTime,
        isCertified: false,
      );

      final saved = await _clinicService.updateClinic(clinic: updated);
      if (saved != null) {
        await Storage.saveClinic(saved);
        _clinic = saved;
        AppToast.success(
          context,
          'Profile updated. Your clinic is now under review.',
        );
      } else {
        AppToast.error(context, 'Unable to update clinic profile.');
      }
    } catch (e) {
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinic = _clinic;
    final isCertified = clinic?.isCertified == true;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Clinic Profile'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : clinic == null
              ? Center(
                  child: Text(
                    'Clinic not found.',
                    style: AppFonts.regular(),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusBanner(isCertified: isCertified),
                        16.height,
                        _InfoBanner(),
                        16.height,
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('Clinic Information'),
                              12.height,
                              _FieldLabel('Clinic Name'),
                              CustomTextField(
                                controller: _nameController,
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
                              ),
                              16.height,
                              _FieldLabel('Clinic Address'),
                              CustomTextField(
                                controller: _addressController,
                                hintText: "123 Vet Street, City, State",
                                keyboardType: TextInputType.streetAddress,
                                prefixIcon:
                                    const Icon(Icons.location_on_outlined),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "Address is required";
                                  }
                                  return null;
                                },
                              ),
                              16.height,
                              _FieldLabel('Contact Number'),
                              CustomTextField(
                                controller: _phoneController,
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
                              ),
                              16.height,
                              _FieldLabel('Website'),
                              CustomTextField(
                                controller: _websiteController,
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
                              ),
                              20.height,
                              const _SectionLabel('Clinic Branding'),
                              12.height,
                              _FieldLabel('Clinic Logo'),
                              8.height,
                              FormField<String>(
                                initialValue: _logoPath,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Clinic logo is required";
                                  }
                                  return null;
                                },
                                builder: (field) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _imagePreview(field.value),
                                          12.width,
                                          IconButton(
                                            onPressed: () => _pickLogo(
                                              onSelected: (path) {},
                                              onFieldChanged: field.didChange,
                                            ),
                                            icon: const Icon(
                                              Icons.camera_alt_outlined,
                                            ),
                                            tooltip: field.value?.isNotEmpty ==
                                                    true
                                                ? "Change clinic logo"
                                                : "Select clinic logo",
                                          ),
                                        ],
                                      ),
                                      if (field.hasError)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
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
                              _FieldLabel('Clinic Tagline'),
                              4.height,
                              CustomTextField(
                                controller: _taglineController,
                                hintText: "Caring for pets, one visit at a time",
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return "Tagline is required";
                                  }
                                  return null;
                                },
                              ),
                              16.height,
                              _FieldLabel('About Clinic'),
                              4.height,
                              CustomTextField(
                                controller: _aboutController,
                                hintText: "Brief description of your clinic",
                                maxLines: 4,
                                validator: (val) {
                                  if (val == null || val.length < 20) {
                                    return "Please write at least 20 characters";
                                  }
                                  return null;
                                },
                              ),
                              20.height,
                              const _SectionLabel('Clinic Documents'),
                              12.height,
                              _FieldLabel('Clinic Certificate'),
                              8.height,
                              FormField<String>(
                                initialValue: _certificatePath,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Clinic certificate is required";
                                  }
                                  return null;
                                },
                                builder: (field) {
                                  final hasCertificate =
                                      field.value != null &&
                                      field.value!.isNotEmpty;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.divider,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              hasCertificate
                                                  ? Icons.verified_outlined
                                                  : Icons.error_outline,
                                              color: hasCertificate
                                                  ? AppColors.primary
                                                  : AppColors.grey,
                                              size: 18,
                                            ),
                                            10.width,
                                            Expanded(
                                              child: Text(
                                                hasCertificate
                                                    ? "Certificate uploaded"
                                                    : "No certificate uploaded",
                                                style: AppFonts.regular(
                                                  fontSize: 12,
                                                  color: AppColors.darkGrey,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () async {
                                                await _pickCertificate((path) {
                                                  field.didChange(path);
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.upload_file_outlined,
                                              ),
                                              tooltip: "Upload certificate",
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (field.hasError)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
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
                                style: AppFonts.regular(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              20.height,
                              const _SectionLabel('Services & Hours'),
                              12.height,
                              _FieldLabel('Services Offered'),
                              4.height,
                              SelectableChips(
                                items: _servicesCatalog,
                                initialSelected: _services,
                                onSelectionChanged: (selected) {
                                  _services = selected;
                                },
                              ),
                              24.height,
                              Row(
                                children: [
                                  Expanded(
                                    child: TimePickerField(
                                      label: "Opening Time",
                                      value: _openingTime,
                                      onTimeSelected: (time) {
                                        setState(() {
                                          _openingTime = time;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please select opening time";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  12.width,
                                  Expanded(
                                    child: TimePickerField(
                                      label: "Closing Time",
                                      value: _closingTime,
                                      onTimeSelected: (time) {
                                        setState(() {
                                          _closingTime = time;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please select closing time";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              16.height,
                              _FieldLabel('Working Days'),
                              8.height,
                              SelectableChips(
                                items: _days,
                                initialSelected: _workingDays,
                                onSelectionChanged: (selected) {
                                  _workingDays = selected;
                                },
                              ),
                              20.height,
                              Text(
                                'Saving updates will place your clinic under review until approved.',
                                style: AppFonts.regular(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              16.height,
                              PrimaryButton(
                                text: 'Save Changes',
                                onPressed: _save,
                                isLoading: _saving,
                                isEnabled: !_saving,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppFonts.semiBold(fontSize: 12, color: AppColors.black),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: AppFonts.semiBold(
            fontSize: 12,
            letterSpacing: 1,
            color: AppColors.grey,
          ),
        ),
        8.width,
        Expanded(child: Divider(color: AppColors.divider.withOpacity(0.8))),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          8.width,
          Expanded(
            child: Text(
              'Updates to your clinic profile require review. Your clinic will be marked under review until approved.',
              style: AppFonts.regular(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isCertified;
  const _StatusBanner({required this.isCertified});

  @override
  Widget build(BuildContext context) {
    final color = isCertified ? AppColors.primary : Colors.orange;
    final label = isCertified ? 'Certified' : 'Under Review';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isCertified ? Icons.verified : Icons.hourglass_top,
            size: 18,
            color: color,
          ),
          8.width,
          Text(
            'Status: $label',
            style: AppFonts.semiBold(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
