import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/error/failures.dart';
import '../../../models/plan.dart';
import '../../../models/plan_view_data.dart';
import '../../../services/error_monitoring_service.dart';
import '../plan_repository.dart';

class SupabasePlanRepositoryImpl implements PlanRepository {
  final SupabaseClient _client;
  SupabasePlanRepositoryImpl(this._client);

  @override
  Future<Either<AppFailure, List<PlanViewData>>> getPlansWithCategoryDetails(int walletId, {String? orderBy}) async {
    try {
      final response = await _client
          .from('plans')
          .select('*, categories(*)')
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .order('start_date', ascending: false);
      final plans = (response as List).map((data) => PlanViewData.fromMap(data)).toList();
      return Right(plans);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> createPlan(Plan plan, int walletId) async {
    try {
      final map = plan.toMap();
      map['wallet_id'] = walletId;
      final response = await _client.from('plans').insert(map).select().single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> updatePlan(Plan plan) async {
    try {
      final response = await _client
        .from('plans')
        .update(plan.toMap())
        .eq('id', plan.id!)
        .select()
        .single();
      return Right(response['id'] as int);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, int>> deletePlan(int id) async {
    try {
      await _client
        .from('plans')
        .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
      return Right(id);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Plan>>> getPlansForPeriod(int walletId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _client
          .from('plans')
          .select()
          .eq('wallet_id', walletId)
          .eq('is_deleted', false)
          .lte('end_date', endDate.toIso8601String())
          .gte('start_date', startDate.toIso8601String());
      final plans = (response as List).map((data) => Plan.fromMap(data)).toList();
      return Right(plans);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<PlanViewData>>> getActivePlansForCategoryAndDate(int walletId, int categoryId, DateTime date) async {
    try {
      final dateString = date.toIso8601String();
      final response = await _client
          .from('plans')
          .select('*, categories(*)')
          .eq('wallet_id', walletId)
          .eq('category_id', categoryId)
          .eq('is_deleted', false)
          .lte('start_date', dateString)
          .gte('end_date', dateString);
      final plans = (response as List).map((data) => PlanViewData.fromMap(data)).toList();
      return Right(plans);
    } catch(e, s) {
      ErrorMonitoringService.capture(e, stackTrace: s);
      return Left(NetworkFailure(details: e.toString()));
    }
  }
}