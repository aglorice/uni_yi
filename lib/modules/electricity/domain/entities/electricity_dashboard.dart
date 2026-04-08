import '../../../../core/models/data_origin.dart';

enum ElectricityChargePeriod {
  threeMonths(code: '3M', label: '近3个月'),
  oneYear(code: '1Y', label: '近1年'),
  all(code: '1Y+', label: '全部');

  const ElectricityChargePeriod({required this.code, required this.label});

  final String code;
  final String label;

  static ElectricityChargePeriod fromCode(String value) {
    for (final period in values) {
      if (period.code == value) {
        return period;
      }
    }
    return ElectricityChargePeriod.oneYear;
  }
}

class ElectricityRoomBinding {
  const ElectricityRoomBinding({
    required this.building,
    required this.roomNumber,
    this.userTypeId = 1,
  });

  static const defaultBinding = ElectricityRoomBinding(
    building: 'K',
    roomNumber: '503',
    userTypeId: 1,
  );

  final String building;
  final String roomNumber;
  final int userTypeId;

  String get requestBuilding => building.trim().toLowerCase();
  String get requestRoomNumber => roomNumber.trim();
  String get displayLabel =>
      '${building.trim().toUpperCase()}${roomNumber.trim()}';

  ElectricityRoomBinding copyWith({
    String? building,
    String? roomNumber,
    int? userTypeId,
  }) {
    return ElectricityRoomBinding(
      building: building ?? this.building,
      roomNumber: roomNumber ?? this.roomNumber,
      userTypeId: userTypeId ?? this.userTypeId,
    );
  }

  Map<String, dynamic> toJson() => {
    'building': building,
    'roomNumber': roomNumber,
    'userTypeId': userTypeId,
  };

  factory ElectricityRoomBinding.fromJson(Map<String, dynamic> json) {
    return ElectricityRoomBinding(
      building: json['building'] as String? ?? defaultBinding.building,
      roomNumber: json['roomNumber'] as String? ?? defaultBinding.roomNumber,
      userTypeId: json['userTypeId'] as int? ?? defaultBinding.userTypeId,
    );
  }
}

class ElectricityBalance {
  const ElectricityBalance({
    required this.schoolName,
    required this.apartName,
    required this.roomName,
    required this.totalUsedKwh,
    required this.remainingKwh,
    required this.updatedAt,
  });

  final String schoolName;
  final String apartName;
  final String roomName;
  final double totalUsedKwh;
  final double remainingKwh;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'schoolName': schoolName,
    'apartName': apartName,
    'roomName': roomName,
    'totalUsedKwh': totalUsedKwh,
    'remainingKwh': remainingKwh,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ElectricityBalance.fromJson(Map<String, dynamic> json) {
    return ElectricityBalance(
      schoolName: json['schoolName'] as String? ?? '',
      apartName: json['apartName'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      totalUsedKwh: (json['totalUsedKwh'] as num?)?.toDouble() ?? 0,
      remainingKwh: (json['remainingKwh'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ElectricityRechargeRecord {
  const ElectricityRechargeRecord({
    required this.paidAt,
    required this.amountYuan,
    required this.paymentMethodCode,
    required this.paymentMethodLabel,
    required this.orderCode,
    required this.building,
    required this.roomNumber,
  });

  final DateTime paidAt;
  final double amountYuan;
  final String paymentMethodCode;
  final String paymentMethodLabel;
  final String orderCode;
  final String building;
  final String roomNumber;

  Map<String, dynamic> toJson() => {
    'paidAt': paidAt.toIso8601String(),
    'amountYuan': amountYuan,
    'paymentMethodCode': paymentMethodCode,
    'paymentMethodLabel': paymentMethodLabel,
    'orderCode': orderCode,
    'building': building,
    'roomNumber': roomNumber,
  };

  factory ElectricityRechargeRecord.fromJson(Map<String, dynamic> json) {
    return ElectricityRechargeRecord(
      paidAt: DateTime.parse(json['paidAt'] as String),
      amountYuan: (json['amountYuan'] as num?)?.toDouble() ?? 0,
      paymentMethodCode: json['paymentMethodCode'] as String? ?? '',
      paymentMethodLabel: json['paymentMethodLabel'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      building: json['building'] as String? ?? '',
      roomNumber: json['roomNumber'] as String? ?? '',
    );
  }
}

class ElectricityDashboard {
  const ElectricityDashboard({
    required this.binding,
    required this.balance,
    required this.records,
    required this.selectedPeriod,
    required this.totalRecords,
    required this.pageSize,
    required this.fetchedAt,
    required this.origin,
  });

  final ElectricityRoomBinding binding;
  final ElectricityBalance balance;
  final List<ElectricityRechargeRecord> records;
  final ElectricityChargePeriod selectedPeriod;
  final int totalRecords;
  final int pageSize;
  final DateTime fetchedAt;
  final DataOrigin origin;

  double get totalRechargeAmount {
    return records.fold<double>(0, (sum, item) => sum + item.amountYuan);
  }

  int get rechargeCount => records.length;

  double get averageRechargeAmount {
    if (records.isEmpty) {
      return 0;
    }
    return totalRechargeAmount / records.length;
  }

  ElectricityDashboard copyWith({
    ElectricityRoomBinding? binding,
    ElectricityBalance? balance,
    List<ElectricityRechargeRecord>? records,
    ElectricityChargePeriod? selectedPeriod,
    int? totalRecords,
    int? pageSize,
    DateTime? fetchedAt,
    DataOrigin? origin,
  }) {
    return ElectricityDashboard(
      binding: binding ?? this.binding,
      balance: balance ?? this.balance,
      records: records ?? this.records,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      totalRecords: totalRecords ?? this.totalRecords,
      pageSize: pageSize ?? this.pageSize,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      origin: origin ?? this.origin,
    );
  }

  Map<String, dynamic> toJson() => {
    'binding': binding.toJson(),
    'balance': balance.toJson(),
    'records': records.map((item) => item.toJson()).toList(),
    'selectedPeriod': selectedPeriod.code,
    'totalRecords': totalRecords,
    'pageSize': pageSize,
    'fetchedAt': fetchedAt.toIso8601String(),
    'origin': origin.name,
  };

  factory ElectricityDashboard.fromJson(Map<String, dynamic> json) {
    return ElectricityDashboard(
      binding: ElectricityRoomBinding.fromJson(
        json['binding'] as Map<String, dynamic>,
      ),
      balance: ElectricityBalance.fromJson(
        json['balance'] as Map<String, dynamic>,
      ),
      records: (json['records'] as List<dynamic>? ?? const [])
          .map(
            (item) => ElectricityRechargeRecord.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      selectedPeriod: ElectricityChargePeriod.fromCode(
        json['selectedPeriod'] as String? ??
            ElectricityChargePeriod.oneYear.code,
      ),
      totalRecords: json['totalRecords'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 0,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      origin: DataOrigin.values.byName(json['origin'] as String),
    );
  }
}
