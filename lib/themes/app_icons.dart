import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcons {
  AppIcons._();

  static const String _base = 'assets/icons';

  static const String adhesivePlaster = '$_base/adhesive-plaster.svg';
  static const String clipboardAdd = '$_base/clipboard-add.svg';
  static const String dangerTriangle = '$_base/danger-triangle.svg';
  static const String jarOfPills = '$_base/jar-of-pills-2.svg';
  static const String penNewSquare = '$_base/pen-new-square.svg';
  static const String shop = '$_base/shop.svg';
  static const String squareArrowLeft = '$_base/square-arrow-left.svg';
  static const String squareArrowRight = '$_base/square-arrow-right.svg';
  static const String stethoscope = '$_base/stethoscope.svg';
  static const String tuning = '$_base/tuning-2.svg';
  static const String walletMoney = '$_base/wallet-money.svg';

  static Widget show(
    String asset, {
    double size = 20,
    Color? color,
  }) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
