import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/navigation_provider.dart';
import '../../provider/cart_provider.dart';
import '../screen/cart/cart_screen.dart';
import '../screen/categories/categories_screen.dart';
import '../screen/home/home_screen.dart';
import '../screen/menu/menu_screen.dart';
import '../screen/offers/offers_screen.dart';
import '../theme/app_colors.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key});

  static const List<Widget> _screens = [
    CategoriesScreen(),
    OffersScreen(),
    HomeScreen(),
    CartScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: navigation.selectedIndex, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        button: true,
        selected: navigation.selectedDestination == AppDestination.home,
        label: 'Home',
        child: SizedBox(
          width: 66,
          height: 66,
          child: FloatingActionButton(
            key: const Key('homeNavigationButton'),
            tooltip: 'Home',
            onPressed: () =>
                context.read<NavigationProvider>().select(AppDestination.home),
            child: const Icon(Icons.home_rounded, size: 30),
          ),
        ),
      ),
      bottomNavigationBar: const _TechSmartBottomBar(),
    );
  }
}

class _TechSmartBottomBar extends StatelessWidget {
  const _TechSmartBottomBar();

  @override
  Widget build(BuildContext context) {
    final selected = context.select<NavigationProvider, AppDestination>(
      (provider) => provider.selectedDestination,
    );

    return SafeArea(
      top: false,
      child: BottomAppBar(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 14,
        shadowColor: const Color(0x33081B33),
        shape: const CircularNotchedRectangle(),
        notchMargin: 9,
        child: Row(
          children: [
            _NavigationItem(
              key: const Key('categoriesNavigationButton'),
              destination: AppDestination.categories,
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              label: 'Categories',
              selected: selected == AppDestination.categories,
            ),
            _NavigationItem(
              key: const Key('offersNavigationButton'),
              destination: AppDestination.offers,
              icon: Icons.local_offer_outlined,
              selectedIcon: Icons.local_offer_rounded,
              label: 'Offers',
              selected: selected == AppDestination.offers,
            ),
            const SizedBox(width: 76),
            _NavigationItem(
              key: const Key('cartNavigationButton'),
              destination: AppDestination.cart,
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag_rounded,
              label: 'Cart',
              selected: selected == AppDestination.cart,
              badgeReady: true,
            ),
            _NavigationItem(
              key: const Key('menuNavigationButton'),
              destination: AppDestination.menu,
              icon: Icons.menu_rounded,
              selectedIcon: Icons.menu_open_rounded,
              label: 'Menu',
              selected: selected == AppDestination.menu,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    this.badgeReady = false,
    super.key,
  });

  final AppDestination destination;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool badgeReady;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.electricBlue : AppColors.textSecondary;
    final badgeCount = badgeReady
        ? context.watch<CartProvider>().totalQuantity
        : 0;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkResponse(
          onTap: () => context.read<NavigationProvider>().select(destination),
          radius: 30,
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  key: badgeReady ? const Key('cartBadgeAnchor') : null,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      color: color,
                      size: 25,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -12,
                        top: -9,
                        child: Container(
                          key: const Key('cartBadge'),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
