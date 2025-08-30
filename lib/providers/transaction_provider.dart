import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/models/category.dart' as fin_category;
import 'package:sage_wallet_reborn/providers/wallet_provider.dart';
import 'package:sage_wallet_reborn/services/ai_categorization_service.dart';
import 'package:sage_wallet_reborn/utils/debouncer.dart';

class TransactionProvider with ChangeNotifier {
  final AICategorizationService _aiService = getIt<AICategorizationService>();
  final Debouncer _debouncer = Debouncer(milliseconds: 400);

  fin_category.Category? _suggestedCategory;
  bool _isLoadingSuggestion = false;

  fin_category.Category? get suggestedCategory => _suggestedCategory;
  bool get isLoadingSuggestion => _isLoadingSuggestion;

  void onDescriptionChanged(BuildContext context, String description) {
    if (description.length < 3) {
      _suggestedCategory = null;
      notifyListeners();
      return;
    }

    _isLoadingSuggestion = true;
    notifyListeners();

    _debouncer.run(() async {
      final walletId = context.read<WalletProvider>().currentWallet?.id;
      if (walletId == null) {
        _isLoadingSuggestion = false;
        notifyListeners();
        return;
      }

      _suggestedCategory = await _aiService.suggestCategory(
        description: description,
        walletId: walletId,
      );
      _isLoadingSuggestion = false;
      notifyListeners();
    });
  }

  void clearSuggestion() {
    _suggestedCategory = null;
    notifyListeners();
  }
}
