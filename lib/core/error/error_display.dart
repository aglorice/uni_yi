import 'package:flutter/material.dart';

import 'failure.dart';

class ErrorDisplayInfo {
  const ErrorDisplayInfo({
    required this.title,
    required this.message,
    required this.icon,
    this.suggestion,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? suggestion;
}

ErrorDisplayInfo formatError(Object error) {
  if (error is Failure) {
    return switch (error) {
      NetworkFailure() => ErrorDisplayInfo(
          title: '网络连接失败',
          message: error.message,
          icon: Icons.wifi_off,
          suggestion: '请检查网络后重试',
        ),
      SessionExpiredFailure() => ErrorDisplayInfo(
          title: '登录已过期',
          message: error.message,
          icon: Icons.lock_outline,
          suggestion: '请重新登录',
        ),
      AuthenticationFailure() => ErrorDisplayInfo(
          title: '认证失败',
          message: error.message,
          icon: Icons.person_off,
        ),
      ParsingFailure() => ErrorDisplayInfo(
          title: '数据解析异常',
          message: error.message,
          icon: Icons.broken_image,
          suggestion: '学校系统可能正在维护',
        ),
      BusinessFailure() => ErrorDisplayInfo(
          title: '服务暂不可用',
          message: error.message,
          icon: Icons.info_outline,
        ),
      StorageFailure() => ErrorDisplayInfo(
          title: '本地存储异常',
          message: error.message,
          icon: Icons.storage,
        ),
      _ => ErrorDisplayInfo(
          title: '操作失败',
          message: error.message,
          icon: Icons.error_outline,
        ),
    };
  }

  return ErrorDisplayInfo(
    title: '出错了',
    message: error.toString(),
    icon: Icons.error_outline,
  );
}
