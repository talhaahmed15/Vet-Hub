import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/add_item_state.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:clinic_management_app/services/items_service.dart';

class AddItemCubit extends Cubit<AddItemState> {
  AddItemCubit({
    required ItemsService itemsService,
    required InventoryService inventoryService,
  }) : _itemsService = itemsService,
       _inventoryService = inventoryService,
       super(const AddItemState());

  final ItemsService _itemsService;
  final InventoryService _inventoryService;

  Future<void> addItem({
    required String name,
    String? category,
    required String unit,
    required double price,
    double initialStock = 0,
  }) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, submitSuccess: false, error: null));
    try {
      final item = await _itemsService.createItem(
        name: name.trim(),
        category: category,
        unit: unit,
        price: price,
      );

      final safeInitial = initialStock.isNaN ? 0 : initialStock;
      if (safeInitial > 0) {
        await _inventoryService.createTxn(
          itemId: item.id,
          txnType: InventoryTxnType.receive,
          quantity: safeInitial.toDouble(),
          note: 'Initial stock',
        );
      }

      emit(state.copyWith(isSubmitting: false, submitSuccess: true));
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
