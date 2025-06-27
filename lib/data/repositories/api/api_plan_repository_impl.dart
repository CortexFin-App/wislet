import 'package:sage_wallet_reborn/models/plan.dart';
import 'package:sage_wallet_reborn/models/plan_view_data.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/data/repositories/plan_repository.dart';

class ApiPlanRepositoryImpl implements PlanRepository {
  final ApiClient _apiClient;
  ApiPlanRepositoryImpl(this._apiClient);

  @override
  Future<int> createPlan(Plan plan, int walletId) async {
    final map = plan.toMap();
    map['wallet_id'] = walletId;
    final responseData = await _apiClient.post('/plans', body: map);
    return responseData['id'] as int;
  }

  @override
  Future<List<PlanViewData>> getPlansWithCategoryDetails(int walletId, {String? orderBy}) async {
    final responseData = await _apiClient.get(
      '/plans',
      queryParams: { 'walletId': walletId.toString() },
    ) as List;
    return responseData.map((data) => PlanViewData.fromMap(data)).toList();
  }
  
  @override
  Future<int> updatePlan(Plan plan) async {
    final responseData = await _apiClient.put('/plans/${plan.id}', body: plan.toMap());
    return responseData['id'] as int;
  }
  
  @override
  Future<int> deletePlan(int id) async {
    await _apiClient.delete('/plans/$id');
    return id;
  }

  @override
  Future<List<Plan>> getPlansForPeriod(int walletId, DateTime startDate, DateTime endDate) {
    throw UnimplementedError('This specific query is better handled by combining other calls or on the client for API version.');
  }
  
  @override
  Future<List<PlanViewData>> getActivePlansForCategoryAndDate(int walletId, int categoryId, DateTime date) {
    throw UnimplementedError('This specific query is better handled on the client for API version.');
  }
}