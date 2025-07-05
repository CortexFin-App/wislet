import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/plan.dart';
import '../../../models/plan_view_data.dart';
import '../plan_repository.dart';

class SupabasePlanRepositoryImpl implements PlanRepository {
  final SupabaseClient _client;
  SupabasePlanRepositoryImpl(this._client);

  @override
  Future<List<PlanViewData>> getPlansWithCategoryDetails(int walletId,
      {String? orderBy}) async {
    final response = await _client
        .from('plans')
        .select('*, categories(*)')
        .eq('wallet_id', walletId)
        .order('start_date', ascending: false);
    return (response as List)
        .map((data) => PlanViewData.fromMap(data))
        .toList();
  }

  @override
  Future<int> createPlan(Plan plan, int walletId) async {
    final map = plan.toMap();
    map['wallet_id'] = walletId;
    final response = await _client.from('plans').insert(map).select().single();
    return response['id'] as int;
  }

  @override
  Future<int> updatePlan(Plan plan) async {
    final response = await _client
        .from('plans')
        .update(plan.toMap())
        .eq('id', plan.id!)
        .select()
        .single();
    return response['id'] as int;
  }

  @override
  Future<int> deletePlan(int id) async {
    await _client.from('plans').delete().eq('id', id);
    return id;
  }

  @override
  Future<List<Plan>> getPlansForPeriod(
      int walletId, DateTime startDate, DateTime endDate) async {
    final response = await _client
        .from('plans')
        .select()
        .eq('wallet_id', walletId)
        .lte('end_date', endDate.toIso8601String())
        .gte('start_date', startDate.toIso8601String());
    return (response as List).map((data) => Plan.fromMap(data)).toList();
  }

  @override
  Future<List<PlanViewData>> getActivePlansForCategoryAndDate(
      int walletId, int categoryId, DateTime date) async {
    final dateString = date.toIso8601String();
    final response = await _client
        .from('plans')
        .select('*, categories(*)')
        .eq('wallet_id', walletId)
        .eq('category_id', categoryId)
        .lte('start_date', dateString)
        .gte('end_date', dateString);
    return (response as List)
        .map((data) => PlanViewData.fromMap(data))
        .toList();
  }
}