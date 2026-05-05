import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_fonts.dart';

class SelectableChips extends StatefulWidget {
  const SelectableChips({
    super.key,
    required this.items,
    this.initialSelected = const [],
    this.onSelectionChanged,
    this.labelStyle,
    this.selectedColor,
    this.unselectedColor,
    this.chipSpacing = 4,
  });

  final List<String> items;
  final List<String> initialSelected;
  final void Function(List<String> selected)? onSelectionChanged;
  final TextStyle? labelStyle;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double chipSpacing;

  @override
  State<SelectableChips> createState() => _SelectableChipsState();
}

class _SelectableChipsState extends State<SelectableChips> {
  late List<String> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.initialSelected);
  }

  void _toggleItem(String item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });

    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged!(selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.chipSpacing,
      runSpacing: 0,
      children: widget.items.map((item) {
        final isSelected = selectedItems.contains(item);
        return GestureDetector(
          onTap: () => _toggleItem(item),
          child: Chip(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check,
                    size: 16,
                    color: widget.selectedColor ?? AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  item,
                  style:
                      widget.labelStyle ??
                      AppFonts.regular(fontSize: 12, color: AppColors.black),
                ),
              ],
            ),
            backgroundColor: isSelected
                ? (widget.selectedColor ?? AppColors.primary).withValues(alpha: 0.2)
                : (widget.unselectedColor ?? AppColors.grey).withValues(alpha: 0.2),
            side: BorderSide(
              color: isSelected
                  ? (widget.selectedColor ?? AppColors.primary)
                  : (widget.unselectedColor ?? AppColors.grey).withValues(alpha: 0.3),
            ),
          ),
        );
      }).toList(),
    );
  }
}
