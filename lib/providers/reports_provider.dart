import 'package:flutter/material.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/models/financial_story.dart';
import 'package:sage_wallet_reborn/services/financial_report_service.dart';

class ReportsProvider with ChangeNotifier {
  final FinancialReportService _reportService = getIt<FinancialReportService>();

  bool _isLoading = true;
  List<FinancialStory> _stories = [];

  bool get isLoading => _isLoading;
  List<FinancialStory> get stories => _stories;

  Future<void> fetchStories({required int walletId}) async {
    _isLoading = true;
    notifyListeners();

    _stories = await _reportService.getFinancialStories(walletId: walletId);

    _isLoading = false;
    notifyListeners();
  }
}
