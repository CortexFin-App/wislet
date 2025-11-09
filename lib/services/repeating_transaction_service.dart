import 'package:wislet/data/repositories/repeating_transaction_repository.dart';
import 'package:wislet/data/repositories/transaction_repository.dart';
import 'package:wislet/data/repositories/wallet_repository.dart';
import 'package:wislet/models/repeating_transaction_model.dart';
import 'package:wislet/models/transaction.dart' as fin_transaction;

class RepeatingTransactionService {
  RepeatingTransactionService(
    this._rtRepository,
    this._transactionRepository,
    this._walletRepository,
  );

  final RepeatingTransactionRepository _rtRepository;
  final TransactionRepository _transactionRepository;
  final WalletRepository _walletRepository;

  Future<void> checkAndGenerateTransactions() async {
    final walletsEither = await _walletRepository.getAllWallets();

    await walletsEither.fold(
      (failure) async {},
      (wallets) async {
        for (final wallet in wallets) {
          if (wallet.id == null) continue;
          final userIdForWallet = wallet.ownerUserId;

          final rtEither =
              await _rtRepository.getAllRepeatingTransactions(wallet.id!);

          await rtEither.fold(
            (l) => null,
            (allRTs) async {
              for (final rt in allRTs) {
                if (!rt.isActive) continue;
                var checkDate = rt.nextDueDate;
                while (checkDate.isBefore(DateTime.now()) ||
                    checkDate.isAtSameMomentAs(DateTime.now())) {
                  if (rt.endDate != null && checkDate.isAfter(rt.endDate!)) {
                    rt.isActive = false;
                    await _rtRepository.updateRepeatingTransaction(rt);
                    break;
                  }

                  if (rt.occurrences != null &&
                      (rt.generatedOccurrencesCount ?? 0) >= rt.occurrences!) {
                    rt.isActive = false;
                    await _rtRepository.updateRepeatingTransaction(rt);
                    break;
                  }

                  final transaction = fin_transaction.Transaction(
                    type: rt.type,
                    originalAmount: rt.originalAmount,
                    originalCurrencyCode: rt.originalCurrencyCode,
                    amountInBaseCurrency: rt.originalAmount,
                    exchangeRateUsed: 1,
                    categoryId: rt.categoryId,
                    date: checkDate,
                    description: rt.description,
                  );

                  await _transactionRepository.createTransaction(
                    transaction,
                    wallet.id!,
                    userIdForWallet,
                  );

                  rt
                  ..generatedOccurrencesCount =
                      (rt.generatedOccurrencesCount ?? 0) + 1
                  ..nextDueDate = RepeatingTransaction.calculateNextDueDate(
                    checkDate,
                    rt.frequency,
                  );
                  await _rtRepository.updateRepeatingTransaction(rt);

                  checkDate = rt.nextDueDate;
                }
              }
            },
          );
        }
      },
    );
  }
}
