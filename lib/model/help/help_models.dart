import '../common/api_models.dart';
import '../review/review_models.dart';

class HelpFaq {
  const HelpFaq({
    required this.faqCode,
    required this.category,
    required this.question,
    required this.answer,
    required this.displayOrder,
  });

  final String faqCode, category, question, answer;
  final int displayOrder;

  factory HelpFaq.fromJson(Object? value) {
    final j = unwrapDataMap(value, 'faq');
    return HelpFaq(
      faqCode: requireString(j, 'faqCode'),
      category: requireString(j, 'category'),
      question: requireString(j, 'question'),
      answer: requireString(j, 'answer'),
      displayOrder: requireInt(j, 'displayOrder'),
    );
  }
}
