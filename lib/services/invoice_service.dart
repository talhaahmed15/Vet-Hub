import 'dart:developer';

import 'package:clinic_management_app/models/invoice_models.dart';
import 'package:clinic_management_app/services/storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceService {
  final SupabaseClient _supabase;

  InvoiceService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<String> _requireClinicId() async {
    final data = await Storage.getClinicData();
    final clinicId = data?['clinic_id']?.toString();
    if (clinicId == null || clinicId.isEmpty) {
      throw StateError('Missing clinic context. Please sign in again.');
    }
    return clinicId;
  }

  Future<List<InvoiceListItem>> fetchInvoices() async {
    try {
      final clinicId = await _requireClinicId();
      final query = _supabase
          .from('invoices')
          .select(
            'id,invoice_number,status,payment_method,total,created_at,client_id,pet_id,client:clients(id,full_name,phone),pet:pets(id,name)',
          )
          .eq('clinic_id', clinicId);

      final data = await query.order('created_at', ascending: false);
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows
          .map((row) {
            final client = row['client'] as Map<String, dynamic>?;
            final pet = row['pet'] as Map<String, dynamic>?;
            return InvoiceListItem(
              id: row['id']?.toString() ?? '',
              invoiceNumber: row['invoice_number']?.toString() ?? '',
              clientId: row['client_id']?.toString() ?? '',
              clientName: client?['full_name']?.toString() ?? '',
              clientPhone: client?['phone']?.toString() ?? '',
              petId: row['pet_id']?.toString() ?? '',
              petName: pet?['name']?.toString() ?? '',
              total: _parseNumeric(row['total']),
              status: _statusFromString(row['status']?.toString()),
              paymentMethod: _paymentMethodFromString(
                row['payment_method']?.toString(),
              ),
              createdAt: _parseDateTime(row['created_at']),
            );
          })
          .where((row) => row.id.isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      log('Error fetching invoices: $error');
      rethrow;
    }
  }

  Future<void> createInvoice(InvoiceDraft draft) async {
    try {
      final clinicId = await _requireClinicId();
      final payload = <String, dynamic>{
        'clinic_id': clinicId,
        'invoice_number': draft.invoiceNumber,
        'appointment_id': draft.appointmentId,
        'client_id': draft.clientId.isEmpty ? null : draft.clientId,
        'pet_id': draft.petId.isEmpty ? null : draft.petId,
        'status': _statusToString(InvoiceStatus.paid),
        'payment_method': _paymentMethodToString(draft.paymentMethod),
        'subtotal': draft.subtotal,
        'tax': draft.tax,
        'total': draft.total,
      };
      log('Creating invoice ${draft.invoiceNumber}');
      final invoiceRow = await _supabase
          .from('invoices')
          .insert(payload)
          .select('id')
          .single();
      final invoiceId = invoiceRow['id']?.toString() ?? '';
      if (invoiceId.isEmpty) return;

      final itemsPayload = <Map<String, dynamic>>[];
      if (draft.consultationEnabled) {
        itemsPayload.add({
          'invoice_id': invoiceId,
          'item_type': 'consultation',
          'item_name': 'Consultation Fee',
          'quantity': draft.consultationQty,
          'unit_price': draft.consultationPrice,
          'total': draft.consultationTotal,
        });
      }

      for (final item in draft.items) {
        itemsPayload.add({
          'invoice_id': invoiceId,
          'item_type': item.type == InvoiceLineItemType.product
              ? 'product'
              : 'service',
          'item_name': item.name,
          'item_id': item.itemId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
        });
      }

      if (itemsPayload.isNotEmpty) {
        await _supabase.from('invoice_items').insert(itemsPayload);
      }
    } catch (e) {
      log('Error creating invoice: $e');
      rethrow;
    }
  }

  Future<InvoiceListItem?> fetchInvoiceByAppointmentId(
    String appointmentId,
  ) async {
    try {
      final clinicId = await _requireClinicId();
      final data = await _supabase
          .from('invoices')
          .select(
            'id,invoice_number,status,payment_method,total,created_at,client_id,pet_id,client:clients(id,full_name,phone),pet:pets(id,name)',
          )
          .eq('clinic_id', clinicId)
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      final row = data;
      final client = row['client'] as Map<String, dynamic>?;
      final pet = row['pet'] as Map<String, dynamic>?;
      return InvoiceListItem(
        id: row['id']?.toString() ?? '',
        invoiceNumber: row['invoice_number']?.toString() ?? '',
        clientId: row['client_id']?.toString() ?? '',
        clientName: client?['full_name']?.toString() ?? '',
        clientPhone: client?['phone']?.toString() ?? '',
        petId: row['pet_id']?.toString() ?? '',
        petName: pet?['name']?.toString() ?? '',
        total: _parseNumeric(row['total']),
        status: _statusFromString(row['status']?.toString()),
        paymentMethod: _paymentMethodFromString(
          row['payment_method']?.toString(),
        ),
        createdAt: _parseDateTime(row['created_at']),
      );
    } catch (error) {
      log('Error fetching invoice by appointment: $error');
      rethrow;
    }
  }

  Future<InvoiceDraft?> fetchInvoiceForEdit(String invoiceId) async {
    try {
      final clinicId = await _requireClinicId();
      final data = await _supabase
          .from('invoices')
          .select(
            'id,invoice_number,appointment_id,client_id,pet_id,payment_method,client:clients(id,full_name,phone),pet:pets(id,name,species,breed)',
          )
          .eq('clinic_id', clinicId)
          .eq('id', invoiceId)
          .maybeSingle();
      if (data == null) return null;
      final row = data;
      final client = row['client'] as Map<String, dynamic>?;
      final pet = row['pet'] as Map<String, dynamic>?;

      final items = await fetchInvoiceItems(invoiceId);
      final consultation = items.firstWhere(
        (item) => item.itemId == 'consultation',
        orElse: () => const InvoiceLineItem(
          id: '',
          name: '',
          type: InvoiceLineItemType.service,
          quantity: 1,
          unitPrice: 0,
        ),
      );
      final nonConsultation = items
          .where((item) => item.id != consultation.id)
          .toList(growable: false);

      return InvoiceDraft(
        invoiceId: row['id']?.toString() ?? '',
        invoiceNumber: row['invoice_number']?.toString() ?? '',
        appointmentId: row['appointment_id']?.toString(),
        clientId: row['client_id']?.toString() ?? '',
        clientName: client?['full_name']?.toString() ?? '',
        clientPhone: client?['phone']?.toString() ?? '',
        petId: row['pet_id']?.toString() ?? '',
        petName: pet?['name']?.toString() ?? '',
        petSpecies: pet?['species']?.toString() ?? '',
        petBreed: pet?['breed']?.toString() ?? '',
        paymentMethod: _paymentMethodFromString(
          row['payment_method']?.toString(),
        ),
        consultationEnabled: consultation.id.isNotEmpty,
        consultationQty: consultation.quantity,
        consultationPrice: consultation.unitPrice,
        items: nonConsultation,
      );
    } catch (error) {
      log('Error fetching invoice for edit: $error');
      rethrow;
    }
  }

  Future<void> updateInvoice(InvoiceDraft draft) async {
    try {
      final clinicId = await _requireClinicId();
      final invoiceId = draft.invoiceId;
      if (invoiceId.isEmpty) return;
      final payload = <String, dynamic>{
        'appointment_id': draft.appointmentId,
        'client_id': draft.clientId.isEmpty ? null : draft.clientId,
        'pet_id': draft.petId.isEmpty ? null : draft.petId,
        'payment_method': _paymentMethodToString(draft.paymentMethod),
        'subtotal': draft.subtotal,
        'tax': draft.tax,
        'total': draft.total,
      };
      await _supabase
          .from('invoices')
          .update(payload)
          .eq('id', invoiceId)
          .eq('clinic_id', clinicId);

      final ownedInvoice = await _supabase
          .from('invoices')
          .select('id')
          .eq('id', invoiceId)
          .eq('clinic_id', clinicId)
          .maybeSingle();
      if (ownedInvoice == null) {
        throw StateError('Invoice not found for this clinic.');
      }

      await _supabase
          .from('invoice_items')
          .delete()
          .eq('invoice_id', invoiceId);

      final itemsPayload = <Map<String, dynamic>>[];
      if (draft.consultationEnabled) {
        itemsPayload.add({
          'invoice_id': invoiceId,
          'item_type': 'consultation',
          'item_name': 'Consultation Fee',
          'quantity': draft.consultationQty,
          'unit_price': draft.consultationPrice,
          'total': draft.consultationTotal,
        });
      }

      for (final item in draft.items) {
        itemsPayload.add({
          'invoice_id': invoiceId,
          'item_type': item.type == InvoiceLineItemType.product
              ? 'product'
              : 'service',
          'item_name': item.name,
          'item_id': item.itemId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total': item.total,
        });
      }

      if (itemsPayload.isNotEmpty) {
        await _supabase.from('invoice_items').insert(itemsPayload);
      }
    } catch (e) {
      log('Error updating invoice: $e');
      rethrow;
    }
  }

  Future<List<InvoiceLineItem>> fetchInvoiceItems(String invoiceId) async {
    try {
      final clinicId = await _requireClinicId();
      final ownedInvoice = await _supabase
          .from('invoices')
          .select('id')
          .eq('id', invoiceId)
          .eq('clinic_id', clinicId)
          .maybeSingle();
      if (ownedInvoice == null) {
        return const <InvoiceLineItem>[];
      }
      final data = await _supabase
          .from('invoice_items')
          .select('id,item_type,item_name,item_id,quantity,unit_price')
          .eq('invoice_id', invoiceId);
      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows
          .map((row) {
            final itemType = (row['item_type']?.toString() ?? '').toLowerCase();
            final type = itemType == 'product'
                ? InvoiceLineItemType.product
                : InvoiceLineItemType.service;
            return InvoiceLineItem(
              id: row['id']?.toString() ?? '',
              name: row['item_name']?.toString() ?? 'Item',
              type: type,
              quantity: int.tryParse(row['quantity']?.toString() ?? '') ?? 1,
              unitPrice: _parseNumeric(row['unit_price']),
              itemId: itemType == 'consultation'
                  ? 'consultation'
                  : row['item_id']?.toString(),
            );
          })
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      log('Error fetching invoice items: $error');
      rethrow;
    }
  }

  Future<void> updateInvoiceStatus({
    required String invoiceId,
    required InvoiceStatus status,
  }) async {
    try {
      final clinicId = await _requireClinicId();
      log('Updating invoice $invoiceId to $status');
      await _supabase
          .from('invoices')
          .update({'status': _statusToString(status)})
          .eq('id', invoiceId)
          .eq('clinic_id', clinicId);
    } catch (e) {
      log('Error updating invoice $invoiceId: $e');
      rethrow;
    }
  }

}

double _parseNumeric(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

InvoiceStatus _statusFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'pending':
      return InvoiceStatus.pending;
    case 'paid':
    default:
      return InvoiceStatus.paid;
  }
}

String _statusToString(InvoiceStatus status) {
  return switch (status) {
    InvoiceStatus.pending => 'pending',
    InvoiceStatus.paid => 'paid',
  };
}

InvoicePaymentMethod _paymentMethodFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'card':
      return InvoicePaymentMethod.card;
    case 'cash':
    default:
      return InvoicePaymentMethod.cash;
  }
}

String _paymentMethodToString(InvoicePaymentMethod method) {
  return switch (method) {
    InvoicePaymentMethod.cash => 'cash',
    InvoicePaymentMethod.card => 'card',
  };
}
