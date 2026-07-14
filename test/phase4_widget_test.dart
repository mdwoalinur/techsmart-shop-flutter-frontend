import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tech_smart_shop/app.dart';
import 'package:tech_smart_shop/provider/cart_provider.dart';
import 'package:tech_smart_shop/provider/compare_provider.dart';
import 'package:tech_smart_shop/provider/wishlist_provider.dart';
import 'support/fake_catalog_repository.dart';
import 'support/fake_offer_repository.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    TechSmartShopApp(
      catalogRepository: FakeCatalogRepository(),
      offerRepository: const FakeOfferRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openDetail(WidgetTester tester) async {
  await pumpApp(tester);
  final product = find
      .ancestor(
        of: find.byKey(const Key('wishlist-32')).first,
        matching: find.byType(InkWell),
      )
      .last;
  await tester.ensureVisible(product);
  await tester.tap(product);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('detail variation price and quantity update', (tester) async {
    await openDetail(tester);
    expect(find.text('\u09F35,750'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('incrementQuantity')),
      300,
    );
    expect(find.byKey(const Key('detailQuantity')), findsOneWidget);
    await tester.tap(find.byKey(const Key('incrementQuantity')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('decrementQuantity')))
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('Add to Cart confirms and View Cart works', (tester) async {
    await openDetail(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('addToCart')), 300);
    await tester.tap(find.byKey(const Key('addToCart')));
    await tester.pumpAndSettle();
    expect(
      find.text('Added to your current shopping session.'),
      findsOneWidget,
    );
    expect(find.text('Quantity added: 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('viewCart')));
    await tester.pumpAndSettle();
    expect(find.text('Current Session Cart'), findsOneWidget);
    expect(find.text('Anker USB-C Hub'), findsOneWidget);
  });
  testWidgets('dynamic Cart badge and quantity update', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(MaterialApp));
    context.read<CartProvider>().add(sampleProduct, quantity: 2);
    await tester.pump();
    expect(find.byKey(const Key('cartBadge')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cartNavigationButton')));
    await tester.pump();
    expect(find.text('Anker USB-C Hub'), findsOneWidget);
  });
  testWidgets(
    'product card Wishlist and Compare actions update session state',
    (tester) async {
      await pumpApp(tester);
      await tester.ensureVisible(find.byKey(const Key('wishlist-32')).first);
      await tester.tap(find.byKey(const Key('wishlist-32')).first);
      await tester.ensureVisible(find.byKey(const Key('compare-32')).first);
      await tester.tap(find.byKey(const Key('compare-32')).first);
      await tester.pump();
      final context = tester.element(find.byType(MaterialApp));
      expect(context.read<WishlistProvider>().contains(32), isTrue);
      expect(context.read<CompareProvider>().contains(32), isTrue);
    },
  );
  testWidgets('Menu opens Wishlist and Compare screens', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('menuNavigationButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('wishlistMenu')));
    await tester.pumpAndSettle();
    expect(find.text('Session Wishlist'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('compareMenu')));
    await tester.pumpAndSettle();
    expect(find.text('Compare Products'), findsOneWidget);
  });
  testWidgets('no unsupported customer fields are rendered', (tester) async {
    await openDetail(tester);
    expect(find.textContaining('buying'), findsNothing);
    expect(find.textContaining('rating'), findsNothing);
    expect(find.textContaining('discount'), findsNothing);
    expect(find.textContaining('warehouse'), findsNothing);
  });
}
