import 'package:flutter_test/flutter_test.dart';
import 'package:tech_smart_shop/provider/navigation_provider.dart';

void main() {
  test('Home is initially selected and reselection is observable', () {
    final provider = NavigationProvider();
    var notifications = 0;
    provider.addListener(() => notifications++);

    expect(provider.selectedDestination, AppDestination.home);
    expect(provider.selectedIndex, AppDestination.home.index);

    provider.select(AppDestination.home);

    expect(provider.homeReselectionCount, 1);
    expect(notifications, 1);
  });

  test('select changes the active destination', () {
    final provider = NavigationProvider();
    provider.select(AppDestination.cart);
    expect(provider.selectedDestination, AppDestination.cart);
  });
}
