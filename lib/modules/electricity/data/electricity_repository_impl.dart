import '../../../core/logging/app_logger.dart';
import '../../../core/models/data_origin.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/json_cache_store.dart';
import '../../../integrations/electricity_recharge/wyu_electricity_api.dart';
import '../../auth/domain/entities/app_session.dart';
import '../domain/entities/electricity_dashboard.dart';
import '../domain/repositories/electricity_repository.dart';

class ElectricityRepositoryImpl implements ElectricityRepository {
  const ElectricityRepositoryImpl({
    required WyuElectricityApi api,
    required JsonCacheStore cacheStore,
    required AppLogger logger,
  }) : _api = api,
       _cacheStore = cacheStore,
       _logger = logger;

  static const _bindingKey = 'electricity.binding.current';
  static const _dashboardCachePrefix = 'electricity.dashboard';

  final WyuElectricityApi _api;
  final JsonCacheStore _cacheStore;
  final AppLogger _logger;

  @override
  Future<ElectricityRoomBinding> readBinding() async {
    final cached = await _cacheStore.readMap(_bindingKey);
    if (cached == null) {
      return ElectricityRoomBinding.defaultBinding;
    }

    return ElectricityRoomBinding.fromJson(cached);
  }

  @override
  Future<void> saveBinding(ElectricityRoomBinding binding) async {
    await _cacheStore.writeMap(_bindingKey, binding.toJson());
  }

  @override
  Future<Result<ElectricityDashboard>> fetchDashboard({
    required AppSession session,
    ElectricityChargePeriod period = ElectricityChargePeriod.oneYear,
    bool forceRefresh = false,
  }) async {
    final binding = await readBinding();
    final cacheKey = _cacheKey(binding, period);
    final cachedMap = await _cacheStore.readMap(cacheKey);
    final cachedDashboard = cachedMap == null
        ? null
        : ElectricityDashboard.fromJson(
            cachedMap,
          ).copyWith(origin: DataOrigin.cache);

    _logger.info(
      '[Electricity] 开始查询 userId=${session.userId} building=${binding.requestBuilding} room=${binding.requestRoomNumber} period=${period.code}',
    );

    final balanceResult = await _api.fetchCurrentRemaining(binding);
    if (balanceResult case FailureResult<dynamic>(failure: final failure)) {
      if (cachedDashboard != null && !forceRefresh) {
        _logger.warn('[Electricity] 电量接口失败，回退缓存。');
        return Success(cachedDashboard);
      }
      return FailureResult(failure);
    }

    final recordsResult = await _api.fetchRechargeHistory(
      binding,
      period: period,
    );
    final recordsPayload = recordsResult.dataOrNull;
    if (recordsPayload == null) {
      _logger.warn(
        '[Electricity] 充值记录接口失败，继续返回电量主数据 reason=${recordsResult.failureOrNull?.message}',
      );
    }

    final fallbackRecords = cachedDashboard?.selectedPeriod == period
        ? cachedDashboard!.records
        : const <ElectricityRechargeRecord>[];
    final dashboard = ElectricityDashboard(
      binding: binding,
      balance: ElectricityBalance(
        schoolName: balanceResult.requireValue().schoolName,
        apartName: balanceResult.requireValue().apartName,
        roomName: balanceResult.requireValue().roomName,
        totalUsedKwh: balanceResult.requireValue().totalUsedKwh,
        remainingKwh: balanceResult.requireValue().remainingKwh,
        updatedAt: balanceResult.requireValue().updatedAt,
      ),
      records: recordsPayload == null
          ? fallbackRecords
          : recordsPayload.records
                .map(
                  (item) => ElectricityRechargeRecord(
                    paidAt: item.paidAt,
                    amountYuan: item.amountYuan,
                    paymentMethodCode: item.paymentMethodCode,
                    paymentMethodLabel: item.paymentMethodLabel,
                    orderCode: item.orderCode,
                    building: item.building,
                    roomNumber: item.roomNumber,
                  ),
                )
                .toList(),
      selectedPeriod: period,
      totalRecords: recordsPayload?.total ?? fallbackRecords.length,
      pageSize: recordsPayload?.pageSize ?? fallbackRecords.length,
      fetchedAt: DateTime.now(),
      origin: DataOrigin.remote,
    );

    await _cacheStore.writeMap(cacheKey, dashboard.toJson());
    return Success(dashboard);
  }

  String _cacheKey(
    ElectricityRoomBinding binding,
    ElectricityChargePeriod period,
  ) {
    return '$_dashboardCachePrefix.${binding.requestBuilding}.${binding.requestRoomNumber}.${period.code}';
  }
}
