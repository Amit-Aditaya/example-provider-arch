import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../screens/logged_in/home_tabs/main_screen.dart';
import '../screens/logged_in/home_tabs/second_screen.dart';

enum AppScreen {
  MAIN,
  SECOND,
}

class HomeProvider with ChangeNotifier {
  final _screens = [
    const MainScreen(),
    const SecondScreen(),
  ];

  int _currentIndex = 0;

  Future<void> switchToIndex(int index) async {
    _currentIndex = index;
    // AnalyticsProvider.setCurrentScreen(AppScreen.values.elementAt(index).name);
    notifyListeners();
  }

  Future<void> switchToScreen(AppScreen screen) async {
    _currentIndex = AppScreen.values.indexOf(screen);
    // AnalyticsProvider.setCurrentScreen(screen.name);
    notifyListeners();
  }

  void reset() {
    _currentIndex = AppScreen.MAIN.index;
    notifyListeners();
  }

  int get currentIndex => _currentIndex;

  Widget get selectedScreen => _screens.elementAt(_currentIndex);
}
