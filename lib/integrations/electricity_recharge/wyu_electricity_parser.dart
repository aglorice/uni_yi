import 'dart:convert';

import 'package:intl/intl.dart';

import '../../core/error/failure.dart';
import '../../core/result/result.dart';

class WyuElectricityBalancePayload {
  const WyuElectricityBalancePayload({
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
}

class WyuElectricityRechargeRecordPayload {
  const WyuElectricityRechargeRecordPayload({
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
}

class WyuElectricityRechargePagePayload {
  const WyuElectricityRechargePagePayload({
    required this.pageSize,
    required this.total,
    required this.page,
    required this.records,
  });

  final int pageSize;
  final int total;
  final int page;
  final List<WyuElectricityRechargeRecordPayload> records;
}

class WyuElectricityParser {
  const WyuElectricityParser();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  Result<WyuElectricityBalancePayload> parseBalance(String rawBody) {
    try {
      final root = _decodeRoot(rawBody);
      if (root case FailureResult<Map<String, dynamic>>(
        failure: final failure,
      )) {
        return FailureResult(failure);
      }

      final decoded = root.requireValue();
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        return const FailureResult(ParsingFailure('电量接口缺少 data 字段。'));
      }

      return Success(
        WyuElectricityBalancePayload(
          schoolName: _stringValue(data['schoolName']),
          apartName: _stringValue(data['apartName']),
          roomName: _stringValue(data['roomName']),
          totalUsedKwh: _doubleValue(data['usedamp']),
          remainingKwh: _doubleValue(data['resamp']),
          updatedAt: _parseDateTime(data['updatedt']),
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        ParsingFailure('电量数据解析失败。', cause: error, stackTrace: stackTrace),
      );
    }
  }

  Result<WyuElectricityRechargePagePayload> parseRechargePage(String rawBody) {
    try {
      final root = _decodeRoot(rawBody);
      if (root case FailureResult<Map<String, dynamic>>(
        failure: final failure,
      )) {
        return FailureResult(failure);
      }

      final decoded = root.requireValue();
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        return const FailureResult(ParsingFailure('充值记录接口缺少 data 字段。'));
      }

      final items = data['data'];
      if (items is! List) {
        return const FailureResult(ParsingFailure('充值记录 data.data 不是列表。'));
      }

      return Success(
        WyuElectricityRechargePagePayload(
          pageSize: _intValue(data['pageSize']),
          total: _intValue(data['total']),
          page: _intValue(data['page']),
          records: items
              .whereType<Map>()
              .map(
                (item) => WyuElectricityRechargeRecordPayload(
                  paidAt: _parseDateTime(item['payTime']),
                  amountYuan: _doubleValue(item['payCent']) / 100,
                  paymentMethodCode: _stringValue(item['payMethod']),
                  paymentMethodLabel: mapPaymentMethod(
                    _stringValue(item['payMethod']),
                  ),
                  orderCode: _stringValue(item['orderCode']),
                  building: _stringValue(item['building']),
                  roomNumber: _stringValue(item['room']),
                ),
              )
              .toList(),
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        ParsingFailure('充值记录解析失败。', cause: error, stackTrace: stackTrace),
      );
    }
  }

  String mapPaymentMethod(String code) {
    switch (code.trim().toLowerCase()) {
      case 'code':
        return '扫码支付';
      case 'wx':
      case 'wechat':
        return '微信支付';
      case 'alipay':
        return '支付宝';
      default:
        return code.trim().isEmpty ? '未知方式' : code.trim();
    }
  }

  Result<Map<String, dynamic>> _decodeRoot(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return const FailureResult(ParsingFailure('电费接口返回不是 JSON 对象。'));
      }

      final success = decoded['success'];
      if (success == false) {
        return FailureResult(
          BusinessFailure(
            _stringValue(decoded['message']).ifEmpty('电费接口返回失败。'),
          ),
        );
      }

      return Success(decoded);
    } catch (error, stackTrace) {
      return FailureResult(
        ParsingFailure('电费接口返回解析失败。', cause: error, stackTrace: stackTrace),
      );
    }
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static int _intValue(Object? value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text when text.trim().isNotEmpty => int.parse(text.trim()),
      _ => 0,
    };
  }

  static double _doubleValue(Object? value) {
    return switch (value) {
      double number => number,
      num number => number.toDouble(),
      String text when text.trim().isNotEmpty => double.parse(text.trim()),
      _ => 0,
    };
  }

  static DateTime _parseDateTime(Object? value) {
    final text = _stringValue(value);
    if (text.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return _dateFormat.parseStrict(text);
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
