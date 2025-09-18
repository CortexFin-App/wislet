import 'package:fpdart/fpdart.dart';
import 'package:wislet/core/error/failures.dart';
import 'package:wislet/models/plan.dart';
import 'package:wislet/models/plan_view_data.dart';

abstract class PlanRepository {
  Future<Either<AppFailure, int>> createPlan(Plan plan, int walletId);

  Future<Either<AppFailure, int>> updatePlan(Plan plan);

  Future<Either<AppFailure, int>> deletePlan(int id);

  Future<Either<AppFailure, List<Plan>>> getPlansForPeriod(
    int walletId,
    DateTime startDate,
    DateTime endDate,
  );

  Future<Either<AppFailure, List<PlanViewData>>> getPlansWithCategoryDetails(
    int walletId, {
    String? orderBy,
  });

  Future<Either<AppFailure, List<PlanViewData>>>
      getActivePlansForCategoryAndDate(
    int walletId,
    int categoryId,
    DateTime date,
  );
}
