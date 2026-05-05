import 'package:clinic_management_app/bloc/invoice/invoice_cubit.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/services/items_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/custom_textfield.dart';
import 'package:clinic_management_app/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _category = 'All';
  final Map<String, int> _cartQuantities = {};
  String? _expandedItemId;

  late Future<List<Item>> _futureItems;

  @override
  void initState() {
    super.initState();
    _futureItems = context.read<ItemsService>().fetchItems(activeOnly: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: CustomAppBar(title: "Add Products"),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            if (_cartQuantities.isNotEmpty)
              TextButton(
                onPressed: _clearAll,
                child: Text(
                  'Clear All',
                  style: AppFonts.semiBold(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            if (_cartQuantities.isNotEmpty) const SizedBox(width: 10),
            Expanded(
              child: PrimaryIconButton(
                text: 'Save Products (${_cartCountLabel()})',
                icon: Icons.receipt_long,
                onPressed: _cartQuantities.isEmpty ? () {} : _saveProducts,
                isEnabled: _cartQuantities.isNotEmpty,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  hintText: 'Search products or scan barcode',
                  onChanged: (_) => setState(() {}),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.qr_code_scanner),
                ),
                const SizedBox(height: 12),
                _CategoryChips(
                  selected: _category,
                  onSelected: (value) => setState(() => _category = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: _futureItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load products'));
                }

                final items = _filteredItems(snapshot.data ?? const []);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    ...items.map(
                      (item) => _ProductRow(
                        item: item,
                        isExpanded: _expandedItemId == item.id,
                        addedQuantity: _cartQuantities[item.id] ?? 0,
                        onToggle: () => _handleTap(item),
                        onQtyChanged: (value) => _updateQuantity(item, value),
                        onClear: () => _clearItem(item.id),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Item> _filteredItems(List<Item> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items
        .where((item) {
          if (item.onHand <= 0) return false;
          if (_category != 'All') {
            final category = (item.category ?? '').toLowerCase();
            if (!category.contains(_category.toLowerCase())) {
              return false;
            }
          }
          if (query.isEmpty) return true;
          return item.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _handleTap(Item item) {
    if (_expandedItemId == item.id) {
      setState(() => _expandedItemId = null);
      return;
    }

    final unitPrice = item.price;
    if (unitPrice <= 0) {
      AppToast.error(context, 'Set a price for this product in inventory.');
      return;
    }

    setState(() {
      final current = _cartQuantities[item.id] ?? 0;
      final available = _availableQty(item);
      if (available <= 0) {
        AppToast.error(context, 'This item is out of stock.');
        return;
      }
      if (current >= available) {
        AppToast.error(context, 'Only $available in stock.');
        _expandedItemId = item.id;
        return;
      }
      _cartQuantities[item.id] = current + 1;
      _expandedItemId = item.id;
    });
  }

  void _updateQuantity(Item item, int value) {
    setState(() {
      final available = _availableQty(item);
      if (value > available) {
        _cartQuantities[item.id] = available;
        AppToast.error(context, 'Only $available in stock.');
        return;
      }
      if (value <= 0) {
        _cartQuantities.remove(item.id);
        if (_expandedItemId == item.id) {
          _expandedItemId = null;
        }
      } else {
        _cartQuantities[item.id] = value;
      }
    });
  }

  void _clearItem(String itemId) {
    setState(() {
      _cartQuantities.remove(itemId);
      if (_expandedItemId == itemId) {
        _expandedItemId = null;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _cartQuantities.clear();
      _expandedItemId = null;
    });
  }

  int _availableQty(Item item) {
    final available = item.onHand.floor();
    return available < 0 ? 0 : available;
  }

  String _cartCountLabel() {
    if (_cartQuantities.isEmpty) return '0';
    final total = _cartQuantities.values.fold<int>(0, (sum, v) => sum + v);
    return total.toString();
  }

  void _saveProducts() {
    final itemIds = _cartQuantities.keys.toSet();
    if (itemIds.isEmpty) return;

    // Lookup items in the current list for price/name details.
    _futureItems.then((items) {
      final byId = {for (final item in items) item.id: item};
      for (final entry in _cartQuantities.entries) {
        final item = byId[entry.key];
        if (item == null) continue;
        final unitPrice = item.price;
        if (unitPrice <= 0) continue;
        context.read<InvoiceCubit>().addProduct(
          item: item,
          quantity: entry.value,
          unitPrice: unitPrice.toDouble(),
        );
      }
      Navigator.of(context).pop();
    });
  }
}

class _CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, IconData icon) {
      final isSelected = selected == label;
      return InkWell(
        onTap: () => onSelected(label),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.darkGrey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.semiBold(
                  fontSize: 12,
                  color: isSelected ? AppColors.white : AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', Icons.all_inclusive),
          const SizedBox(width: 8),
          chip('Medicine', Icons.medication),
          const SizedBox(width: 8),
          chip('Food', Icons.pets),
          const SizedBox(width: 8),
          chip('Accessories', Icons.widgets),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Item item;
  final bool isExpanded;
  final int addedQuantity;
  final VoidCallback onToggle;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onClear;

  const _ProductRow({
    required this.item,
    required this.isExpanded,
    required this.addedQuantity,
    required this.onToggle,
    required this.onQtyChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AppFonts.semiBold(fontSize: 13)),
                        Text(
                          '${item.onHand.toStringAsFixed(0)} ${item.unit} in stock',
                          style: AppFonts.regular(
                            fontSize: 10,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        if (addedQuantity > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Added: $addedQuantity',
                            style: AppFonts.semiBold(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    _formatMoney(item.price),
                    style: AppFonts.semiBold(fontSize: 14),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _QuantityPicker(
                        quantity: addedQuantity > 0 ? addedQuantity : 1,
                        onChanged: onQtyChanged,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close, color: AppColors.error),
                      tooltip: 'Clear item',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityPicker extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityPicker({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onChanged(quantity - 1),
          ),
          Expanded(
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: AppFonts.semiBold(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
  return NumberFormat.currency(symbol: '\$').format(value);
}
