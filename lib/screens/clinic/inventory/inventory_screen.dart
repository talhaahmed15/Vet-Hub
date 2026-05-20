import 'dart:math' show min;

import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/enums/item_status_enum.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/inventory/add_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/edit_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/item_detail_page.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_consts.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/themes/app_icons.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/page_content.dart';
import 'package:clinic_management_app/widgets/search_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = _allCategoryLabel;
  static const String _allCategoryLabel = 'All Items';

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

  Future<void> _openAddItemScreen() {
    return NavigatorHelper.push(context, const AddItemScreen());
  }

  void _openItemDetail(Item item) {
    NavigatorHelper.push(
      context,
      BlocProvider(
        create: (_) =>
            InventoryItemDetailBloc()
              ..add(InventoryItemDetailRequested(item.id)),
        child: InventoryItemDetailScreen(itemId: item.id),
      ),
    );
  }

  void _openEditItem(Item item) {
    NavigatorHelper.push(
      context,
      BlocProvider(
        create: (_) =>
            InventoryItemDetailBloc()
              ..add(InventoryItemDetailRequested(item.id)),
        child: EditItemScreen(item: item),
      ),
    );
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

  void _handleSearch(BuildContext context) {
    final query = _searchController.text.trim();
    context.read<InventoryItemsBloc>().add(
      InventoryItemsRequested(searchQuery: query.isEmpty ? null : query),
    );
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  List<String> _buildCategories(List<Item> items) {
    final dynamicValues =
        items
            .map((item) => item.category?.trim())
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final merged = <String>{...inventoryCategories, ...dynamicValues}.toList();
    merged
      ..remove(_allCategoryLabel)
      ..sort();
    return <String>[_allCategoryLabel, ...merged];
  }

  List<Item> _filterItems(List<Item> items) {
    final selectedCategory = _selectedCategory.toLowerCase();
    return items
        .where((item) {
          if (_selectedCategory == _allCategoryLabel) return true;
          return item.category?.toLowerCase().trim().contains(
                selectedCategory,
              ) ??
              false;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: isMobile ? AppColors.iosBg : AppColors.bgCanvas,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _openAddItemScreen,
              backgroundColor: AppColors.primaryDeep,
              child: AppIcons.show(
                AppIcons.clipboardAdd,
                size: 22,
                color: AppColors.white,
              ),
            )
          : null,
      body: PageContent(
        maxWidth: 1200,
        fillHeight: true,
        child: SafeArea(
          child: BlocListener<InventoryItemsBloc, InventoryItemsState>(
            listenWhen: (previous, current) => current is InventoryItemsFailure,
            listener: (context, state) {
              if (state is InventoryItemsFailure) {
                AppToast.error(context, state.message);
              }
            },
            child: BlocBuilder<InventoryItemsBloc, InventoryItemsState>(
              builder: (context, state) {
                final isLoading =
                    state is InventoryItemsLoading ||
                    state is InventoryItemsInitial;
                final isLoaded = state is InventoryItemsLoaded;
                final items = isLoaded ? state.items : const <Item>[];
                final categories = isLoaded
                    ? _buildCategories(items)
                    : inventoryCategories;
                final filteredItems = isLoaded ? _filterItems(items) : items;
                final loadMoreError = isLoaded ? state.loadMoreError : null;
                final isLoadingMore = isLoaded && state.isLoadingMore;

                if (isMobile) {
                  return _buildMobileLayout(
                    context,
                    state: state,
                    isLoading: isLoading,
                    isLoaded: isLoaded,
                    items: items,
                    categories: categories,
                    filteredItems: filteredItems,
                    isLoadingMore: isLoadingMore,
                    loadMoreError: loadMoreError,
                  );
                }

                return _buildWebLayout(
                  context,
                  state: state,
                  isLoading: isLoading,
                  isLoaded: isLoaded,
                  items: items,
                  categories: categories,
                  filteredItems: filteredItems,
                  isLoadingMore: isLoadingMore,
                  loadMoreError: loadMoreError,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile Layout ─────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext context, {
    required InventoryItemsState state,
    required bool isLoading,
    required bool isLoaded,
    required List<Item> items,
    required List<String> categories,
    required List<Item> filteredItems,
    required bool isLoadingMore,
    required String? loadMoreError,
  }) {
    return RefreshIndicator(
      color: AppColors.primaryDeep,
      onRefresh: () async {
        final query = _searchController.text.trim();
        context.read<InventoryItemsBloc>().add(
          InventoryItemsRefreshed(searchQuery: query.isEmpty ? null : query),
        );
      },
      child: Container(
        color: AppColors.iosBg,
        child: ListView(
          controller: _scrollController,
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory',
                    style: AppFonts.extraBold(
                      fontSize: 22,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SearchTextField(
                    controller: _searchController,
                    hint: 'Search medications or equipment',
                    onSubmitted: (_) => _handleSearch(context),
                  ),
                  const SizedBox(height: 8),
                  _CategoryChips(
                    categories: categories,
                    selected: _selectedCategory,
                    onSelected: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is InventoryItemsFailure)
              _ErrorView(
                message: state.message,
                onRetry: () => context.read<InventoryItemsBloc>().add(
                  const InventoryItemsRequested(),
                ),
              )
            else if (filteredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'No inventory items yet.',
                    style: AppFonts.regular(
                      fontSize: 14,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
              )
            else
              Container(
                color: AppColors.surface,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    for (final item in filteredItems)
                      _InventoryItemCard(
                        item: item,
                        onTap: () => _openItemDetail(item),
                      ),
                    if (isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (loadMoreError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: TextButton(
                            onPressed: () => context
                                .read<InventoryItemsBloc>()
                                .add(const InventoryItemsPageRequested()),
                            child: const Text('Retry loading more'),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Web Layout ────────────────────────────────────────────────────────────

  Widget _buildWebLayout(
    BuildContext context, {
    required InventoryItemsState state,
    required bool isLoading,
    required bool isLoaded,
    required List<Item> items,
    required List<String> categories,
    required List<Item> filteredItems,
    required bool isLoadingMore,
    required String? loadMoreError,
  }) {
    int lowStock = 0, outOfStock = 0;
    for (final item in items) {
      final s = statusFor(item.onHand, minThresholdFor(item.category));
      if (s == InventoryStatus.lowStock) lowStock++;
      if (s == InventoryStatus.outOfStock) outOfStock++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoaded && (lowStock + outOfStock) > 0)
          _LowStockBanner(lowStock: lowStock, outOfStock: outOfStock),
        _WebHeader(
          itemCount: isLoaded ? items.length : null,
          onAddItem: _openAddItemScreen,
        ),
        _FilterBar(
          searchController: _searchController,
          categories: categories,
          selected: _selectedCategory,
          filteredCount: filteredItems.length,
          totalCount: items.length,
          onSearch: () => _handleSearch(context),
          onCategorySelected: (v) => setState(() => _selectedCategory = v),
        ),
        Expanded(
          child: _buildWebContent(
            context,
            state: state,
            isLoading: isLoading,
            items: items,
            filteredItems: filteredItems,
            isLoadingMore: isLoadingMore,
            loadMoreError: loadMoreError,
            lowStock: lowStock,
            outOfStock: outOfStock,
          ),
        ),
      ],
    );
  }

  Widget _buildWebContent(
    BuildContext context, {
    required InventoryItemsState state,
    required bool isLoading,
    required List<Item> items,
    required List<Item> filteredItems,
    required bool isLoadingMore,
    required String? loadMoreError,
    required int lowStock,
    required int outOfStock,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is InventoryItemsFailure) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<InventoryItemsBloc>().add(
          const InventoryItemsRequested(),
        ),
      );
    }
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcons.show(
              AppIcons.jarOfPills,
              size: 48,
              color: AppColors.slate400,
            ),
            const SizedBox(height: 12),
            Text(
              'No inventory items yet.',
              style: AppFonts.semiBold(fontSize: 15, color: AppColors.slate500),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your first item to get started.',
              style: AppFonts.regular(fontSize: 13, color: AppColors.slate400),
            ),
          ],
        ),
      );
    }
    return _InventoryWebTable(
      items: filteredItems,
      allItems: items,
      scrollController: _scrollController,
      isLoadingMore: isLoadingMore,
      loadMoreError: loadMoreError,
      onItemTap: _openItemDetail,
      onEditTap: _openEditItem,
      onRetryLoadMore: () => context.read<InventoryItemsBloc>().add(
        const InventoryItemsPageRequested(),
      ),
      lowStock: lowStock,
      outOfStock: outOfStock,
    );
  }
}

// ── Low Stock Banner ──────────────────────────────────────────────────────────

class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({required this.lowStock, required this.outOfStock});

  final int lowStock;
  final int outOfStock;

  @override
  Widget build(BuildContext context) {
    final total = lowStock + outOfStock;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amber50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.amber200),
        ),
        child: Row(
          children: [
            AppIcons.show(
              AppIcons.dangerTriangle,
              size: 20,
              color: AppColors.amber700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Alert: $total item${total == 1 ? '' : 's'} require attention',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber900,
                    ),
                  ),
                  if (lowStock > 0 || outOfStock > 0)
                    Text(
                      [
                        if (lowStock > 0) '$lowStock low stock',
                        if (outOfStock > 0) '$outOfStock out of stock',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.amber700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Web Header ────────────────────────────────────────────────────────────────

class _WebHeader extends StatelessWidget {
  const _WebHeader({required this.itemCount, required this.onAddItem});

  final int? itemCount;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory',
                style: AppFonts.extraBold(
                  fontSize: 28,
                  color: AppColors.slate900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Manage clinic supplies, medications, and equipment.',
                style: AppFonts.regular(
                  fontSize: 13,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onAddItem,
            icon: AppIcons.show(
              AppIcons.clipboardAdd,
              size: 17,
              color: Colors.white,
            ),
            label: const Text('Add New Item'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.categories,
    required this.selected,
    required this.filteredCount,
    required this.totalCount,
    required this.onSearch,
    required this.onCategorySelected,
  });

  final TextEditingController searchController;
  final List<String> categories;
  final String selected;
  final int filteredCount;
  final int totalCount;
  final VoidCallback onSearch;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          SearchTextField(
            controller: searchController,
            hint: 'Search medications, equipment, or supplies...',
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories
                          .map((label) {
                            final isSelected = label == selected;
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: _TabButton(
                                label: label,
                                isSelected: isSelected,
                                onTap: () => onCategorySelected(label),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                Text(
                  'Showing $filteredCount of $totalCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                AppIcons.show(
                  AppIcons.tuning,
                  size: 18,
                  color: AppColors.slate400,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipSelectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primaryDeep : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}

// ── Web Table ─────────────────────────────────────────────────────────────────

class _InventoryWebTable extends StatelessWidget {
  const _InventoryWebTable({
    required this.items,
    required this.allItems,
    required this.scrollController,
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onItemTap,
    required this.onEditTap,
    required this.onRetryLoadMore,
    required this.lowStock,
    required this.outOfStock,
  });

  final List<Item> items;
  final List<Item> allItems;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final String? loadMoreError;
  final ValueChanged<Item> onItemTap;
  final ValueChanged<Item> onEditTap;
  final VoidCallback onRetryLoadMore;
  final int lowStock;
  final int outOfStock;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showCategory = w >= 680;
        final showSku = w >= 820;
        final showPrice = w >= 960;

        // Extra items: header(1) + footer(1) + stats bento(1)
        final itemCount = items.length + 3;

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            // Table wrapper header
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _TableHeaderRow(
                    showCategory: showCategory,
                    showSku: showSku,
                    showPrice: showPrice,
                  ),
                ),
              );
            }

            // Table row items
            if (index <= items.length) {
              final item = items[index - 1];
              final isLast = index == items.length;
              final isRounded =
                  isLast && loadMoreError == null && !isLoadingMore;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: isRounded
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        )
                      : null,
                  border: isRounded
                      ? Border.all(color: AppColors.border)
                      : Border(
                          left: BorderSide(color: AppColors.border),
                          right: BorderSide(color: AppColors.border),
                          bottom: BorderSide(color: AppColors.borderFaint),
                        ),
                ),
                child: _InventoryTableRow(
                  item: item,
                  onTap: () => onItemTap(item),
                  onEdit: () => onEditTap(item),
                  showCategory: showCategory,
                  showSku: showSku,
                  showPrice: showPrice,
                ),
              );
            }

            // Load-more footer row
            if (index == items.length + 1) {
              final hasFooterContent = isLoadingMore || loadMoreError != null;
              if (!hasFooterContent) return const SizedBox(height: 8);
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    left: BorderSide(color: AppColors.border),
                    right: BorderSide(color: AppColors.border),
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: _TableFooter(
                  isLoadingMore: isLoadingMore,
                  loadMoreError: loadMoreError,
                  onRetry: onRetryLoadMore,
                ),
              );
            }

            // Stats bento
            return _StatsBento(
              allItems: allItems,
              lowStock: lowStock,
              outOfStock: outOfStock,
            );
          },
        );
      },
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({
    required this.showCategory,
    required this.showSku,
    required this.showPrice,
  });

  final bool showCategory;
  final bool showSku;
  final bool showPrice;

  static const _headerStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.slate500,
    letterSpacing: 0.6,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Text('ITEM NAME', style: _headerStyle),
          ),
          if (showCategory)
            const Expanded(
              flex: 2,
              child: Text('CATEGORY', style: _headerStyle),
            ),
          if (showSku)
            const Expanded(flex: 2, child: Text('SKU', style: _headerStyle)),
          const Expanded(
            flex: 2,
            child: Text('STOCK LEVEL', style: _headerStyle),
          ),
          if (showPrice)
            SizedBox(
              width: 80,
              child: const Text(
                'PRICE',
                style: _headerStyle,
                textAlign: TextAlign.right,
              ),
            ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _InventoryTableRow extends StatefulWidget {
  const _InventoryTableRow({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.showCategory,
    required this.showSku,
    required this.showPrice,
  });

  final Item item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final bool showCategory;
  final bool showSku;
  final bool showPrice;

  @override
  State<_InventoryTableRow> createState() => _InventoryTableRowState();
}

class _InventoryTableRowState extends State<_InventoryTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final status = statusFor(item.onHand, minThresholdFor(item.category));
    final sku = _skuFrom(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hovering) {
          if (_hovered == hovering) return;
          setState(() => _hovered = hovering);
        },
        hoverColor: AppColors.slate50,
        splashColor: AppColors.primaryDeep.withValues(alpha: 0.06),
        highlightColor: AppColors.primaryDeep.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    _ItemIcon(category: item.category),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showCategory)
                Expanded(
                  flex: 2,
                  child: Text(
                    item.category ?? 'General',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
              if (widget.showSku)
                Expanded(
                  flex: 2,
                  child: Text(
                    sku,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: _StockBadge(
                  status: status,
                  quantity: item.onHand,
                  unit: item.unit,
                ),
              ),
              if (widget.showPrice)
                SizedBox(
                  width: 80,
                  child: Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
              SizedBox(
                width: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: widget.onEdit,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AppIcons.show(
                        AppIcons.penNewSquare,
                        size: 17,
                        color: _hovered
                            ? AppColors.primaryDeep
                            : AppColors.slate400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({
    required this.isLoadingMore,
    required this.loadMoreError,
    required this.onRetry,
  });

  final bool isLoadingMore;
  final String? loadMoreError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
      );
    }
    if (loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDeep),
            child: const Text('Retry loading more'),
          ),
        ),
      );
    }
    return const SizedBox(height: 4);
  }
}

// ── Stats Bento ───────────────────────────────────────────────────────────────

class _StatsBento extends StatelessWidget {
  const _StatsBento({
    required this.allItems,
    required this.lowStock,
    required this.outOfStock,
  });

  final List<Item> allItems;
  final int lowStock;
  final int outOfStock;

  @override
  Widget build(BuildContext context) {
    final inventoryValue = allItems.fold<double>(
      0,
      (sum, item) => sum + item.price * item.onHand,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: _BentoCard(
              iconAsset: AppIcons.walletMoney,
              iconColor: AppColors.primaryDeep,
              label: 'Inventory Value',
              value:
                  '\$${inventoryValue >= 10000 ? '${(inventoryValue / 1000).toStringAsFixed(1)}k' : inventoryValue.toStringAsFixed(2)}',
              subtitle: '${allItems.length} items tracked',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _BentoCard(
              iconAsset: AppIcons.dangerTriangle,
              iconColor: AppColors.amberStock,
              label: 'Low Stock',
              value: '$lowStock',
              subtitle: 'Items below threshold',
              valueColor: lowStock > 0 ? AppColors.amberStock : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _BentoCard(
              iconAsset: AppIcons.dangerTriangle,
              iconColor: AppColors.error,
              label: 'Out of Stock',
              value: '$outOfStock',
              subtitle: 'Needs reordering',
              valueColor: outOfStock > 0 ? AppColors.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.iconAsset,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor,
  });

  final String iconAsset;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate400,
                  letterSpacing: 0.8,
                ),
              ),
              AppIcons.show(iconAsset, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.slate900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stock Badge ───────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.status,
    required this.quantity,
    required this.unit,
  });

  final InventoryStatus status;
  final double quantity;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final textColor = switch (status) {
      InventoryStatus.inStock => AppColors.stockIn,
      InventoryStatus.lowStock => AppColors.amberStock,
      InventoryStatus.outOfStock => AppColors.error,
    };

    final qty = formatQuantity(quantity);

    return Text(
      '$qty $unit',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

// ── Item Icon ─────────────────────────────────────────────────────────────────

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final cat = (category ?? '').toLowerCase();
    final String asset;
    final Color bg, iconColor;

    if (cat.contains('med') || cat.contains('vacc')) {
      asset = AppIcons.jarOfPills;
      bg = AppColors.tintBlueBg;
      iconColor = AppColors.primaryDeep;
    } else if (cat.contains('surg') || cat.contains('equip')) {
      asset = AppIcons.stethoscope;
      bg = AppColors.tintGreyBg;
      iconColor = AppColors.slate600;
    } else if (cat.contains('food') || cat.contains('diet')) {
      asset = AppIcons.shop;
      bg = AppColors.tintVioletBg;
      iconColor = AppColors.tintViolet;
    } else {
      asset = AppIcons.adhesivePlaster;
      bg = AppColors.stockInBg;
      iconColor = AppColors.stockIn;
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(child: AppIcons.show(asset, size: 18, color: iconColor)),
    );
  }
}

// ── Category Chips (mobile) ───────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map((label) {
              final isSelected = label == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelected(label),
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryDeep
                          : AppColors.chipPaleBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDeep
                            : AppColors.chipPaleBorder,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

// ── Mobile Item Card ──────────────────────────────────────────────────────────

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minThreshold = minThresholdFor(item.category);
    final status = statusFor(item.onHand, minThreshold);

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primaryDeep.withValues(alpha: 0.08),
        highlightColor: AppColors.primaryDeep.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _ItemThumb(category: item.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (item.category ?? 'General').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate400,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _StockBadge(
                      status: status,
                      quantity: item.onHand,
                      unit: item.unit,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${formatQuantity(item.onHand)} ${unitLabel(item.unit)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final cat = (category ?? '').toLowerCase();
    final String asset;
    final List<Color> gradientColors;

    if (cat.contains('med') || cat.contains('vacc')) {
      asset = AppIcons.jarOfPills;
      gradientColors = const [AppColors.gradMedStart, AppColors.gradMedEnd];
    } else if (cat.contains('equip')) {
      asset = AppIcons.stethoscope;
      gradientColors = const [AppColors.gradEquipStart, AppColors.greyBlue];
    } else if (cat.contains('consum') || cat.contains('clean')) {
      asset = AppIcons.adhesivePlaster;
      gradientColors = const [
        AppColors.gradConsumStart,
        AppColors.gradConsumEnd,
      ];
    } else if (cat.contains('food') || cat.contains('diet')) {
      asset = AppIcons.shop;
      gradientColors = const [
        AppColors.gradDefaultStart,
        AppColors.gradDefaultEnd,
      ];
    } else {
      asset = AppIcons.stethoscope;
      gradientColors = const [
        AppColors.gradDefaultStart,
        AppColors.gradDefaultEnd,
      ];
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Center(
        child: AppIcons.show(
          asset,
          size: 26,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              style: AppFonts.regular(fontSize: 13, color: AppColors.slate500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 180,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _skuFrom(Item item) {
  final normalized = item.name
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
  if (normalized.isEmpty) {
    final id = item.id.replaceAll('-', '').toUpperCase();
    return id.substring(0, min(8, id.length));
  }
  return normalized.split('-').take(3).join('-');
}
