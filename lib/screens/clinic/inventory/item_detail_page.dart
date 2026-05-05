import 'package:clinic_management_app/bloc/inventory_bloc/item_detail_bloc.dart';
import 'package:clinic_management_app/bloc/inventory_bloc/items_bloc.dart';
import 'package:clinic_management_app/models/enums/item_status_enum.dart';
import 'package:clinic_management_app/models/inventory_txn.dart';
import 'package:clinic_management_app/models/item.dart';
import 'package:clinic_management_app/navigation/navigation_helper.dart';
import 'package:clinic_management_app/screens/clinic/inventory/adjust_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/edit_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/recieve_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/use_item_screen.dart';
import 'package:clinic_management_app/screens/clinic/inventory/waste_item_screen.dart';
import 'package:clinic_management_app/services/inventory_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/app_toast.dart';
import 'package:clinic_management_app/widgets/custom_appbar.dart';
import 'package:clinic_management_app/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class InventoryItemDetailScreen extends StatelessWidget {
  const InventoryItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryItemDetailBloc, InventoryItemDetailState>(
      listener: (context, state) {
        if (state is InventoryItemDetailFailure) {
          AppToast.error(context, state.message);
        }
      },
      builder: (context, state) {
        final loadedItem = state is InventoryItemDetailLoaded
            ? state.item
            : null;
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Item Details',
              style: AppFonts.bold(fontSize: 18, color: AppColors.black),
            ),
            actions: [
              PopupMenuButton<_DetailMenuAction>(
                tooltip: 'More',
                onSelected: (action) {
                  switch (action) {
                    case _DetailMenuAction.refresh:
                      context.read<InventoryItemDetailBloc>().add(
                        const InventoryItemDetailRefreshed(),
                      );
                      context.read<InventoryItemsBloc>().add(
                        InventoryItemRefetched(itemId: itemId),
                      );
                      return;
                    case _DetailMenuAction.edit:
                      final item = loadedItem;
                      if (item == null) return;
                      NavigatorHelper.push(
                        context,
                        BlocProvider.value(
                          value: context.read<InventoryItemDetailBloc>(),
                          child: EditItemScreen(item: item),
                        ),
                      );
                      return;
                  }
                },
                itemBuilder: (context) => [
                  if (loadedItem != null)
                    const PopupMenuItem(
                      value: _DetailMenuAction.edit,
                      child: Text('Edit'),
                    ),
                  const PopupMenuItem(
                    value: _DetailMenuAction.refresh,
                    child: Text('Refresh'),
                  ),
                ],
                icon: const Icon(Icons.more_vert_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: switch (state) {
            InventoryItemDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            InventoryItemDetailFailure(message: final message) =>
              _DetailErrorView(
                message: message,
                onRetry: () => context.read<InventoryItemDetailBloc>().add(
                  InventoryItemDetailRequested(itemId),
                ),
              ),
            InventoryItemDetailLoaded(item: final item, txns: final txns) =>
              _InventoryDetailView(item: item, txns: txns),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

enum _DetailMenuAction { edit, refresh }

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.item,
    required this.txns,
    required this.onCreateTxn,
  });

  final Item item;
  final List<InventoryTxn> txns;
  final ValueChanged<InventoryTxnType> onCreateTxn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ItemHeader(item: item),
        const Divider(height: 1, color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Receive',
                icon: Icons.add,
                onPressed: () => onCreateTxn(InventoryTxnType.receive),
              ),
              _ActionButton(
                label: 'Use',
                icon: Icons.remove,
                onPressed: () => onCreateTxn(InventoryTxnType.use),
                isPrimary: false,
              ),
              _ActionButton(
                label: 'Waste',
                icon: Icons.delete_outline,
                onPressed: () => onCreateTxn(InventoryTxnType.waste),
                isPrimary: false,
              ),
              _ActionButton(
                label: 'Adjust',
                icon: Icons.tune,
                onPressed: () => onCreateTxn(InventoryTxnType.adjust),
                isPrimary: false,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        Expanded(
          child: txns.isEmpty
              ? const Center(child: Text('No transactions yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: txns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final txn = txns[index];
                    return _TxnTile(txn: txn, unit: item.unit);
                  },
                ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary ? AppColors.primary : AppColors.lightGrey;
    final foregroundColor = isPrimary ? AppColors.white : AppColors.black;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 12),
      label: Text(label, style: AppFonts.medium()),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: AppFonts.medium(fontSize: 12, color: foregroundColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppFonts.bold(fontSize: 14, color: AppColors.black),
                ),
                if (item.category != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.category!,
                    style: AppFonts.regular(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _OnHandCard(item: item),
        ],
      ),
    );
  }
}

class _OnHandCard extends StatelessWidget {
  const _OnHandCard({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'On hand',
            style: AppFonts.medium(fontSize: 11, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatQuantity(item.onHand)} ${item.unit}',
            style: AppFonts.bold(fontSize: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn, required this.unit});

  final InventoryTxn txn;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(txn.createdAt.toLocal());
    final quantityLabel = _quantityLabel(txn, unit);
    final iconColor = _iconColor(txn.txnType);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_iconFor(txn.txnType), color: iconColor, size: 18),
      ),
      title: Text(
        txn.txnType.label,
        style: AppFonts.semiBold(fontSize: 13, color: AppColors.black),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: AppFonts.regular(fontSize: 11, color: AppColors.grey),
          ),
          if (txn.note != null && txn.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                txn.note!,
                style: AppFonts.regular(fontSize: 12, color: AppColors.black),
              ),
            ),
        ],
      ),
      trailing: Text(
        quantityLabel,
        style: AppFonts.bold(fontSize: 13, color: iconColor),
      ),
      isThreeLine: txn.note != null && txn.note!.isNotEmpty,
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  const _DetailErrorView({required this.message, required this.onRetry});

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

