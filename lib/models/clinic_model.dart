class Clinic {
  String? clinicId;
  String? clinicCode;
  String? clinicName;
  String? clinicAddress;
  String? contactNumber;
  String? website;
  String? logoUrl;
  String? certificateUrl;
  String? tagLine;
  String? aboutClinic;
  List<String>? servicesOffered;
  List<String>? workingDays;
  String? openingTime;
  String? closingTime;
  bool isCertified;

  Clinic({
    this.clinicId,
    this.clinicCode,
    this.clinicName,
    this.clinicAddress,
    this.contactNumber,
    this.website,
    this.logoUrl,
    this.certificateUrl,
    this.tagLine,
    this.aboutClinic,
    this.servicesOffered,
    this.workingDays,
    this.openingTime,
    this.closingTime,
    this.isCertified = false,
  });

  /// Convert JSON / Map to Clinic object
  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      clinicId: map['clinic_id']?.toString(),
      clinicCode: map['clinic_code'] ?? '',
      clinicName: map['name'] ?? '',
      clinicAddress: map['address'] ?? '',
      contactNumber: map['contact_number'] ?? '',
      website: map['website'],
      logoUrl: map['logo_url'],
      certificateUrl: map['certificate_url'],
      tagLine: map['tag_line'],
      aboutClinic: map['about_clinic'],
      servicesOffered: map['services_offered'] != null
          ? List<String>.from(map['services_offered'])
          : null,
      workingDays: map['working_days'] != null
          ? List<String>.from(map['working_days'])
          : null,
      openingTime: map['opening_time'],
      closingTime: map['closing_time'],
      isCertified: map['is_certified'] ?? false,
    );
  }

  /// Convert Clinic object to Map / JSON
  Map<String, dynamic> toMap() {
    return {
      // 'clinic_id': clinicId,
      'clinic_code': clinicCode,
      'name': clinicName,
      'address': clinicAddress,
      'contact_number': contactNumber,
      'website': website,
      'logo_url': logoUrl,
      'certificate_url': certificateUrl,
      'tag_line': tagLine,
      'about_clinic': aboutClinic,
      'services_offered': servicesOffered,
      'working_days': workingDays,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'is_certified': isCertified,
    };
  }

  Clinic copyWith({
    String? clinicId,
    String? clinicCode,
    String? name,
    String? address,
    String? contactNumber,
    String? website,
    String? logoUrl,
    String? certificateUrl,
    String? tagLine,
    String? aboutClinic,
    List<String>? servicesOffered,
    List<String>? workingDays,
    String? openingTime,
    String? closingTime,
    bool? isCertified,
  }) {
    return Clinic(
      clinicId: clinicId ?? this.clinicId,
      clinicCode: clinicCode ?? this.clinicCode,
      clinicName: name ?? clinicName,
      clinicAddress: address ?? this.clinicAddress,
      contactNumber: contactNumber ?? this.contactNumber,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      tagLine: tagLine ?? this.tagLine,
      aboutClinic: aboutClinic ?? this.aboutClinic,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      workingDays: workingDays ?? this.workingDays,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      isCertified: isCertified ?? this.isCertified,
    );
  }
}
