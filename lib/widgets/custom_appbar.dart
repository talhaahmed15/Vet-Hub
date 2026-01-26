import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, this.title = 'Title'});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        title,
        style: AppFonts.semiBold(
          fontSize: 16,
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
    );
  }
}
