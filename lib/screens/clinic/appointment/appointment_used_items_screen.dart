import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:clinic_management_app/widgets/search_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppointmentUsedItemsScreen extends StatefulWidget {
  final String appointmentId;
  final String petName;
  final String ownerName;

  const AppointmentUsedItemsScreen({
    super.key,
    required this.appointmentId,
    required this.petName,
    required this.ownerName,
  });

  @override
  State<AppointmentUsedItemsScreen> createState() =>
      _AppointmentUsedItemsScreenState();
}

class _AppointmentUsedItemsScreenState extends State<AppointmentUsedItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_PendingUse> _pending = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    context.read<InventoryItemsBloc>().add(const InventoryItemsRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;

    final bloc = context.read<InventoryItemsBloc>();
    final state = bloc.state;
    if (state is InventoryItemsLoaded &&
        state.hasMore &&
        !state.isLoadingMore) {
      bloc.add(const InventoryItemsPageRequested());
    }
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    context.read<InventoryItemsBloc>().add(
      InventoryItemsRequested(searchQuery: query.isEmpty ? null : query),
    );
  }

  Future<void> _openLogSheet(Item item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _LogUsedItemSheet(
          item: item,
          onAdd: (quantity, note) {
            _addPending(item, quantity, note);
          },
        );
      },
    );
  }

  void _addPending(Item item, double quantity, String? note) {
    setState(() {
      final index = _pending.indexWhere((entry) => entry.item.id == item.id);
      final trimmedNote = note?.trim();
      if (index == -1) {
        _pending.add(
          _PendingUse(item: item, quantity: quantity, note: trimmedNote),
        );
        return;
      }

      final existing = _pending[index];
      final mergedNote = _mergeNotes(existing.note, trimmedNote);
      _pending[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
        note: mergedNote,
      );
    });
  }

  String? _mergeNotes(String? existing, String? next) {
    final left = existing?.trim() ?? '';
    final right = next?.trim() ?? '';
    if (left.isEmpty && right.isEmpty) return null;
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    if (left == right) return left;
    return '$left / $right';
  }

  Future<void> _submitBatch() async {
    if (_pending.isEmpty) {
      AppToast.error(context, 'Add at least one item to log.');
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    final inventoryService = context.read<InventoryService>();

    try {
      for (final entry in _pending) {
        await inventoryService.createTxn(
          itemId: entry.item.id,
          txnType: InventoryTxnType.use,
          quantity: entry.quantity,
          note: entry.note,
        );
      }
      if (!mounted) return;
      for (final entry in _pending) {
        context.read<InventoryItemsBloc>().add(
          InventoryItemRefetched(itemId: entry.item.id),
        );
      }
      setState(() => _pending.clear());
      AppToast.success(context, 'Usage recorded.');
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Failed to log items: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF101922) : AppColors.lightGrey;
    final nameLine = widget.petName.trim().isEmpty
        ? 'Appointment items'
        : widget.petName.trim();
    final ownerLine = widget.ownerName.trim().isEmpty
        ? 'Pet Owner'
        : widget.ownerName.trim();

    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(title: 'Log Used Items'),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: isDark ? const Color(0xFF101922) : AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameLine,
                    style: AppFonts.bold(
                      fontSize: 18,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ownerLine,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: isDark ? AppColors.grey : AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SearchTextField(
                    controller: _searchController,
                    hint: 'Search inventory items',
                    onSubmitted: (_) => _submitSearch(),
                  ),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Pending Items (${_pending.length})',
                      style: AppFonts.semiBold(
                        fontSize: 12,
                        color: isDark ? AppColors.grey : AppColors.darkGrey,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._pending.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PendingItemCard(
                          entry: entry,
                          onRemove: () {
                            setState(() => _pending.remove(entry));
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<InventoryItemsBloc, InventoryItemsState>(
                builder: (context, state) {
                  if (state is InventoryItemsLoading ||
                      state is InventoryItemsInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is InventoryItemsFailure) {
                    return _ErrorState(
                      message: state.message,
                      onRetry: () => _submitSearch(),
                    );
                  }
                  if (state is! InventoryItemsLoaded) {
                    return const SizedBox.shrink();
                  }

                  final items = state.items;
                  if (items.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount:
                        items.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = items[index];
                      return _InventoryUseCard(
                        item: item,
                        onLog: () => _openLogSheet(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _pending.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryIconButton(
                    text:
                        'Submit ${_pending.length} Item${_pending.length == 1 ? '' : 's'}',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _submitting,
                    onPressed: _submitBatch,
                  ),
                ],
              ),
            ),
    );
  }
}

class _PendingUse {
  final Item item;
  final double quantity;
  final String? note;

  const _PendingUse({
    required this.item,
    required this.quantity,
    required this.note,
  });

  _PendingUse copyWith({double? quantity, String? note}) {
    return _PendingUse(
      item: item,
      quantity: quantity ?? this.quantity,
      note: note,
    );
  }
}

class _PendingItemCard extends StatelessWidget {
  final _PendingUse entry;
  final VoidCallback onRemove;

  const _PendingItemCard({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.item.name, style: AppFonts.semiBold(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${_formatQuantity(entry.quantity)} ${entry.item.unit.toLowerCase()}',
                  style: AppFonts.regular(
                    fontSize: 11,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.darkGrey,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _InventoryUseCard extends StatelessWidget {
  final Item item;
  final VoidCallback onLog;

  const _InventoryUseCard({required this.item, required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppFonts.semiBold(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _itemSubtitle(item),
                  style: AppFonts.regular(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatQuantity(item.onHand)} ${item.unit.toLowerCase()}',
            style: AppFonts.bold(fontSize: 14, color: AppColors.black),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onLog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Log'),
            ),
          ),
        ],
      ),
    );
  }

  String _itemSubtitle(Item item) {
    final category = item.category?.trim();
    if (category == null || category.isEmpty) return 'Inventory item';
    return category;
  }
}

class _LogUsedItemSheet extends StatefulWidget {
  final Item item;
  final void Function(double quantity, String? note) onAdd;

  const _LogUsedItemSheet({
    required this.item,
    required this.onAdd,
  });

  @override
  State<_LogUsedItemSheet> createState() => _LogUsedItemSheetState();
}

class _LogUsedItemSheetState extends State<_LogUsedItemSheet> {
  late final TextEditingController _quantityController;
  final TextEditingController _notesController = TextEditingController();

  static const _quickQuantities = <int>[1, 5, 10, 25];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _quantity {
    final parsed = double.tryParse(_quantityController.text.trim());
    if (parsed == null || parsed <= 0) return 1;
    return parsed;
  }

  double get _remaining =>
      (widget.item.onHand - _quantity).clamp(0, double.infinity).toDouble();

  void _setQuantity(num value) {
    setState(() => _quantityController.text = value.toString());
  }

  double? _parseQuantity(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _submit(BuildContext context) {
    final quantity = _parseQuantity(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      AppToast.error(context, 'Enter a quantity greater than 0.');
      return;
    }
    if (quantity > widget.item.onHand) {
      AppToast.error(context, 'Not enough stock on hand.');
      return;
    }

    final note = _buildNote(_notesController.text);
    widget.onAdd(quantity, note);
    Navigator.of(context).pop(true);
  }

  String? _buildNote(String raw) {
    final base = 'Used in procedure';
    final extra = raw.trim();
    if (extra.isEmpty) return base;
    return '$base - $extra';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.name,
            style: AppFonts.bold(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'In stock: ${_formatQuantity(widget.item.onHand)} ${widget.item.unit.toLowerCase()}',
            style: AppFonts.regular(
              fontSize: 12,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quantity Used',
            style: AppFonts.semiBold(fontSize: 13),
          ),
          const SizedBox(height: 6),
          CustomTextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            hintText: '1',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _quickQuantities
                .map((value) {
                  final isSelected =
                      _quantityController.text.trim() == '$value';
                  return _QuickQuantityChip(
                    value: value,
                    isSelected: isSelected,
                    onTap: () => _setQuantity(value),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          Text(
            'Notes (optional)',
            style: AppFonts.semiBold(fontSize: 13),
          ),
          const SizedBox(height: 6),
          CustomTextField(
            controller: _notesController,
            maxLines: 3,
            hintText: 'Add any details...',
          ),
          const SizedBox(height: 12),
          Text(
            'Remaining after use: ${_formatQuantity(_remaining)} ${widget.item.unit.toLowerCase()}',
            style: AppFonts.medium(
              fontSize: 12,
              color: AppColors.greyBlue,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryIconButton(
            text: 'Add to Batch',
            icon: Icons.add_circle_outline,
            onPressed: () => _submit(context),
          ),
        ],
      ),
    );
  }
}

class _QuickQuantityChip extends StatelessWidget {
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickQuantityChip({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFD6E2F3),
            width: 1,
          ),
        ),
        child: Text(
          '$value',
          style: AppFonts.bold(
            fontSize: 12,
            color: isSelected ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No inventory items yet.',
        style: AppFonts.regular(fontSize: 13, color: AppColors.darkGrey),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.regular(fontSize: 13, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatQuantity(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
