import 'package:flutter/foundation.dart';

enum AppDestination { categories, offers, home, cart, menu }

class NavigationProvider extends ChangeNotifier {
  AppDestination _selectedDestination = AppDestination.home;
  int _homeReselectionCount = 0;

  AppDestination get selectedDestination => _selectedDestination;
  int get selectedIndex => _selectedDestination.index;

  /// A future Home screen can listen for changes and scroll to its top.
  int get homeReselectionCount => _homeReselectionCount;

  void select(AppDestination destination) {
    if (destination == _selectedDestination) {
      if (destination == AppDestination.home) {
        _homeReselectionCount++;
        notifyListeners();
      }
      return;
    }

    _selectedDestination = destination;
    notifyListeners();
  }
}
