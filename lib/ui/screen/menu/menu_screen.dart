import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/cart_provider.dart';
import '../../../provider/compare_provider.dart';
import '../../../provider/wishlist_provider.dart';
import '../../../provider/notification_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../compare/compare_screen.dart';
import '../profile/change_password_screen.dart';
import '../order/my_orders_screen.dart';
import '../notification/notification_center_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../../widget/customer/customer_avatar.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>(),
        wish = context.watch<WishlistProvider>().count,
        compare = context.watch<CompareProvider>().count,
        cart = context.watch<CartProvider>().totalQuantity,
        unread = context.watch<NotificationProvider>().unreadCount;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          Text('Menu', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          if (auth.authenticated)
            _authenticated(context, auth, unread)
          else
            _guest(context),
          const SizedBox(height: 20),
          const Text('Current-session shopping tools'),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const Key('wishlistMenu'),
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Wishlist'),
                  subtitle: const Text('Saved only for this app session'),
                  trailing: Text('$wish'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('compareMenu'),
                  leading: const Icon(Icons.compare_arrows),
                  title: const Text('Compare Products'),
                  subtitle: const Text('Compare up to 4 products'),
                  trailing: Text('$compare'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CompareScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: const Text('Current Session Cart'),
                  subtitle: Text(
                    '$cart total item${cart == 1 ? '' : 's'} â€” not synchronized',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guest(BuildContext context) => Card(
    key: const Key('guestMenu'),
    child: Column(
      children: [
        const ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('Browsing as Guest'),
          subtitle: Text('Login is not required to shop'),
        ),
        ListTile(
          key: const Key('loginMenu'),
          leading: const Icon(Icons.login),
          title: const Text('Login'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
        ListTile(
          key: const Key('registerMenu'),
          leading: const Icon(Icons.person_add_alt),
          title: const Text('Create Account'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.storefront),
          title: Text('Continue Browsing'),
        ),
      ],
    ),
  );
  Widget _authenticated(BuildContext context, AuthProvider auth, int unread) {
    final p = auth.profile!;
    return Card(
      key: const Key('authenticatedMenu'),
      child: Column(
        children: [
          ListTile(
            leading: CustomerAvatar(
              keyName: 'menuAvatar',
              fullName: p.fullName,
              photoUrl: p.photoUrl,
              radius: 20,
            ),
            title: Text(p.fullName),
            subtitle: Text(p.email),
          ),
          ListTile(
            key: const Key('myOrdersMenu'),
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('My Orders'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            ),
          ),
          ListTile(
            key: const Key('notificationsMenu'),
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notifications'),
            trailing: Text(unread > 99 ? '99+' : unread.toString()),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            ),
          ),
          ListTile(
            key: const Key('profileMenu'),
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Profile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          ListTile(
            key: const Key('logoutMenu'),
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Your current-session Cart, Wishlist, and Compare items will remain in this running app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
