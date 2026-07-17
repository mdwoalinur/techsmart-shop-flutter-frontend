import 'package:flutter/foundation.dart';

import '../model/help/help_models.dart';
import '../service/help/help_service.dart';

enum HelpLoadState { idle, loading, loaded, error }

class HelpProvider extends ChangeNotifier {
  HelpProvider(this.repository);
  final HelpRepository repository;
  HelpLoadState state = HelpLoadState.idle;
  String? error;
  String? query;
  List<HelpFaq> faqs = const [];
  HelpFaq? selected;

  Future<void> load({String? search, String? category}) async {
    query = search;
    state = HelpLoadState.loading;
    error = null;
    notifyListeners();
    try {
      faqs = await repository.faqs(category: category, query: search);
      state = HelpLoadState.loaded;
    } catch (e) {
      error = e is HelpRequestException
          ? e.message
          : 'Unable to load help articles.';
      state = HelpLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadDetail(String faqCode) async {
    state = HelpLoadState.loading;
    error = null;
    notifyListeners();
    try {
      selected = await repository.faq(faqCode);
      state = HelpLoadState.loaded;
    } catch (e) {
      error = e is HelpRequestException
          ? e.message
          : 'Unable to load help article.';
      state = HelpLoadState.error;
    }
    notifyListeners();
  }
}
