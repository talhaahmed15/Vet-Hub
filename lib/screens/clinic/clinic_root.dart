import 'dart:ui';

import 'package:clinic_management_app/screens/clinic/appointment/recent_appointments_screen.dart';
import 'package:clinic_management_app/screens/clinic/dashboard/clinic_dashboard.dart';
import 'package:clinic_management_app/screens/clinic/inventory/inventory_screen.dart';
import 'package:clinic_management_app/screens/clinic/patients_module/patients_screen.dart';
import 'package:clinic_management_app/screens/clinic/settings_module/settings_screen.dart';
import 'package:clinic_management_app/screens/clinic/tasks/tasks_screen.dart';
import 'package:clinic_management_app/bloc/tasks/tasks_cubit.dart';
import 'package:clinic_management_app/services/task_service.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/utils/responsive.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Data model for a nav destination
// ─────────────────────────────────────────────────────────────

class ClinicNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const ClinicNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────
// Root screen — picks the right shell based on screen size
// ─────────────────────────────────────────────────────────────

class ClinicRootScreen extends StatefulWidget {
  final int initialIndex;

  const ClinicRootScreen({super.key, this.initialIndex = 0});

  @override
  State<ClinicRootScreen> createState() => _ClinicRootScreenState();
}

class _ClinicRootScreenState extends State<ClinicRootScreen> {
  late int _currentIndex;

  static const List<ClinicNavItem> _navItems = [
    ClinicNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Home',
    ),
    ClinicNavItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      label: 'Appointments',
    ),
    ClinicNavItem(
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
      label: 'Tasks',
    ),
    ClinicNavItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Inventory',
    ),
    ClinicNavItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Invoices',
    ),
    ClinicNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  final List<Widget> _pages = [
    const ClinicDashboardScreen(),
    const RecentAppointmentsScreen(),
    BlocProvider(
      create: (ctx) => TasksCubit(service: ctx.read<TaskService>()),
      child: const TasksScreen(),
    ),
    const InventoryListScreen(),
    const PatientsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  void _onTap(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _currentIndex = 0);
      },
      child: ResponsiveBuilder(
        builder: (context, size) {
          switch (size) {
            case ScreenSize.compact:
              return _MobileShell(
                currentIndex: _currentIndex,
                onTap: _onTap,
                items: _navItems,
                child: _pages[_currentIndex],
              );
            case ScreenSize.medium:
              return _TabletShell(
                currentIndex: _currentIndex,
                onTap: _onTap,
                items: _navItems,
                child: _pages[_currentIndex],
              );
            case ScreenSize.expanded:
              return _DesktopShell(
                currentIndex: _currentIndex,
                onTap: _onTap,
                items: _navItems,
                child: _pages[_currentIndex],
              );
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MOBILE SHELL  (< 600 px) — floating glass bottom nav
// ─────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ClinicNavItem> items;
  final Widget child;

  const _MobileShell({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: 64 + 16 + bottomInset),
              child: child,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClinicFloatingGlassBottomNav(
              currentIndex: currentIndex,
              onTap: onTap,
              items: items,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TABLET SHELL  (600–1199 px) — left navigation rail
// ─────────────────────────────────────────────────────────────

class _TabletShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ClinicNavItem> items;
  final Widget child;

  const _TabletShell({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: Colors.white,
            minWidth: Responsive.railWidth,
            labelType: NavigationRailLabelType.selected,
            selectedIconTheme: const IconThemeData(
              color: AppColors.primary,
              size: 22,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.grey,
              size: 22,
            ),
            selectedLabelTextStyle: AppFonts.medium(
              fontSize: 12,
              color: AppColors.primary,
            ),
            unselectedLabelTextStyle: AppFonts.regular(
              fontSize: 12,
              color: AppColors.grey,
            ),
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            destinations: items
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.divider,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DESKTOP SHELL  (≥ 1200 px) — persistent dark sidebar
// ─────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ClinicNavItem> items;
  final Widget child;

  const _DesktopShell({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          _DesktopSidebar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: items,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ClinicNavItem> items;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final mainItems = items.sublist(0, items.length - 1);
    final lastItem = items.last;
    final lastIndex = items.length - 1;

    return Container(
      width: Responsive.sidebarWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1C2E), Color(0xFF0A1628)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(6, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Branding ──
          const _SidebarHeader(),

          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.07),
          ),

          const SizedBox(height: 20),

          // ── Section label ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'MAIN MENU',
              style: AppFonts.medium(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── Main nav items ──
          ...List.generate(mainItems.length, (i) {
            return _SidebarNavItem(
              icon: mainItems[i].icon,
              selectedIcon: mainItems[i].selectedIcon,
              label: mainItems[i].label,
              selected: i == currentIndex,
              onTap: () => onTap(i),
            );
          }),

          const Spacer(),

          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.07),
          ),

          const SizedBox(height: 6),

          // ── Settings pinned to bottom ──
          _SidebarNavItem(
            icon: lastItem.icon,
            selectedIcon: lastItem.selectedIcon,
            label: lastItem.label,
            selected: lastIndex == currentIndex,
            onTap: () => onTap(lastIndex),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VetHub',
                style: AppFonts.bold(fontSize: 16, color: Colors.white),
              ),
              Text(
                'Clinic Portal',
                style: AppFonts.regular(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.selected;

    final iconColor = isActive
        ? AppColors.primary
        : _hovered
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.4);

    final textColor = isActive
        ? Colors.white
        : _hovered
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.45);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.28)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Left accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  isActive ? widget.selectedIcon : widget.icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: isActive
                        ? AppFonts.semiBold(fontSize: 13, color: textColor)
                        : AppFonts.regular(fontSize: 13, color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FLOATING GLASS BOTTOM NAV  (mobile only)
// ─────────────────────────────────────────────────────────────

class ClinicFloatingGlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ClinicNavItem> items;

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
              color: Colors.white.withValues(alpha: 0.82),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTightHeight = constraints.maxHeight < 64;

                return Row(
                  children: List.generate(items.length, (i) {
                    return Expanded(
                      child: _ClinicNavTile(
                        icon: items[i].icon,
                        selectedIcon: items[i].selectedIcon,
                        label: items[i].label,
                        selected: i == currentIndex,
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
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _ClinicNavTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.grey;
    final textScaler = MediaQuery.textScalerOf(context);
    final hideLabel = compact || textScaler.scale(1) >= 1.25;

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
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: 20,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
