import 'package:clinic_management_app/models/clinic_model.dart';

final testClinic = Clinic(
  clinicName: 'Healthy Life Medical Center',
  clinicAddress: '123 Main Road, Lahore',
  contactNumber: '+92 300 1234567',
  website: 'https://healthylifeclinic.pk',
  logoUrl: 'https://cdn.healthylifeclinic.pk/logo.png',
  certificateUrl: 'https://cdn.healthylifeclinic.pk/certificate.pdf',
  tagLine: 'Care You Can Trust',
  aboutClinic:
      'Healthy Life Medical Center provides quality healthcare with experienced doctors and modern facilities.',
  servicesOffered: [
    'General Consultation',
    'Pediatrics',
    'Dental Care',
    'Cardiology',
  ],
  workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
  openingTime: '09:00',
  closingTime: '18:00',
  isCertified: true,
);
