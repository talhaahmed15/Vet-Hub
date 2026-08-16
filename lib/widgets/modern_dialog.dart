import 'package:clinic_management_app/themes/app_colors.dart';
import 'package:clinic_management_app/themes/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A modern, opinionated dialog shell with a hero icon header,
/// subtitle, scrollable body and a sticky footer.
class ModernDialog extends StatelessWidget {
  const ModernDialog({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.body,
    this.footer,
    this.width = 440,
    this.showClose = true,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;
  final double width;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                icon: icon,
                accent: accent,
                title: title,
                subtitle: subtitle,
                showClose: showClose,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                  child: body,
                ),
              ),
              if (footer != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                  decoration: const BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: AppColors.borderFaint),
                    ),
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.showClose,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 14, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.18),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.extraBold(
                      fontSize: 17,
                      color: AppColors.slate900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppFonts.regular(
                        fontSize: 12.5,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showClose)
            _CloseButton(onTap: () => Navigator.of(context).maybePop()),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderFaint),
          ),
          child: const Icon(
            LucideIcons.x,
            size: 16,
            color: AppColors.slate500,
          ),
        ),
      ),
    );
  }
}

/// A labelled form field section used inside [ModernDialog] bodies.
class ModernField extends StatelessWidget {
  const ModernField({
    super.key,
    required this.label,
    required this.child,
    this.icon,
    this.helper,
  });

  final String label;
  final Widget child;
  final IconData? icon;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: AppColors.slate500),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppFonts.semiBold(
                  fontSize: 11.5,
                  color: AppColors.slate700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: AppFonts.regular(
                fontSize: 11.5,
                color: AppColors.slate500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
