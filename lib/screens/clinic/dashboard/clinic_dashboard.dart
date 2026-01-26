import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:clinic_management_app/widgets/spacing.dart';
import 'package:flutter/material.dart';

class ClinicDashboardScreen extends StatelessWidget {
  const ClinicDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              24.height,
              _StatsRow(),
              16.height,
              _RevenueCard(),
              16.height,
              _AppointmentTrends(),
              24.height,
              _QuickActions(),
              24.height,
              _NextAppointments(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.pets, color: AppColors.white),
        ),
        12.width,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("City Vet Clinic", style: AppFonts.semiBold(fontSize: 16)),
            2.height,
            Text(
              "Monday, Oct 23",
              style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
        const Spacer(),
        _IconButton(Icons.search),
        8.width,
        _IconButton(Icons.notifications_none),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Icon(icon, size: 20),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: "TODAY'S APPTS",
            value: "14",
            change: "+12%",
            icon: Icons.calendar_today_outlined,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: "TOTAL PATIENTS",
            value: "1,240",
            change: "+5%",
            icon: Icons.group_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              8.width,
              Text(title, style: AppFonts.regular(fontSize: 11)),
            ],
          ),
          12.height,
          Row(
            children: [
              Text(value, style: AppFonts.bold(fontSize: 22)),
              8.width,
              Text(
                change,
                style: AppFonts.semiBold(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: AppColors.primary),
              8.width,
              Text("DAILY REVENUE", style: AppFonts.regular(fontSize: 11)),
              const Spacer(),
              Text(
                "+8% vs yesterday",
                style: AppFonts.semiBold(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          16.height,
          Text("\$1,240.00", style: AppFonts.bold(fontSize: 28)),
        ],
      ),
    );
  }
}

class _AppointmentTrends extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Appointment Trends",
                style: AppFonts.semiBold(fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Weekly",
                  style: AppFonts.semiBold(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          16.height,
          Text("98 Total", style: AppFonts.bold(fontSize: 22)),
          4.height,
          Text(
            "Last 7 Days +15%",
            style: AppFonts.regular(fontSize: 12, color: AppColors.primary),
          ),
          24.height,
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _LineGraphPainter(),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.3,
        size.width * 0.3,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.8,
        size.width * 0.6,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.2,
        size.width,
        size.height * 0.5,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Actions", style: AppFonts.semiBold(fontSize: 18)),
        16.height,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _ActionItem(icon: Icons.add, label: "New Patient", primary: true),
            _ActionItem(icon: Icons.calendar_today, label: "Add Appt"),
            _ActionItem(icon: Icons.science_outlined, label: "New Lab"),
            _ActionItem(icon: Icons.qr_code_scanner, label: "Scan"),
          ],
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary ? AppColors.primary : AppColors.white,
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, color: primary ? AppColors.white : AppColors.black),
        ),
        8.height,
        Text(label, style: AppFonts.regular(fontSize: 12)),
      ],
    );
  }
}

class _NextAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Next Appointments", style: AppFonts.semiBold(fontSize: 18)),
            const Spacer(),
            Text(
              "View All",
              style: AppFonts.semiBold(fontSize: 12, color: AppColors.primary),
            ),
          ],
        ),
        16.height,
        const _AppointmentTile(
          time: "10:30 AM",
          title: "Luna (Golden Retriever)",
          subtitle: "Vaccination • Dr. Sarah",
        ),
        const _AppointmentTile(
          time: "11:15 AM",
          title: "Oliver (Siamese Cat)",
          subtitle: "Check-up • Dr. Sarah",
        ),
        const _AppointmentTile(
          time: "01:45 PM",
          title: "Max (Beagle)",
          subtitle: "Dental • Dr. James",
          disabled: true,
        ),
      ],
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final bool disabled;

  const _AppointmentTile({
    required this.time,
    required this.title,
    required this.subtitle,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: disabled ? AppColors.divider.withOpacity(0.3) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: AppFonts.semiBold(fontSize: 12, color: AppColors.primary),
            ),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.semiBold(fontSize: 14)),
                4.height,
                Text(
                  subtitle,
                  style: AppFonts.regular(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
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
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
      ],
    );
  }
}
