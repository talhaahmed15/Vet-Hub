import 'package:clinic_management_app/screens/clinic/billing_module/billing_screen.dart';
import 'package:clinic_management_app/screens/clinic/dashboard/clinic_dashboard.dart';
import 'package:clinic_management_app/screens/clinic/patients_module/patients_screen.dart';
import 'package:clinic_management_app/screens/clinic/schedule_module/schedule_screen.dart';
import 'package:clinic_management_app/screens/clinic/settings_module/settings_screen.dart';
import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class ClinicRootScreen extends StatefulWidget {
  const ClinicRootScreen({super.key});

  @override
  State<ClinicRootScreen> createState() => _ClinicRootScreenState();
}

class _ClinicRootScreenState extends State<ClinicRootScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ClinicDashboardScreen(),
    ScheduleScreen(),
    PatientsScreen(),
    BillingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      backgroundColor: AppColors.white,
      iconSize: 20,
      selectedLabelStyle: AppFonts.regular(
        color: AppColors.primary,
        fontSize: 12,
      ),
      unselectedLabelStyle: AppFonts.regular(
        color: AppColors.grey,
        fontSize: 12,
      ),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: "Schedule",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: "Patients"),
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label: "Billing"),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"),
      ],
    );
  }
}
