import 'package:clinic_management_app/models/appointment_detail.dart';
import 'package:clinic_management_app/models/invoice_models.dart';

class InvoiceState {
  final List<InvoiceListItem> invoices;
  final bool loading;
  final bool finalizing;
  final String? error;
  final InvoiceDraft draft;
  final AppointmentDetail? appointment;

  const InvoiceState({
    this.invoices = const [],
    this.loading = false,
    this.finalizing = false,
    this.error,
    required this.draft,
    this.appointment,
  });

  InvoiceState copyWith({
    List<InvoiceListItem>? invoices,
    bool? loading,
    bool? finalizing,
    String? error,
    InvoiceDraft? draft,
    AppointmentDetail? appointment,
  }) {
    return InvoiceState(
      invoices: invoices ?? this.invoices,
      loading: loading ?? this.loading,
      finalizing: finalizing ?? this.finalizing,
      error: error,
      draft: draft ?? this.draft,
      appointment: appointment ?? this.appointment,
    );
  }
}
