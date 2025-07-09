import '../data/repositories/repeating_transaction_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../models/repeating_transaction_model.dart';
import '../models/transaction.dart' as fin_transaction;

class RepeatingTransactionService {
  final RepeatingTransactionRepository _rtRepository;
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;

  RepeatingTransactionService(this._rtRepository, this._transactionRepository, this._walletRepository);

  Future<void> checkAndGenerateTransactions() async {
    final walletsEither = await _walletRepository.getAllWallets();
    
    await walletsEither.fold(
      (failure) async {},
      (wallets) async {
        for (final wallet in wallets) {
          if (wallet.id == null) continue;
          
          final rtEither = await _rtRepository.getAllRepeatingTransactions(wallet.id!);
          
          rtEither.fold(
            (l) => null,
            (allRTs) async {
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
                  
                  final transaction = fin_transaction.Transaction(
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
          );
        }
      }
    );
  }
}