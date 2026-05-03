import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/enums/item_status_enum.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/inventory/add_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/item_detail_page.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_consts.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/search_textfield.dart';
import 'package:clinic_management_app/widgets/status_chip.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemScreen,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
      body: SafeArea(
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

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  final query = _searchController.text.trim();
                  context.read<InventoryItemsBloc>().add(
                    InventoryItemsRefreshed(
                      searchQuery: query.isEmpty ? null : query,
                    ),
                  );
                },
                child: Container(
                  color: AppColors.iosBg,
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      Container(
                        color: AppColors.white,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                            const SizedBox(height: 14),
                            SearchTextField(
                              controller: _searchController,
                              hint: 'Search medications or equipment',
                              onSubmitted: (_) {
                                final query = _searchController.text.trim();
                                context.read<InventoryItemsBloc>().add(
                                  InventoryItemsRequested(
                                    searchQuery: query.isEmpty ? null : query,
                                  ),
                                );
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            _CategoryChips(
                              categories: categories,
                              selected: _selectedCategory,
                              onSelected: (value) {
                                setState(() => _selectedCategory = value);
                              },
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
                          child: Column(
                            children: [
                              const Center(
                                child: Text('No inventory items yet.'),
                              ),
                              if (isLoaded && state.isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Container(
                          color: AppColors.white,
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              ...filteredItems.map(
                                (item) => _InventoryItemCard(
                                  item: item,
                                  onTap: () => _openItemDetail(item),
                                ),
                              ),
                              if (isLoaded && state.isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (isLoaded && loadMoreError != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () => context
                                          .read<InventoryItemsBloc>()
                                          .add(
                                            const InventoryItemsPageRequested(),
                                          ),
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
            },
          ),
        ),
      ),
    );
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
          final matchesCategory =
              _selectedCategory == _allCategoryLabel ||
              (item.category?.toLowerCase().trim().contains(selectedCategory) ??
                  false);

          if (!matchesCategory) return false;
          return true;
        })
        .toList(growable: false);
  }
}

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
                padding: const EdgeInsets.only(right: 10),
                child: _CategoryChip(
                  label: label,
                  isSelected: isSelected,
                  onTap: () => onSelected(label),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F6FB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE1ECFA),
          ),
        ),
        child: Text(
          label,
          style: AppFonts.bold(
            fontSize: 12,
            color: isSelected ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minThreshold = minThresholdFor(item.category);
    final status = statusFor(item.onHand, minThreshold);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withOpacity(0.2),
        highlightColor: AppColors.primary.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              _ItemThumb(category: item.category),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: .spaceBetween,
                  spacing: 5,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.bold(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      (item.category ?? 'Inventory').toUpperCase(),
                      style: AppFonts.semiBold(
                        fontSize: 10,
                        color: AppColors.greyBlue,
                        letterSpacing: 0.6,
                      ),
                    ),
                    StatusChip(status: status),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${formatQuantity(item.onHand)} ${unitLabel(item.unit)}',
                style: AppFonts.bold(fontSize: 16, color: AppColors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              style: AppFonts.regular(fontSize: 13, color: AppColors.black),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 180,
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

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final icon = switch ((category ?? '').toLowerCase()) {
      final value when value.contains('equip') =>
        Icons.medical_services_outlined,
      final value when value.contains('consum') => Icons.clean_hands_outlined,
      _ => Icons.vaccines_outlined,
    };

    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B22), AppColors.greyBlue],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Icon(icon, color: AppColors.white.withOpacity(0.92), size: 34),
    );
  }
}
