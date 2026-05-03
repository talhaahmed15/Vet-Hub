import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? trailing;

  const CustomAppBar({
    super.key,
    this.title = 'Title',
    this.onBackPressed,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      // forceMaterialTransparency: true,
      backgroundColor: AppColors.white,
      centerTitle: true,
      leading: onBackPressed != null
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.white : AppColors.black,
              ),
              onPressed: onBackPressed,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : null,
      title: Text(
        title,
        style: AppFonts.semiBold(
          fontSize: 16,
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
      actions: trailing != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: trailing!,
              ),
            ]
          : null,
    );
  }
}
