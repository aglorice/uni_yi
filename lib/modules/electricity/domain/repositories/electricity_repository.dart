import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_session.dart';
import '../entities/electricity_dashboard.dart';

abstract class ElectricityRepository {
  Future<ElectricityRoomBinding> readBinding();
  Future<void> saveBinding(ElectricityRoomBinding binding);

  Future<Result<ElectricityDashboard>> fetchDashboard({
    required AppSession session,
    ElectricityChargePeriod period = ElectricityChargePeriod.oneYear,
    bool forceRefresh = false,
  });
}
