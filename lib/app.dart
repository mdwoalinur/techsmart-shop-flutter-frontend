import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/auth_provider.dart';
import 'provider/navigation_provider.dart';
import 'provider/order_provider.dart';
import 'provider/offer_provider.dart';
import 'provider/payment_provider.dart';
import 'provider/notification_provider.dart';
import 'provider/review_provider.dart';
import 'provider/support_provider.dart';
import 'provider/help_provider.dart';
import 'provider/category_provider.dart';
import 'provider/checkout_provider.dart';
import 'provider/cart_provider.dart';
import 'provider/compare_provider.dart';
import 'provider/product_provider.dart';
import 'provider/search_provider.dart';
import 'provider/wishlist_provider.dart';
import 'service/api/api_client.dart';
import 'service/auth/auth_service.dart';
import 'service/catalog/catalog_service.dart';
import 'service/checkout/checkout_service.dart';
import 'service/order/order_service.dart';
import 'service/offer/offer_service.dart';
import 'service/payment/payment_service.dart';
import 'service/notification/notification_service.dart';
import 'service/review/review_service.dart';
import 'service/support/support_service.dart';
import 'service/help/help_service.dart';
import 'service/storage/secure_session_storage.dart';
import 'service/shopping/customer_shopping_service.dart';
import 'ui/navigation/main_navigation_shell.dart';
import 'ui/theme/app_theme.dart';

class TechSmartShopApp extends StatelessWidget {
  const TechSmartShopApp({
    super.key,
    this.catalogRepository,
    this.offerRepository,
    this.authRepository,
    this.sessionStorage,
  });
  final CatalogRepository? catalogRepository;
  final OfferRepository? offerRepository;
  final AuthRepository? authRepository;
  final SessionStorage? sessionStorage;
  static const String appTitle = 'TechSmart Shop';
  @override
  Widget build(BuildContext context) {
    final client = ApiClient();
    final catalog = catalogRepository ?? CatalogService(client);
    final offerRepo = offerRepository ?? OfferService(client);
    final storage = sessionStorage ?? SecureSessionStorage();
    final auth = authRepository ?? AuthService(client, storage);
    final authProvider = AuthProvider(auth, storage, autoInitialize: false);
    if (auth is AuthService) {
      auth.sessionInvalidHandler = authProvider.expireSession;
    }
    if (catalogRepository == null) unawaited(authProvider.initialize());
    final shopping = CustomerShoppingService(client);
    final checkout = CheckoutService(client);
    final orders = OrderService(client);
    final payments = PaymentService(client);
    final notifications = NotificationService(client);
    final reviews = ReviewService(client);
    final support = SupportService(client);
    final help = HelpService(client);
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        Provider<CatalogRepository>.value(value: catalog),
        Provider<OfferRepository>.value(value: offerRepo),
        Provider<SessionStorage>.value(value: storage),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => CartProvider(repository: shopping, auth: authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              WishlistProvider(repository: shopping, auth: authProvider),
        ),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(
          create: (_) => CheckoutProvider(checkout, authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(orders, authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(payments, authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notifications, authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(reviews, authProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => SupportProvider(support, authProvider),
        ),
        ChangeNotifierProvider(create: (_) => HelpProvider(help)),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(catalog)..load(rootOnly: true),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ProductProvider(catalog, initialSort: CatalogSort.newest)
                ..loadInitial(),
        ),
        ChangeNotifierProvider(create: (_) => SearchProvider(catalog)),
        ChangeNotifierProvider(create: (_) => OfferProvider(offerRepo)),
      ],
      child: MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainNavigationShell(),
      ),
    );
  }
}
