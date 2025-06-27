import '../data/repositories/repeating_transaction_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../models/repeating_transaction_model.dart';
import '../models/transaction.dart' as FinTransaction;

class RepeatingTransactionService {
  final RepeatingTransactionRepository _rtRepository;
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;

  RepeatingTransactionService(this._rtRepository, this._transactionRepository, this._walletRepository);

  Future<void> checkAndGenerateTransactions() async {
    final wallets = await _walletRepository.getAllWallets();
    for (final wallet in wallets) {
      if (wallet.id == null) continue;
      
      final List<RepeatingTransaction> allRTs = await _rtRepository.getAllRepeatingTransactions(wallet.id!);
      for (RepeatingTransaction rt in allRTs) {
        if (!rt.isActive) continue;
        DateTime checkDate = rt.nextDueDate;
        while (checkDate.isBefore(DateTime.now()) || checkDate.isAtSameMomentAs(DateTime.now())) {
          if (rt.endDate != null && checkDate.isAfter(rt.endDate!)) {
            rt.isActive = false;
            await _rtRepository.updateRepeatingTransaction(rt);
            break;
          }

          if (rt.occurrences != null && (rt.generatedOccurrencesCount ?? 0) >= rt.occurrences!) {
            rt.isActive = false;
            await _rtRepository.updateRepeatingTransaction(rt);
            break;
          }
          
          final transaction = FinTransaction.Transaction(
            type: rt.type,
            originalAmount: rt.originalAmount,
            originalCurrencyCode: rt.originalCurrencyCode,
            amountInBaseCurrency: rt.originalAmount,
            exchangeRateUsed: 1.0,
            categoryId: rt.categoryId,
            date: checkDate,
            description: rt.description,
          );
          
          await _transactionRepository.createTransaction(transaction, wallet.id!);
          
          rt.generatedOccurrencesCount = (rt.generatedOccurrencesCount ?? 0) + 1;
          rt.nextDueDate = RepeatingTransaction.calculateNextDueDate(checkDate, rt.frequency);
          await _rtRepository.updateRepeatingTransaction(rt);
          
          checkDate = rt.nextDueDate;
        }
      }
    }
  }
}