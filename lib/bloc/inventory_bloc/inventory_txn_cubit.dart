import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/inventory_txn_state.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryTxnCubit extends Cubit<InventoryTxnState> {
  InventoryTxnCubit() : super(InventoryTxnState());

  final InventoryService _inventoryService = InventoryService();

  Future<void> submitTxn({
    required String itemId,
    required InventoryTxnType txnType,
    required double quantity,
    String? note,
  }) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, submitSuccess: false, error: null));
    try {
      await _inventoryService.createTxn(
        itemId: itemId,
        txnType: txnType,
        quantity: quantity,
        note: note,
      );
      emit(state.copyWith(isSubmitting: false, submitSuccess: true));
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitSuccess: false,
          error: _mapTxnError(error),
        ),
      );
    }
  }

  String _mapTxnError(Object error) {
    if (error is PostgrestException) {
      final code = error.code ?? '';
      final message =
          '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
              .toLowerCase();

      final isCheckConstraintViolation = code == '23514';
      final mentionsOnHand =
          message.contains('on_hand') ||
          message.contains('on hand') ||
          message.contains('negative') ||
          message.contains('check constraint');

      if (isCheckConstraintViolation && mentionsOnHand) {
        return 'Not enough stock on hand.';
      }

      return error.message;
    }

    return error.toString();
  }
}
