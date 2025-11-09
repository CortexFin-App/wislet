import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/data/repositories/wallet_repository.dart';
import 'package:wislet/models/wallet.dart';
import 'package:wislet/services/error_monitoring_service.dart';

class SupabaseWalletRepositoryImpl implements WalletRepository {
  SupabaseWalletRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Either<AppFailure, List<Wallet>>> getAllWallets() async {
    try {
      final response = await _client
          .from('wallets')
          .select('*, wallet_users(*, users!inner(*))')
          .eq('is_deleted', false);
      final wallets = response.map(Wallet.fromMap).toList();
      return Right(wallets);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Wallet?>> getWallet(int id) async {
    try {
      final response = await _client
          .from('wallets')
          .select('*, wallet_users(*, users!inner(*))')
          .eq('id', id)
          .eq('is_deleted', false)
          .maybeSingle();
      if (response == null) {
        return const Right(null);
      }
      return Right(Wallet.fromMap(response));
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createWallet({
    required String name,
    required String ownerUserId,
    bool isDefault = false,
  }) async {
    try {
      final response = await _client.rpc<int>(
        'create_new_wallet',
        params: {'p_name': name, 'p_is_default': isDefault},
      );
      return Right(response);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updateWallet(Wallet wallet) async {
    try {
      final response = await _client
          .from('wallets')
          .update(wallet.toMapForApi())
          .eq('id', wallet.id!)
          .select()
          .single();
      return Right(response['id'] as int);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deleteWallet(int walletId) async {
    try {
      await _client.from('wallets').update({
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', walletId);
      return Right(walletId);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> changeUserRole(
    int walletId,
    String userId,
    String newRole,
  ) async {
    try {
      await _client
          .from('wallet_users')
          .update({'role': newRole})
          .eq('wallet_id', walletId)
          .eq('user_id', userId);
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> removeUserFromWallet(
    int walletId,
    String userId,
  ) async {
    try {
      await _client
          .from('wallet_users')
          .delete()
          .eq('wallet_id', walletId)
          .eq('user_id', userId);
      return const Right(null);
    } on Exception catch (e, s) {
      await ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> createInitialWallet() async {
    return Left(
      UnexpectedFailure(
        message: 'createInitialWallet is a local-only operation.',
      ),
    );
  }
}
