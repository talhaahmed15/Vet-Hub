import 'dart:ui';

import 'package:clinic_management_app/screens/clinic/appointment/recent_appointments_screen.dart';
import 'package:clinic_management_app/screens/clinic/dashboard/clinic_dashboard.dart';
import 'package:clinic_management_app/screens/clinic/inventory/inventory_screen.dart';
import 'package:clinic_management_app/screens/clinic/patients_module/patients_screen.dart';
import 'package:clinic_management_app/screens/clinic/settings_module/settings_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter/material.dart';

class ClinicRootScreen extends StatefulWidget {
  final int initialIndex;

  const ClinicRootScreen({super.key, this.initialIndex = 0});

  @override
  State<ClinicRootScreen> createState() => _ClinicRootScreenState();
}

class _ClinicRootScreenState extends State<ClinicRootScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    ClinicDashboardScreen(),
    RecentAppointmentsScreen(),
    InventoryListScreen(),
    PatientsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: 64 + 16 + bottomInset),
                child: _pages[_currentIndex],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ClinicFloatingGlassBottomNav(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                items: const [
                  ClinicNavItem(icon: Icons.dashboard, label: "Home"),
                  ClinicNavItem(
                    icon: Icons.calendar_today,
                    label: "Appointments",
                  ),
                  ClinicNavItem(
                    icon: Icons.inventory_2_outlined,
                    label: "Inventory",
                  ),
                  ClinicNavItem(icon: Icons.receipt_long, label: "Invoices"),
                  ClinicNavItem(icon: Icons.more_horiz, label: "More"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }
}

class ClinicNavItem {
  final IconData icon;
  final String label;

  const ClinicNavItem({required this.icon, required this.label});
}

class ClinicFloatingGlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ClinicNavItem> items;

  // style knobs
  final double borderRadius;
  final double blurSigma;
  final EdgeInsets margin;
  final double minHeight;

  const ClinicFloatingGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.borderRadius = 22,
    this.blurSigma = 18,
    this.minHeight = 64,
    this.margin = const EdgeInsets.fromLTRB(8, 0, 8, 0),
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        margin.left,
        margin.top,
        margin.right,
        margin.bottom + (bottomInset > 0 ? 0 : 8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.white.withOpacity(0.82),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // If height is tight, we compact:
                final isTightHeight = constraints.maxHeight < 64;

                return Row(
                  children: List.generate(items.length, (i) {
                    final item = items[i];
                    final selected = i == currentIndex;
                    return Expanded(
                      child: _ClinicNavTile(
                        icon: item.icon,
                        label: item.label,
                        selected: selected,
                        compact: isTightHeight,
                        onTap: () => onTap(i),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _ClinicNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.primary;
    final unselectedColor = AppColors.grey;

    final textScale = MediaQuery.textScaleFactorOf(context);
    final hideLabel = compact || textScale >= 1.25;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: hideLabel ? 10 : 8,
          horizontal: 6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? selectedColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? selectedColor : unselectedColor,
              ),
            ),
            // if (!hideLabel) ...[
            //   const SizedBox(height: 6),
            //   FittedBox(
            //     // prevents text overflow horizontally/vertically
            //     fit: BoxFit.scaleDown,
            //     child: Text(
            //       label,
            //       maxLines: 1,
            //       style: AppFonts.regular(
            //         color: selected ? selectedColor : unselectedColor,
            //         fontSize: 12,
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
