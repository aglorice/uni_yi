import '../../../core/result/result.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/electricity_dashboard.dart';
import '../domain/repositories/electricity_repository.dart';

class FetchElectricityDashboardUseCase {
  const FetchElectricityDashboardUseCase(this._repository);

  final ElectricityRepository _repository;

  Future<Result<ElectricityDashboard>> call({
    required AppSession session,
    ElectricityChargePeriod period = ElectricityChargePeriod.oneYear,
    bool forceRefresh = false,
  }) {
    return _repository.fetchDashboard(
      session: session,
      period: period,
      forceRefresh: forceRefresh,
    );
  }
}
