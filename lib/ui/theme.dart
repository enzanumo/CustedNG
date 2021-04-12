import 'package:custed2/ui/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Theme;

// should be material.Theme.of(context).backgroundColor
// scheduleButtonColor: Color(0xFFF0EFF3),

final _appTheme = AppTheme();

bool isDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

class DarkMode {
  static const auto = 0;
  static const on = 1;
  static const off = 2;
}

class AppTheme {
  static AppThemeResolved bright = resolve(Brightness.light);

  static AppThemeResolved dark = resolve(Brightness.dark);

  // 根据当前context的亮度，返回应用主题数据
  static AppThemeResolved of(BuildContext context) {
    return isDark(context) ? dark : bright;
  }

  // 根据当前context的亮度，返回应用主题数据
  static AppThemeResolved resolve(Brightness brightness) {
    return AppThemeResolved()
      ..backgroundColor = s(brightness, _appTheme.backgroundColor)
      ..scheduleOutlineColor = s(brightness, _appTheme.scheduleOutlineColor)
      ..scheduleTextColor = s(brightness, _appTheme.scheduleTextColor)
      ..cardBackgroundColor = s(brightness, _appTheme.cardBackgroundColor)
      ..cardTextColor = s(brightness, _appTheme.cardTextColor)
      ..textFieldBackgroundColor =
          s(brightness, _appTheme.textFieldBackgroundColor)
      ..textFieldBorderColor = s(brightness, _appTheme.textFieldBorderColor)
      ..textFieldListBackgroundColor =
          s(brightness, _appTheme.textFieldListBackgroundColor);
  }

  static Color s(Brightness brightness, DynamicColor color) {
    return brightness == Brightness.dark ? color.dark : color.light;
  }

  final backgroundColor = DynamicColor(
    Colors.white,
    Color.fromRGBO(23, 23, 23, 1),
  );

  final lightTextColor = DynamicColor(
    Color(0xFF8A8A8A),
    Color(0xFF8A8A8A),
  );

  final scheduleOutlineColor = DynamicColor(
    Color(0xFFE7ECEb),
    Colors.grey[850],
  );

  final scheduleButtonColor = DynamicColor(
    Color(0xFFF0EFF3),
    Color(0xFF2F2F2F),
  );

  final scheduleButtonTextColor = DynamicColor(
    Color(0xFF83868E),
    Color(0xFF83868E),
  );

  final scheduleTextColor = DynamicColor(
    Color(0xFF898C91),
    Color(0xFF898C91),
  );

  final cardBackgroundColor = DynamicColor(
    Colors.white,
    Colors.grey[850],
  );

  final cardTextColor = DynamicColor(
    Colors.black,
    Colors.white70,
  );

  final textFieldBackgroundColor = DynamicColor(
    CupertinoColors.white,
    Colors.transparent,
  );

  final textFieldBorderColor = DynamicColor(
    CupertinoColors.lightBackgroundGray,
    Colors.grey[850],
  );

  final textFieldListBackgroundColor = DynamicColor(
    CupertinoColors.lightBackgroundGray,
    CupertinoColors.darkBackgroundGray,
  );
}

class AppThemeResolved {
  Color backgroundColor;
  Color scheduleOutlineColor;
  Color scheduleTextColor;
  Color cardBackgroundColor;
  Color cardTextColor;
  Color textFieldBackgroundColor;
  Color textFieldBorderColor;
  Color textFieldListBackgroundColor;
}
