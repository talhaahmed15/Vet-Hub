import 'dart:typed_data';

import 'package:clinic_management_app/bloc/appointment/appointment_flow_cubit.dart';
import 'package:clinic_management_app/models/clinic_model.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:clinic_management_app/utils/url_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AppointmentSummaryPdf {
  static Future<Uint8List> build({
    required AppointmentFlowState state,
  }) async {
    final clinic = await _loadClinic();
    final logoBytes = await _loadLogoBytes(clinic?.logoUrl);
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final doc = pw.Document();
    final primary = PdfColor.fromInt(0xFF1D4ED8);
    final subtle = PdfColor.fromInt(0xFFF1F5F9);
    final textMuted = PdfColor.fromInt(0xFF64748B);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build:
            (context) => [
              _buildHeader(
                clinic: clinic,
                logoBytes: logoBytes,
                primary: primary,
              ),
              pw.SizedBox(height: 18),
              _buildMetaRow(
                date: dateFormat.format(now),
                time: timeFormat.format(now),
                petName: state.petName,
                ownerName: state.ownerName,
                textMuted: textMuted,
              ),
              pw.SizedBox(height: 18),
              _sectionTitle('Patient & Owner', primary),
              pw.SizedBox(height: 6),
              _infoCard(
                subtle: subtle,
                children: [
                  _infoRow(
                    'Pet',
                    _joinParts([
                      state.petName,
                      state.petSpecies,
                      state.petBreed,
                      state.petAge.isEmpty ? '' : '${state.petAge} yrs',
                    ]),
                    textMuted,
                  ),
                  _infoRow(
                    'Owner',
                    _joinParts([state.ownerName, state.ownerPhone]),
                    textMuted,
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Vitals', primary),
              pw.SizedBox(height: 6),
              _infoCard(
                subtle: subtle,
                children: [
                  _infoRow(
                    'Temperature',
                    state.temperature.isEmpty
                        ? 'Not recorded'
                        : '${state.temperature} F',
                    textMuted,
                  ),
                  _infoRow(
                    'Heart Rate',
                    state.heartRate.isEmpty
                        ? 'Not recorded'
                        : '${state.heartRate} bpm',
                    textMuted,
                  ),
                  _infoRow(
                    'Weight',
                    state.weightKg.isEmpty
                        ? 'Not recorded'
                        : '${state.weightKg} kg',
                    textMuted,
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Appointment', primary),
              pw.SizedBox(height: 6),
              _infoCard(
                subtle: subtle,
                children: [
                  _infoRow(
                    'Reason',
                    state.appointmentReason.trim().isEmpty
                        ? 'Not provided'
                        : state.appointmentReason.trim(),
                    textMuted,
                  ),
                  _infoRow(
                    'Condition Status',
                    state.conditionStatus.trim().isEmpty
                        ? 'Not provided'
                        : state.conditionStatus.trim(),
                    textMuted,
                  ),
                  _infoRow(
                    'Condition Notes',
                    state.conditionNotes.trim().isEmpty
                        ? 'Not provided'
                        : state.conditionNotes.trim(),
                    textMuted,
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              _sectionTitle('Prescriptions', primary),
              pw.SizedBox(height: 6),
              _prescriptionsTable(
                prescriptions: state.prescriptions,
                textMuted: textMuted,
                subtle: subtle,
              ),
              pw.SizedBox(height: 22),
              pw.Divider(color: subtle),
              pw.SizedBox(height: 10),
              pw.Text(
                'Thank you for trusting ${clinic?.clinicName ?? 'your clinic'}.',
                style: pw.TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader({
    required Clinic? clinic,
    required Uint8List? logoBytes,
    required PdfColor primary,
  }) {
    final clinicName = clinic?.clinicName?.trim().isNotEmpty == true
        ? clinic!.clinicName!.trim()
        : 'Vet Clinic';
    final tagline =
        clinic?.tagLine?.trim().isNotEmpty == true ? clinic!.tagLine! : null;
    final address = clinic?.clinicAddress?.trim();
    final phone = clinic?.contactNumber?.trim();
    final website = clinic?.website?.trim();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoBytes != null)
            pw.Container(
              height: 52,
              width: 52,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
              ),
              child: pw.Image(pw.MemoryImage(logoBytes)),
            )
          else
            pw.Container(
              height: 52,
              width: 52,
              decoration: pw.BoxDecoration(
                color: primary,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                clinicName.isNotEmpty ? clinicName.substring(0, 1) : 'V',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  clinicName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0F172A),
                  ),
                ),
                if (tagline != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    tagline,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                ],
                pw.SizedBox(height: 6),
                if (address != null && address.isNotEmpty)
                  pw.Text(
                    address,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                if (phone != null && phone.isNotEmpty)
                  pw.Text(
                    phone,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                if (website != null && website.isNotEmpty)
                  pw.Text(
                    website,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: pw.BoxDecoration(
              color: primary,
              borderRadius: pw.BorderRadius.circular(999),
            ),
            child: pw.Text(
              'APPOINTMENT SUMMARY',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaRow({
    required String date,
    required String time,
    required String petName,
    required String ownerName,
    required PdfColor textMuted,
  }) {
    return pw.Row(
      children: [
        _metaChip('Date', date, textMuted),
        pw.SizedBox(width: 10),
        _metaChip('Time', time, textMuted),
        pw.Spacer(),
        pw.Text(
          _joinParts([petName, ownerName]),
          style: pw.TextStyle(fontSize: 10, color: textMuted),
        ),
      ],
    );
  }

  static pw.Widget _metaChip(
    String label,
    String value,
    PdfColor textMuted,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF1F5F9),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(fontSize: 9, color: textMuted),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String text, PdfColor primary) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: primary, width: 3),
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(left: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  static pw.Widget _infoCard({
    required PdfColor subtle,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: subtle,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(children: children),
    );
  }

  static pw.Widget _infoRow(
    String label,
    String value,
    PdfColor textMuted,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: textMuted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? 'Not provided' : value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _prescriptionsTable({
    required List<PrescriptionDraft> prescriptions,
    required PdfColor textMuted,
    required PdfColor subtle,
  }) {
    if (prescriptions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: subtle,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Text(
          'No prescriptions added.',
          style: pw.TextStyle(fontSize: 11, color: textMuted),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: subtle,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1),
          2: pw.FlexColumnWidth(2),
        },
        border: pw.TableBorder.symmetric(
          inside: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF)),
            children: [
              _tableHeader('Medication'),
              _tableHeader('Dosage'),
              _tableHeader('Instructions'),
            ],
          ),
          for (final rx in prescriptions)
            pw.TableRow(
              children: [
                _tableCell(rx.name),
                _tableCell(rx.dosage),
                _tableCell(rx.instructions),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text.trim().isEmpty ? '-' : text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static String _joinParts(List<String> parts) {
    return parts.where((part) => part.trim().isNotEmpty).join(' - ');
  }

  static Future<Clinic?> _loadClinic() async {
    final data = await Storage.getClinicData();
    if (data == null) return null;
    return Clinic.fromMap(data);
  }

  static Future<Uint8List?> _loadLogoBytes(String? logoUrl) async {
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      try {
        final safeUrl = sanitizeRemoteUrl(logoUrl);
        final response = await Dio().get<List<int>>(
          safeUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Uint8List.fromList(bytes);
        }
      } catch (_) {}
    }
    try {
      final data = await rootBundle.load('assets/logos/logo_without_bg.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
