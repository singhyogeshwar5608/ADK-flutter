import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }
}

class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({super.key, required ThemeController super.notifier, required super.child});

  static ThemeController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'No ThemeControllerProvider found in context');
    return provider!.notifier!;
  }

  static ThemeController? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    return provider?.notifier;
  }
}
