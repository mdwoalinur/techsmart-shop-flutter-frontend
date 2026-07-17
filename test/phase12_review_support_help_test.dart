import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tech_smart_shop/app.dart';
import 'package:tech_smart_shop/model/help/help_models.dart';
import 'package:tech_smart_shop/model/review/review_models.dart';
import 'package:tech_smart_shop/model/support/support_models.dart';
import 'package:tech_smart_shop/provider/auth_provider.dart';
import 'package:tech_smart_shop/provider/help_provider.dart';
import 'package:tech_smart_shop/provider/review_provider.dart';
import 'package:tech_smart_shop/provider/support_provider.dart';
import 'package:tech_smart_shop/ui/screen/profile/profile_screen.dart';
import 'package:tech_smart_shop/service/help/help_service.dart';
import 'package:tech_smart_shop/service/review/review_service.dart';
import 'package:tech_smart_shop/service/support/support_service.dart';

import 'support/fake_auth.dart';
import 'support/fake_catalog_repository.dart';
import 'support/fake_offer_repository.dart';

typedef ProfileScreenHarness = ProfileScreen;

void main() {
  test('Phase 12 models parse direct backend DTOs', () {
    final summary = ReviewSummary.fromJson({
      'productId': 42,
      'averageRating': 4.5,
      'reviewCount': 8,
    });
    expect(summary.averageRating.asDouble, 4.5);
    expect(summary.reviewCount, 8);

    final ticket = SupportTicketDetail.fromJson({
      'ticketNumber': 'SUP-1',
      'subject': 'Need help',
      'category': 'ORDER',
      'priority': 'NORMAL',
      'status': 'OPEN',
      'messages': [
        {'senderType': 'CUSTOMER', 'message': 'Hello'},
      ],
    });
    expect(ticket.messages.single.message, 'Hello');

    final faq = HelpFaq.fromJson({
      'faqCode': 'REVIEWS',
      'category': 'Reviews',
      'question': 'When can I review?',
      'answer': 'After delivery.',
      'displayOrder': 40,
    });
    expect(faq.category, 'Reviews');
  });

  test('review and support providers clear customer data on logout', () async {
    final auth = AuthProvider(
      FakeAuthRepository(),
      MemorySessionStorage(),
      autoInitialize: false,
    );
    await auth.login('test@example.com', 'Strong1!');
    final reviews = ReviewProvider(_FakeReviewRepository(), auth);
    final support = SupportProvider(_FakeSupportRepository(), auth);

    await reviews.loadMine(force: true);
    await support.load(force: true);
    expect(reviews.myReviews, isNotEmpty);
    expect(support.tickets, isNotEmpty);

    await auth.logout();
    expect(reviews.myReviews, isEmpty);
    expect(support.tickets, isEmpty);

    reviews.dispose();
    support.dispose();
    auth.dispose();
  });

  test('help provider supports FAQ search state', () async {
    final provider = HelpProvider(_FakeHelpRepository());
    await provider.load(search: 'review');
    expect(provider.query, 'review');
    expect(provider.faqs.single.faqCode, 'REVIEWS');
    provider.dispose();
  });

  testWidgets('Menu exposes Phase 12 customer experience links', (
    tester,
  ) async {
    final repo = FakeAuthRepository(), store = MemorySessionStorage();
    await tester.pumpWidget(
      TechSmartShopApp(
        catalogRepository: FakeCatalogRepository(),
        offerRepository: const FakeOfferRepository(),
        authRepository: repo,
        sessionStorage: store,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menuNavigationButton')));
    await tester.pump();
    final context = tester.element(find.byType(MaterialApp));
    await context.read<AuthProvider>().login('test@example.com', 'Strong1!');
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('myReviewsMenu')), findsOneWidget);
    expect(find.byKey(const Key('supportMenu')), findsOneWidget);
    expect(find.byKey(const Key('faqMenu')), findsOneWidget);
  });

  testWidgets('Profile exposes Phase 12 customer experience links', (
    tester,
  ) async {
    final auth = AuthProvider(
      FakeAuthRepository(),
      MemorySessionStorage(),
      autoInitialize: false,
    );
    await auth.login('test@example.com', 'Strong1!');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profileSupportLink')), findsOneWidget);
    expect(find.byKey(const Key('profileFaqLink')), findsOneWidget);
    expect(find.byKey(const Key('profileReviewsLink')), findsOneWidget);
    auth.dispose();
  });
}

class _FakeReviewRepository implements ReviewRepository {
  @override
  Future<ProductReview> createReview({
    required int productId,
    required String orderNumber,
    required int orderItemId,
    required int rating,
    String? title,
    required String comment,
  }) async => _review;

  @override
  Future<List<ProductReview>> myReviews() async => [_review];

  @override
  Future<List<ProductReview>> productReviews(int productId) async => [_review];

  @override
  Future<List<ReviewableItem>> reviewableItems(String orderNumber) async => [
    const ReviewableItem(
      orderNumber: 'TSS-1',
      orderItemId: 1,
      productId: 42,
      productName: 'Mouse',
      delivered: true,
      alreadyReviewed: false,
    ),
  ];

  @override
  Future<ReviewSummary> summary(int productId) async => const ReviewSummary(
    productId: 42,
    averageRating: DecimalRating('5'),
    reviewCount: 1,
  );

  @override
  Future<ProductReview> updateReview({
    required String reviewNumber,
    int? rating,
    String? title,
    String? comment,
  }) async => _review;

  static const _review = ProductReview(
    reviewNumber: 'REV-1',
    productId: 42,
    productName: 'Mouse',
    customerDisplayName: 'Verified customer',
    orderNumber: 'TSS-1',
    rating: 5,
    title: 'Great',
    comment: 'Works well.',
    status: 'APPROVED',
  );
}

class _FakeSupportRepository implements SupportRepository {
  @override
  Future<SupportTicketDetail> addMessage(
    String ticketNumber,
    String message,
  ) async => _detail;

  @override
  Future<SupportTicketDetail> close(String ticketNumber) async => _detail;

  @override
  Future<SupportTicketDetail> createTicket({
    required String subject,
    required String category,
    String? priority,
    String? relatedOrderNumber,
    required String message,
  }) async => _detail;

  @override
  Future<SupportTicketDetail> ticket(String ticketNumber) async => _detail;

  @override
  Future<List<SupportTicketSummary>> tickets() async => [_detail];

  static const _detail = SupportTicketDetail(
    ticketNumber: 'SUP-1',
    subject: 'Need help',
    category: 'ORDER',
    priority: 'NORMAL',
    status: 'OPEN',
    messages: [SupportTicketMessage(senderType: 'CUSTOMER', message: 'Hello')],
  );
}

class _FakeHelpRepository implements HelpRepository {
  @override
  Future<HelpFaq> faq(String faqCode) async => _faq;

  @override
  Future<List<HelpFaq>> faqs({String? category, String? query}) async => [_faq];

  static const _faq = HelpFaq(
    faqCode: 'REVIEWS',
    category: 'Reviews',
    question: 'When can I review?',
    answer: 'After delivery.',
    displayOrder: 40,
  );
}