IconData _iconFor(InventoryTxnType type) {
  switch (type) {
    case InventoryTxnType.receive:
      return Icons.add_circle_outline;
    case InventoryTxnType.use:
      return Icons.remove_circle_outline;
    case InventoryTxnType.waste:
      return Icons.delete_outline;
    case InventoryTxnType.adjust:
      return Icons.tune;
  }
}

Color _iconColor(InventoryTxnType type) {
  switch (type) {
    case InventoryTxnType.receive:
      return AppColors.success;
    case InventoryTxnType.use:
      return AppColors.primary;
    case InventoryTxnType.waste:
      return AppColors.error;
    case InventoryTxnType.adjust:
      return AppColors.warning;
  }
}

String _quantityLabel(InventoryTxn txn, String unit) {
  final qty = _formatQuantity(txn.quantity);
  switch (txn.txnType) {
    case InventoryTxnType.receive:
      return '+$qty $unit';
    case InventoryTxnType.use:
    case InventoryTxnType.waste:
      return '-$qty $unit';
    case InventoryTxnType.adjust:
      return '= $qty $unit';
  }
}

String _formatQuantity(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatMoney(double value) {
  return NumberFormat.currency(symbol: '\$').format(value);
}

class _InventoryDetailView extends StatelessWidget {
  const _InventoryDetailView({required this.item, required this.txns});

  final Item item;
  final List<InventoryTxn> txns;

  @override
  Widget build(BuildContext context) {
    final minThreshold = _detailMinThresholdFor(item.category);
    final status = _detailStatusFor(item.onHand, minThreshold);
    final locations = _detailLocations(item.onHand);
    final expirations = _detailExpirations(item.onHand);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<InventoryItemDetailBloc>().add(
          const InventoryItemDetailRefreshed(),
        );
        context.read<InventoryItemsBloc>().add(
          InventoryItemRefetched(itemId: item.id),
        );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _HeroImage(category: item.category),
          const SizedBox(height: 18),
          _HeaderSection(
            item: item,
            statusLabel: status.label,
            statusColor: status.foreground,
          ),
          const SizedBox(height: 12),
          // Text(
          //   'Broad-spectrum antibiotic used for various bacterial infections in small animals. Store at room temperature away from direct sunlight.',
          //   style: AppFonts.regular(fontSize: 12, color: AppColors.black),
          // ),
          // const SizedBox(height: 12),
          _ActionGrid(item: item),
          const SizedBox(height: 12),
          _InventoryStatusCard(onHand: item.onHand, minThreshold: minThreshold),
          const SizedBox(height: 12),
          // const _SectionTitle('Stock by Location'),
          // const SizedBox(height: 10),
          // ...locations.map(
          //   (entry) => Padding(
          //     padding: const EdgeInsets.only(bottom: 10),
          //     child: _LocationTile(name: entry.name, quantity: entry.quantity),
          //   ),
          // ),
          // const SizedBox(height: 18),
          // const _SectionTitle('Upcoming Expirations'),
          // const SizedBox(height: 10),
          // _ExpirationCard(entries: expirations),
          // const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Recent Activity'),
              InkWell(
                onTap: () => NavigatorHelper.push(
                  context,
                  InventoryTxnHistoryScreen(itemId: item.id, unit: item.unit),
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    'History',
                    style: AppFonts.semiBold(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RecentActivityList(txns: txns, unit: item.unit),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final icon = switch ((category ?? '').toLowerCase()) {
      final value when value.contains('equip') => Icons.monitor_heart_outlined,
      final value when value.contains('consum') => Icons.sanitizer_outlined,
      _ => Icons.medication_outlined,
    };

    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E231B), Color(0xFF7A9C90)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 64, color: AppColors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.item,
    required this.statusLabel,
    required this.statusColor,
  });

  final Item item;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppFonts.extraBold(fontSize: 22, color: AppColors.black),
              ),
              const SizedBox(height: 6),

              Text(
                '${item.category}'.toUpperCase(),
                style: AppFonts.semiBold(
                  fontSize: 10,
                  color: AppColors.greyBlue,
                  letterSpacing: 0.6,
                ),
              ),
              if (item.price > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Price: ${_formatMoney(item.price)}',
                  style: AppFonts.semiBold(
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
              // const SizedBox(height: 6),
              // Text(
              //   '${item.onHand.toInt()} ${item.unit}',
              //   style: AppFonts.semiBold(
              //     fontSize: 13,
              //     color: AppColors.darkGrey,
              //   ),
              // ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        StatusChip(
          status: statusFor(item.onHand, minThresholdFor(item.category)),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            label: 'Receive',
            icon: Icons.add_box_rounded,
            background: AppColors.primary,
            foreground: AppColors.white,
            onTap: () => NavigatorHelper.push(
              context,
              BlocProvider.value(
                value: context.read<InventoryItemDetailBloc>(),
                child: RecieveItemScreen(item: item),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            label: 'Use',
            icon: Icons.remove_circle_rounded,
            background: AppColors.primary.withValues(alpha: 0.16),
            foreground: AppColors.primary,
            onTap: () => NavigatorHelper.push(
              context,
              BlocProvider.value(
                value: context.read<InventoryItemDetailBloc>(),
                child: UseItemScreen(item: item),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            label: 'Waste',
            icon: Icons.delete_forever_rounded,
            background: const Color(0xFFFFF1F1),
            foreground: const Color(0xFFD32F2F),
            onTap: () => NavigatorHelper.push(
              context,
              BlocProvider.value(
                value: context.read<InventoryItemDetailBloc>(),
                child: WasteItemScreen(item: item),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            label: 'Adjust',
            icon: Icons.tune_rounded,
            background: const Color(0xFFF1F5FA),
            foreground: const Color(0xFF2E3E52),
            onTap: () => NavigatorHelper.push(
              context,
              BlocProvider.value(
                value: context.read<InventoryItemDetailBloc>(),
                child: AdjustItemScreen(item: item),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: foreground.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: foreground, size: 25),
            const SizedBox(height: 4),
            Text(label, style: AppFonts.bold(fontSize: 12, color: foreground)),
          ],
        ),
      ),
    );
  }
}

class _InventoryStatusCard extends StatelessWidget {
  const _InventoryStatusCard({
    required this.onHand,
    required this.minThreshold,
  });

  final double onHand;
  final double minThreshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE6EEF9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
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
                'Inventory Status',
                style: AppFonts.bold(fontSize: 14, color: AppColors.black),
              ),
              Text(
                'View Detail',
                style: AppFonts.semiBold(
                  fontSize: 10,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatusStatTile(
                  label: 'Total On Hand',
                  value: '${_formatQuantity(onHand)} units',
                  valueColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusStatTile(
                  label: 'Min. Threshold',
                  value: '${_formatQuantity(minThreshold)} units',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusStatTile extends StatelessWidget {
  const _StatusStatTile({
    required this.label,
    required this.value,
    this.valueColor = AppColors.black,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE1ECFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.medium(
              fontSize: 10,
              color: const Color(0xFF6C87A8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.extraBold(fontSize: 16, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppFonts.bold(fontSize: 16, color: AppColors.black),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.name, required this.quantity});

  final String name;
  final double quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EEF9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppFonts.semiBold(fontSize: 15, color: AppColors.black),
            ),
          ),
          Text(
            '${_formatQuantity(quantity)} units',
            style: AppFonts.bold(fontSize: 15, color: AppColors.black),
          ),
        ],
      ),
    );
  }
}

class _ExpirationCard extends StatelessWidget {
  const _ExpirationCard({required this.entries});

  final List<_DetailExpirationEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EEF9)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4FA)),
            _ExpirationRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _ExpirationRow extends StatelessWidget {
  const _ExpirationRow({required this.entry});

  final _DetailExpirationEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = entry.isSoon
        ? const Color(0xFFF0A020)
        : const Color(0xFFB8C6D9);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 50,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.lot,
                  style: AppFonts.bold(fontSize: 14, color: AppColors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  'Exp: ${DateFormat.yMMMd().format(entry.expiry)}',
                  style: AppFonts.medium(
                    fontSize: 12,
                    color: const Color(0xFF6C87A8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatQuantity(entry.quantity)} units',
                style: AppFonts.bold(fontSize: 14, color: AppColors.black),
              ),
              const SizedBox(height: 2),
              Text(
                entry.isSoon ? 'EXPIRING SOON' : 'STABLE',
                style: AppFonts.bold(
                  fontSize: 10,
                  color: entry.isSoon
                      ? const Color(0xFFF0A020)
                      : const Color(0xFF9AAAC0),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.txns, required this.unit});

  final List<InventoryTxn> txns;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (txns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EEF9)),
        ),
        child: Text(
          'No recent activity yet.',
          style: AppFonts.medium(fontSize: 14, color: const Color(0xFF6C87A8)),
        ),
      );
    }

    final recent = txns.take(4).toList(growable: false);
    return Column(
      children: recent
          .map(
            (txn) => _ActivityRow(
              txn: txn,
              unit: unit,
              isLast: identical(txn, recent.last),
            ),
          )
          .toList(growable: false),
    );
  }
}

