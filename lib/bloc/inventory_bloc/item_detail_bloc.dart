import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Events
sealed class InventoryItemDetailEvent {
  const InventoryItemDetailEvent();
}

final class InventoryItemDetailRequested extends InventoryItemDetailEvent {
  const InventoryItemDetailRequested(this.itemId);

  final String itemId;
}

final class InventoryItemDetailRefreshed extends InventoryItemDetailEvent {
  const InventoryItemDetailRefreshed();
}

final class InventoryTxnCreated extends InventoryItemDetailEvent {
  const InventoryTxnCreated({
    required this.txnType,
    required this.quantity,
    this.note,
  });

  final InventoryTxnType txnType;
  final double quantity;
  final String? note;
}

// States
sealed class InventoryItemDetailState {
  const InventoryItemDetailState();
}

final class InventoryItemDetailLoading extends InventoryItemDetailState {
  const InventoryItemDetailLoading();
}

final class InventoryItemDetailLoaded extends InventoryItemDetailState {
  const InventoryItemDetailLoaded({required this.item, required this.txns});

  final Item item;
  final List<InventoryTxn> txns;
}

final class InventoryItemDetailFailure extends InventoryItemDetailState {
  const InventoryItemDetailFailure(this.message);

  final String message;
}

class InventoryItemDetailBloc
    extends Bloc<InventoryItemDetailEvent, InventoryItemDetailState> {
  InventoryItemDetailBloc() : super(const InventoryItemDetailLoading()) {
    on<InventoryItemDetailRequested>(_onRequested);
    on<InventoryItemDetailRefreshed>(_onRefreshed);
    on<InventoryTxnCreated>(_onTxnCreated);
  }

  final ItemsService _itemsRepository = ItemsService();

  final InventoryService _inventoryRepository = InventoryService();

  String? _itemId;

  Future<void> _onRequested(
    InventoryItemDetailRequested event,
    Emitter<InventoryItemDetailState> emit,
  ) async {
    _itemId = event.itemId;
    await _load(emit);
  }

  Future<void> _onRefreshed(
    InventoryItemDetailRefreshed event,
    Emitter<InventoryItemDetailState> emit,
  ) async {
    if (_itemId == null) {
      emit(const InventoryItemDetailFailure('No item selected.'));
      return;
    }
    await _load(emit);
  }

  Future<void> _onTxnCreated(
    InventoryTxnCreated event,
    Emitter<InventoryItemDetailState> emit,
  ) async {
    if (_itemId == null) {
      emit(const InventoryItemDetailFailure('No item selected.'));
      return;
    }

    emit(const InventoryItemDetailLoading());
    try {
      await _inventoryRepository.createTxn(
        itemId: _itemId!,
        txnType: event.txnType,
        quantity: event.quantity,
        note: event.note,
      );
      await _load(emit, showLoading: false);
    } catch (error) {
      emit(InventoryItemDetailFailure(_mapTxnError(error)));
    }
  }

  Future<void> _load(
    Emitter<InventoryItemDetailState> emit, {
    bool showLoading = true,
  }) async {
    final itemId = _itemId;
    if (itemId == null) {
      emit(const InventoryItemDetailFailure('No item selected.'));
      return;
    }

    if (showLoading) {
      emit(const InventoryItemDetailLoading());
    }

    try {
      final item = await _itemsRepository.fetchItemById(itemId);
      final txns = await _inventoryRepository.fetchTxnsForItem(
        itemId,
        limit: 8,
      );
      emit(InventoryItemDetailLoaded(item: item, txns: txns));
    } catch (error) {
      emit(InventoryItemDetailFailure('Failed to load item: $error'));
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
