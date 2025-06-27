import '../../models/plan.dart';
import '../../models/plan_view_data.dart';

abstract class PlanRepository {
  Future<int> createPlan(Plan plan, int walletId);
  Future<int> updatePlan(Plan plan);
  Future<int> deletePlan(int id);
  Future<List<Plan>> getPlansForPeriod(int walletId, DateTime startDate, DateTime endDate);
  Future<List<PlanViewData>> getPlansWithCategoryDetails(int walletId, {String? orderBy});
  Future<List<PlanViewData>> getActivePlansForCategoryAndDate(int walletId, int categoryId, DateTime date);
}