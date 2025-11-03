import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode){
    if (mode != _themeMode){
      _themeMode = mode;
      notifyListeners();
    }
  }
}