class InventoryTxnHistoryScreen extends StatefulWidget {
  const InventoryTxnHistoryScreen({
    super.key,
    required this.itemId,
    required this.unit,
  });

  final String itemId;
  final String unit;

  @override
  State<InventoryTxnHistoryScreen> createState() =>
      _InventoryTxnHistoryScreenState();
}

class _InventoryTxnHistoryScreenState extends State<InventoryTxnHistoryScreen> {
  static const int _pageSize = 20;
  final InventoryService _inventoryService = InventoryService();
  final ScrollController _scrollController = ScrollController();

  final List<InventoryTxn> _txns = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading) return;
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      _load();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_isLoading) return;
    if (!_hasMore && !refresh) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _error = null;
      }
    });

    try {
      final offset = refresh ? 0 : _txns.length;
      final results = await _inventoryService.fetchTxnsForItem(
        widget.itemId,
        limit: _pageSize,
        offset: offset,
      );

      setState(() {
        if (refresh) {
          _txns
            ..clear()
            ..addAll(results);
        } else {
          _txns.addAll(results);
        }
        _hasMore = results.length == _pageSize;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = 'Failed to load history: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _initialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: "Activity History"),
      body: Builder(
        builder: (context) {
          if (_initialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null && _txns.isEmpty) {
            return _DetailErrorView(
              message: _error!,
              onRetry: () => _load(refresh: true),
            );
          }

          if (_txns.isEmpty) {
            return const Center(child: Text('No activity yet.'));
          }

          final extraLoader = _isLoading ? 1 : 0;
          final extraError = (_error != null) ? 1 : 0;
          final total = _txns.length + extraLoader + extraError;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _load(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: total,
              itemBuilder: (context, index) {
                if (index < _txns.length) {
                  final txn = _txns[index];
                  return Column(
                    children: [
                      _TxnTile(txn: txn, unit: widget.unit),
                      if (index < _txns.length - 1) const Divider(height: 1),
                    ],
                  );
                }

                final loaderIndex = _txns.length;
                if (_isLoading && index == loaderIndex) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: TextButton(
                      onPressed: () => _load(),
                      child: const Text('Retry'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.txn,
    required this.unit,
    required this.isLast,
  });

  final InventoryTxn txn;
  final String unit;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _detailActivityColor(txn.txnType);
    final label = _detailActivityLabel(txn.txnType);
    final deltaLabel = _detailDeltaLabel(txn, unit);

    final trailingText = (txn.note != null && txn.note!.trim().isNotEmpty)
        ? txn.note!.trim()
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 20,
            child: Column(
              children: [
                // pill
                Container(
                  width: 14,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                // connector (starts clearly below pill)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 1.5,
                  height: 40,
                  color: AppColors.lightGrey,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Content
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppFonts.semiBold(
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Text(
                      _detailTimeAgo(txn.createdAt),
                      style: AppFonts.medium(
                        fontSize: 10,
                        color: const Color(0xFF8AA0BC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Delta + trailing text (same line)
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: deltaLabel,
                        style: AppFonts.bold(fontSize: 14, color: color),
                      ),
                      if (trailingText != null)
                        TextSpan(
                          text: " - $trailingText",
                          style: AppFonts.medium(
                            fontSize: 10,
                            color: const Color(0xFF5D7FA6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLocationEntry {
  const _DetailLocationEntry({required this.name, required this.quantity});

  final String name;
  final double quantity;
}

class _DetailExpirationEntry {
  const _DetailExpirationEntry({
    required this.lot,
    required this.expiry,
    required this.quantity,
    required this.isSoon,
  });

  final String lot;
  final DateTime expiry;
  final double quantity;
  final bool isSoon;
}

enum _DetailItemStatus { lowStock, inStock, outOfStock }

extension on _DetailItemStatus {
  String get label => switch (this) {
    _DetailItemStatus.lowStock => 'Low Stock',
    _DetailItemStatus.inStock => 'In Stock',
    _DetailItemStatus.outOfStock => 'Out of Stock',
  };

  Color get foreground => switch (this) {
    _DetailItemStatus.lowStock => const Color(0xFFB35A00),
    _DetailItemStatus.inStock => AppColors.primary,
    _DetailItemStatus.outOfStock => AppColors.error,
  };
}

_DetailItemStatus _detailStatusFor(double onHand, double minThreshold) {
  if (onHand <= 0) return _DetailItemStatus.outOfStock;
  if (onHand <= minThreshold) return _DetailItemStatus.lowStock;
  return _DetailItemStatus.inStock;
}

double _detailMinThresholdFor(String? category) {
  final value = (category ?? '').toLowerCase();
  if (value.contains('equip')) return 2;
  if (value.contains('consum')) return 50;
  if (value.contains('med') || value.contains('vacc')) return 20;
  return 10;
}

String _detailSkuFromItem(Item item) {
  final normalized = item.name
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();

  if (normalized.isEmpty) {
    final id = item.id.replaceAll('-', '').toUpperCase();
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  return normalized.split('-').take(3).join('-');
}

List<_DetailLocationEntry> _detailLocations(double total) {
  if (total <= 0) {
    return const [
      _DetailLocationEntry(name: 'Main Pharmacy', quantity: 0),
      _DetailLocationEntry(name: 'Surgery Room A', quantity: 0),
      _DetailLocationEntry(name: 'Exam Room 1', quantity: 0),
    ];
  }

  final main = total * 0.67;
  final surgery = total * 0.2;
  final exam = (total - main - surgery).clamp(0, double.infinity).toDouble();

  return [
    _DetailLocationEntry(name: 'Main Pharmacy', quantity: main),
    _DetailLocationEntry(name: 'Surgery Room A', quantity: surgery),
    _DetailLocationEntry(name: 'Exam Room 1', quantity: exam),
  ];
}

List<_DetailExpirationEntry> _detailExpirations(double total) {
  final now = DateTime.now();
  final soon = now.add(const Duration(days: 120));
  final later = now.add(const Duration(days: 260));

  final soonQty = total * 0.32;
  final laterQty = (total - soonQty).clamp(0, double.infinity).toDouble();

  return [
    _DetailExpirationEntry(
      lot: 'Lot #AMX-9921',
      expiry: soon,
      quantity: soonQty,
      isSoon: true,
    ),
    _DetailExpirationEntry(
      lot: 'Lot #AMX-1044',
      expiry: later,
      quantity: laterQty,
      isSoon: false,
    ),
  ];
}

String _detailActivityLabel(InventoryTxnType type) {
  return switch (type) {
    InventoryTxnType.receive => 'Stock Received',
    InventoryTxnType.use => 'Used in Procedure',
    InventoryTxnType.waste => 'Waste Logged',
    InventoryTxnType.adjust => 'Inventory Adjusted',
  };
}

Color _detailActivityColor(InventoryTxnType type) {
  return switch (type) {
    InventoryTxnType.receive => const Color(0xFF1C8C3A),
    InventoryTxnType.use => AppColors.primary,
    InventoryTxnType.waste => const Color(0xFFD32F2F),
    InventoryTxnType.adjust => const Color(0xFF8A9AAF),
  };
}

String _detailDeltaLabel(InventoryTxn txn, String unit) {
  final qty = _formatQuantity(txn.quantity);
  final unitLabel = unit.trim().isEmpty ? 'units' : unit.toLowerCase();
  return switch (txn.txnType) {
    InventoryTxnType.receive => '+$qty $unitLabel',
    InventoryTxnType.use => '-$qty $unitLabel',
    InventoryTxnType.waste => '-$qty $unitLabel',
    InventoryTxnType.adjust => '= $qty $unitLabel',
  };
}

String _detailTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime.toLocal());

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  return DateFormat.yMMMd().format(dateTime.toLocal());
}
