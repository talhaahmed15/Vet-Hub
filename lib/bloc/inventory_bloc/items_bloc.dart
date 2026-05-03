import 'package:bloc/bloc.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/items_service.dart';

// Events
sealed class InventoryItemsEvent {
  const InventoryItemsEvent();
}

final class InventoryItemsRequested extends InventoryItemsEvent {
  const InventoryItemsRequested({this.activeOnly = true, this.searchQuery});

  final bool activeOnly;
  final String? searchQuery;
}

final class InventoryItemsRefreshed extends InventoryItemsEvent {
  const InventoryItemsRefreshed({this.activeOnly = true, this.searchQuery});

  final bool activeOnly;
  final String? searchQuery;
}

final class InventoryItemsPageRequested extends InventoryItemsEvent {
  const InventoryItemsPageRequested();
}

final class InventoryItemCreated extends InventoryItemsEvent {
  const InventoryItemCreated({
    required this.name,
    this.category,
    this.unit = 'ea',
    this.price = 0,
  });

  final String name;
  final String? category;
  final String unit;
  final double price;
}

final class InventoryItemRefetched extends InventoryItemsEvent {
  const InventoryItemRefetched({required this.itemId});

  final String itemId;
}

// States
sealed class InventoryItemsState {
  const InventoryItemsState();
}

final class InventoryItemsInitial extends InventoryItemsState {
  const InventoryItemsInitial();
}

final class InventoryItemsLoading extends InventoryItemsState {
  const InventoryItemsLoading();
}

final class InventoryItemsLoaded extends InventoryItemsState {
  const InventoryItemsLoaded({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Item> items;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  InventoryItemsLoaded copyWith({
    List<Item>? items,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return InventoryItemsLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

final class InventoryItemsFailure extends InventoryItemsState {
  const InventoryItemsFailure(this.message);

  final String message;
}

class InventoryItemsBloc
    extends Bloc<InventoryItemsEvent, InventoryItemsState> {
  InventoryItemsBloc({required ItemsService itemsRepository})
    : _itemsRepository = itemsRepository,
      super(const InventoryItemsInitial()) {
    on<InventoryItemsRequested>(_onRequested);
    on<InventoryItemsRefreshed>(_onRequested);
    on<InventoryItemsPageRequested>(_onPageRequested);
    on<InventoryItemCreated>(_onCreated);
    on<InventoryItemRefetched>(_onItemRefetched);
  }

  final ItemsService _itemsRepository;
  static const int _pageSize = 30;
  bool _activeOnly = true;
  String? _searchQuery;
  List<Item> _items = [];
  bool _hasMore = true;

  Future<void> _onRequested(
    InventoryItemsEvent event,
    Emitter<InventoryItemsState> emit,
  ) async {
    final activeOnly = switch (event) {
      InventoryItemsRequested e => e.activeOnly,
      InventoryItemsRefreshed e => e.activeOnly,
      _ => true,
    };
    final searchQuery = switch (event) {
      InventoryItemsRequested e => e.searchQuery,
      InventoryItemsRefreshed e => e.searchQuery,
      _ => null,
    };
    _activeOnly = activeOnly;
    _searchQuery = searchQuery;

    emit(const InventoryItemsLoading());
    try {
      final items = await _itemsRepository.fetchItems(
        activeOnly: activeOnly,
        searchQuery: searchQuery,
        limit: _pageSize,
        offset: 0,
      );
      _items = _sorted(items);
      _hasMore = items.length == _pageSize;
      emit(
        InventoryItemsLoaded(
          items: _items,
          hasMore: _hasMore,
        ),
      );
    } catch (error) {
      emit(InventoryItemsFailure('Failed to load items: $error'));
    }
  }

  Future<void> _onPageRequested(
    InventoryItemsPageRequested event,
    Emitter<InventoryItemsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! InventoryItemsLoaded) return;
    if (currentState.isLoadingMore || !_hasMore) return;

    emit(
      currentState.copyWith(
        isLoadingMore: true,
        loadMoreError: null,
      ),
    );
    try {
      final nextItems = await _itemsRepository.fetchItems(
        activeOnly: _activeOnly,
        searchQuery: _searchQuery,
        limit: _pageSize,
        offset: _items.length,
      );
      _items = _sorted([..._items, ...nextItems]);
      _hasMore = nextItems.length == _pageSize;
      emit(
        currentState.copyWith(
          items: _items,
          hasMore: _hasMore,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
    } catch (error) {
      emit(
        currentState.copyWith(
          isLoadingMore: false,
          loadMoreError: 'Failed to load more items: $error',
        ),
      );
    }
  }

  Future<void> _onCreated(
    InventoryItemCreated event,
    Emitter<InventoryItemsState> emit,
  ) async {
    emit(const InventoryItemsLoading());
    try {
      await _itemsRepository.createItem(
        name: event.name,
        category: event.category,
        unit: event.unit,
        price: event.price,
      );
      final items = await _itemsRepository.fetchItems(
        activeOnly: _activeOnly,
        searchQuery: _searchQuery,
        limit: _pageSize,
        offset: 0,
      );
      _items = _sorted(items);
      _hasMore = items.length == _pageSize;
      emit(
        InventoryItemsLoaded(
          items: _items,
          hasMore: _hasMore,
        ),
      );
    } catch (error) {
      emit(InventoryItemsFailure('Failed to create item: $error'));
    }
  }

  Future<void> _onItemRefetched(
    InventoryItemRefetched event,
    Emitter<InventoryItemsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! InventoryItemsLoaded) {
      return;
    }

    try {
      final item = await _itemsRepository.fetchItemById(event.itemId);
      final items = List<Item>.from(currentState.items);
      final index = items.indexWhere((entry) => entry.id == item.id);
      if (_activeOnly && !item.isActive) {
        if (index != -1) {
          items.removeAt(index);
          _items = _sorted(items);
          emit(
            InventoryItemsLoaded(
              items: _items,
              hasMore: _hasMore,
            ),
          );
        }
        return;
      }

      if (!_matchesSearch(item, _searchQuery)) {
        if (index != -1) {
          items.removeAt(index);
          _items = _sorted(items);
          emit(
            InventoryItemsLoaded(
              items: _items,
              hasMore: _hasMore,
            ),
          );
        }
        return;
      }

      if (index == -1) {
        items.add(item);
      } else {
        items[index] = item;
      }

      _items = _sorted(items);
      emit(
        InventoryItemsLoaded(
          items: _items,
          hasMore: _hasMore,
        ),
      );
    } catch (_) {
      // Keep current list if background refetch fails.
    }
  }

  List<Item> _sorted(List<Item> items) {
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  bool _matchesSearch(Item item, String? query) {
    final trimmed = query?.trim();
    if (trimmed == null || trimmed.isEmpty) return true;
    final q = trimmed.toLowerCase();
    return item.name.toLowerCase().contains(q) ||
        (item.category ?? '').toLowerCase().contains(q);
  }
}
