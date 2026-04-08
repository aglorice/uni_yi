import 'package:flutter/services.dart';

enum ApkInstallStatus { started, permissionRequired }

class ApkInstallResult {
  const ApkInstallResult({required this.status, this.message});

  final ApkInstallStatus status;
  final String? message;
}

class AppInstallerService {
  const AppInstallerService();

  static const _channel = MethodChannel('uni_yi/app_installer');

  Future<ApkInstallResult> installApk({
    required String fileName,
    String? path,
    String? uri,
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>('installApk', {
      'fileName': fileName,
      'path': path,
      'uri': uri,
    });

    if (raw == null) {
      throw PlatformException(code: 'empty_result', message: '安装结果为空。');
    }

    final status = switch (raw['status'] as String? ?? 'started') {
      'permission_required' => ApkInstallStatus.permissionRequired,
      _ => ApkInstallStatus.started,
    };

    return ApkInstallResult(status: status, message: raw['message'] as String?);
  }
}
