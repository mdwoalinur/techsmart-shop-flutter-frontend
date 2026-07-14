import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tech_smart_shop/app.dart';
import 'package:tech_smart_shop/provider/auth_provider.dart';
import 'package:tech_smart_shop/ui/screen/auth/registration_otp_screen.dart';
import 'support/fake_auth.dart';
import 'support/fake_catalog_repository.dart';
import 'support/fake_offer_repository.dart';

Future<void> pump(
  WidgetTester t,
  FakeAuthRepository repo,
  MemorySessionStorage store,
) async {
  await t.pumpWidget(
    TechSmartShopApp(
      catalogRepository: FakeCatalogRepository(),
      offerRepository: const FakeOfferRepository(),
      authRepository: repo,
      sessionStorage: store,
    ),
  );
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('menuNavigationButton')));
  await t.pump();
}

void main() {
  testWidgets('guest Menu offers auth and preserves shopping tools', (t) async {
    await pump(t, FakeAuthRepository(), MemorySessionStorage());
    expect(find.byKey(const Key('guestMenu')), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
  });
  testWidgets('Login validates email and toggles password visibility', (
    t,
  ) async {
    await pump(t, FakeAuthRepository(), MemorySessionStorage());
    await t.tap(find.byKey(const Key('loginMenu')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('loginSubmit')));
    await t.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await t.enterText(find.byKey(const Key('loginPassword')), 'secret');
    final before = t
        .widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('loginPassword')),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;
    await t.tap(find.byKey(const Key('loginPasswordVisibility')));
    await t.pump();
    expect(
      t
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('loginPassword')),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isNot(before),
    );
    expect(find.text('Continue Browsing as Guest'), findsOneWidget);
  });
  testWidgets('Registration shows policy and requires Terms', (t) async {
    await pump(t, FakeAuthRepository(), MemorySessionStorage());
    await t.tap(find.byKey(const Key('registerMenu')));
    await t.pumpAndSettle();
    expect(find.textContaining('Password policy:'), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('registerSubmit')));
    await t.tap(find.byKey(const Key('registerSubmit')));
    await t.pump();
    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.byKey(const Key('termsCheckbox')), findsOneWidget);
  });
  testWidgets('OTP requires exactly six digits', (t) async {
    final repo = FakeAuthRepository(),
        store = MemorySessionStorage(),
        provider = AuthProvider(repo, store, autoInitialize: false);
    await provider.register(
      fullName: 'Test',
      email: 't@example.com',
      phone: '01712345678',
      password: 'Strong1!',
      confirmPassword: 'Strong1!',
      terms: true,
    );
    await t.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: RegistrationOtpScreen()),
      ),
    );
    await t.enterText(find.byKey(const Key('registrationOtp')), '123');
    await t.tap(find.text('Verify'));
    await t.pump();
    expect(find.text('Enter the six-digit code.'), findsOneWidget);
    expect(find.textContaining('server controls'), findsOneWidget);
  });
  testWidgets('authenticated Menu and Profile expose only safe fields', (
    t,
  ) async {
    final repo = FakeAuthRepository(), store = MemorySessionStorage();
    await pump(t, repo, store);
    final context = t.element(find.byType(MaterialApp));
    await context.read<AuthProvider>().login('test@example.com', 'Strong1!');
    await t.pump();
    expect(find.byKey(const Key('authenticatedMenu')), findsOneWidget);
    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.textContaining('Admin'), findsNothing);
    await t.tap(find.byKey(const Key('profileMenu')));
    await t.pumpAndSettle();
    expect(find.text('Customer code'), findsOneWidget);
    expect(find.text('Balance'), findsNothing);
    expect(find.text('Credit limit'), findsNothing);
    expect(find.textContaining('password'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });
  testWidgets(
    'authenticated avatar appears in Menu and Profile after profile state has photo',
    (t) async {
      final repo = FakeAuthRepository()
        ..current = testProfile.copyWith(
          photoUrl: '/uploads/customers/profile/7/avatar.jpg',
        );
      final store = MemorySessionStorage();
      await pump(t, repo, store);
      final context = t.element(find.byType(MaterialApp));
      await context.read<AuthProvider>().login('test@example.com', 'Strong1!');
      await t.pump();
      expect(find.byKey(const Key('menuAvatar')), findsOneWidget);
      await t.tap(find.byKey(const Key('profileMenu')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('profileAvatar')), findsOneWidget);
      expect(find.byKey(const Key('profilePhotoButton')), findsOneWidget);
    },
  );
  testWidgets('logout keeps Phase 4 providers alive', (t) async {
    final repo = FakeAuthRepository(), store = MemorySessionStorage();
    await pump(t, repo, store);
    final context = t.element(find.byType(MaterialApp));
    await context.read<AuthProvider>().login('test@example.com', 'Strong1!');
    await t.pump();
    await t.tap(find.byKey(const Key('logoutMenu')));
    await t.pumpAndSettle();
    expect(find.textContaining('Cart, Wishlist, and Compare'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Logout'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('guestMenu')), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
  });
}
