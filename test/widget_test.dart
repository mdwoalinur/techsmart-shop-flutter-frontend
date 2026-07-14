import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_smart_shop/app.dart';
import 'support/fake_catalog_repository.dart';
import 'support/fake_offer_repository.dart';

void main() {
  testWidgets('root app renders branded Home by default', (tester) async {
    await tester.pumpWidget(
      TechSmartShopApp(
        catalogRepository: FakeCatalogRepository(),
        offerRepository: const FakeOfferRepository(),
      ),
    );
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'TechSmart Shop');
    expect(materialApp.theme?.useMaterial3, isTrue);
    expect(find.byKey(const Key('techSmartShopLogo')), findsOneWidget);
    expect(find.byKey(const Key('homeNavigationButton')), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('navigation changes destinations', (tester) async {
    await tester.pumpWidget(
      TechSmartShopApp(
        catalogRepository: FakeCatalogRepository(),
        offerRepository: const FakeOfferRepository(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('categoriesNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsWidgets);

    await tester.tap(find.byKey(const Key('offersNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Online Tech Deals'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cartNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Current Session Cart'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menuNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Current-session shopping tools'), findsOneWidget);
  });

  testWidgets('center Home button returns directly to Home', (tester) async {
    await tester.pumpWidget(
      TechSmartShopApp(
        catalogRepository: FakeCatalogRepository(),
        offerRepository: const FakeOfferRepository(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('menuNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Current-session shopping tools'), findsOneWidget);

    await tester.tap(find.byKey(const Key('homeNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('techSmartShopLogo')), findsOneWidget);
    expect(find.text('Current-session shopping tools'), findsNothing);
  });

  testWidgets('cart navigation is badge-ready without a fake count', (
    tester,
  ) async {
    await tester.pumpWidget(
      TechSmartShopApp(
        catalogRepository: FakeCatalogRepository(),
        offerRepository: const FakeOfferRepository(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('cartBadgeAnchor')), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
