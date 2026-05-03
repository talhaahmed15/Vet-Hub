import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/bloc/invoice/invoice_state.dart';
import 'package:clinic_management_app/models/appointment_detail.dart';
import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/appointment_service.dart';
import 'package:clinic_management_app/services/invoice_service.dart';

class InvoiceCubit extends Cubit<InvoiceState> {
  InvoiceCubit({
    required InvoiceService invoiceService,
    required AppointmentService appointmentService,
  }) : _invoiceService = invoiceService,
       _appointmentService = appointmentService,
       super(
         InvoiceState(
           draft: InvoiceDraft(invoiceNumber: _generateInvoiceNumber()),
         ),
       );

  final InvoiceService _invoiceService;
  final AppointmentService _appointmentService;

  Future<void> loadInvoices() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final invoices = await _invoiceService.fetchInvoices();
      emit(state.copyWith(invoices: invoices, loading: false));
    } catch (error) {
      emit(state.copyWith(loading: false, error: '$error'));
    }
  }

  Future<void> startNewInvoice({String? appointmentId}) async {
    final newDraft = InvoiceDraft(
      invoiceNumber: _generateInvoiceNumber(),
      appointmentId: appointmentId,
    );
    emit(state.copyWith(draft: newDraft, appointment: null));

    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }

    try {
      final detail =
          await _appointmentService.fetchAppointmentById(appointmentId);
      if (detail == null) return;
      emit(
        state.copyWith(
          appointment: detail,
          draft: state.draft.copyWith(
            appointmentId: appointmentId,
            clientId: detail.clientId,
            clientName: detail.ownerName,
            clientPhone: detail.ownerPhone,
            petId: detail.petId,
            petName: detail.petName,
            petSpecies: detail.petSpecies,
            petBreed: detail.petBreed,
          ),
        ),
      );
    } catch (_) {
      // Keep draft without appointment details if lookup fails.
    }
  }

  Future<void> loadInvoiceForEdit(String invoiceId) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final draft = await _invoiceService.fetchInvoiceForEdit(invoiceId);
      if (draft == null) {
        emit(state.copyWith(loading: false));
        return;
      }
      emit(state.copyWith(draft: draft, loading: false));
    } catch (error) {
      emit(state.copyWith(loading: false, error: '$error'));
    }
  }

  void setPaymentMethod(InvoicePaymentMethod method) {
    emit(state.copyWith(draft: state.draft.copyWith(paymentMethod: method)));
  }

  void toggleConsultation(bool enabled) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(consultationEnabled: enabled),
      ),
    );
  }

  void updateConsultationPrice(double price) {
    emit(state.copyWith(draft: state.draft.copyWith(consultationPrice: price)));
  }

  void updateConsultationQty(int qty) {
    emit(state.copyWith(draft: state.draft.copyWith(consultationQty: qty)));
  }

  void updateClient({
    required String clientId,
    required String clientName,
    required String clientPhone,
  }) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          clientId: clientId.trim(),
          clientName: clientName.trim(),
          clientPhone: clientPhone.trim(),
        ),
      ),
    );
  }

  void addProduct({
    required Item item,
    required int quantity,
    required double unitPrice,
  }) {
    final existingIndex = state.draft.items.indexWhere(
      (entry) =>
          entry.type == InvoiceLineItemType.product &&
          entry.itemId == item.id,
    );
    if (existingIndex != -1) {
      final existing = state.draft.items[existingIndex];
      final updated = state.draft.items
          .map(
            (entry) =>
                entry.id == existing.id
                    ? entry.copyWith(
                      quantity: existing.quantity + quantity,
                      unitPrice: unitPrice,
                    )
                    : entry,
          )
          .toList(growable: false);
      emit(state.copyWith(draft: state.draft.copyWith(items: updated)));
      return;
    }

    final lineItem = InvoiceLineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: item.name,
      type: InvoiceLineItemType.product,
      quantity: quantity,
      unitPrice: unitPrice,
      itemId: item.id,
      unitLabel: item.unit,
    );
    _addLineItem(lineItem);
  }

  void addService({
    required String name,
    required double unitPrice,
  }) {
    final lineItem = InvoiceLineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: InvoiceLineItemType.service,
      quantity: 1,
      unitPrice: unitPrice,
    );
    _addLineItem(lineItem);
  }

  void updateLineItem({
    required String id,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    final updated = state.draft.items.map((item) {
      if (item.id != id) return item;
      return item.copyWith(
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
      );
    }).toList(growable: false);

    emit(state.copyWith(draft: state.draft.copyWith(items: updated)));
  }

  void removeLineItem(String id) {
    final updated = state.draft.items
        .where((item) => item.id != id)
        .toList(growable: false);
    emit(state.copyWith(draft: state.draft.copyWith(items: updated)));
  }

  Future<void> finalizeInvoice() async {
    if (state.finalizing) return;
    emit(state.copyWith(finalizing: true));
    try {
      if (state.draft.invoiceId.isNotEmpty) {
        await _invoiceService.updateInvoice(state.draft);
      } else {
        await _invoiceService.createInvoice(state.draft);
      }
      final listItem = InvoiceListItem(
        id: state.draft.invoiceId.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : state.draft.invoiceId,
        invoiceNumber: state.draft.invoiceNumber,
        clientId: state.draft.clientId,
        clientName: state.draft.clientName.isEmpty
            ? 'Client'
            : state.draft.clientName,
        clientPhone: state.draft.clientPhone,
        petId: state.draft.petId,
        petName: state.draft.petName.isEmpty ? 'Pet' : state.draft.petName,
        total: state.draft.total,
        status: InvoiceStatus.paid,
        paymentMethod: state.draft.paymentMethod,
        createdAt: DateTime.now(),
      );

      if (state.draft.invoiceId.isNotEmpty) {
        final updated = state.invoices
            .map((item) => item.id == listItem.id ? listItem : item)
            .toList(growable: false);
        emit(state.copyWith(invoices: updated));
      } else {
        emit(state.copyWith(invoices: [listItem, ...state.invoices]));
      }
    } finally {
      emit(state.copyWith(finalizing: false));
    }
  }

  void _addLineItem(InvoiceLineItem item) {
    final updated = List<InvoiceLineItem>.from(state.draft.items)..add(item);
    emit(state.copyWith(draft: state.draft.copyWith(items: updated)));
  }

  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    final suffix = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return 'INV-${now.year}-$suffix';
  }
}
