import 'package:flutter/services.dart';

class DownloadsSaveResult {
  const DownloadsSaveResult({
    required this.fileName,
    required this.locationLabel,
    this.uri,
  });

  final String fileName;
  final String locationLabel;
  final String? uri;
}

class DownloadsService {
  const DownloadsService();

  static const _channel = MethodChannel('uni_yi/downloads');

  Future<DownloadsSaveResult> saveToPublicDownloads({
    required Uint8List bytes,
    required String fileName,
    String subdirectory = '',
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
      'saveToPublicDownloads',
      {'bytes': bytes, 'fileName': fileName, 'subdirectory': subdirectory},
    );

    if (raw == null) {
      throw PlatformException(code: 'empty_result', message: '下载结果为空。');
    }

    return DownloadsSaveResult(
      fileName: raw['fileName'] as String? ?? fileName,
      locationLabel:
          raw['locationLabel'] as String? ??
          _defaultLocationLabel(fileName, subdirectory),
      uri: raw['uri'] as String?,
    );
  }

  Future<DownloadsSaveResult> saveWithPicker({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
      'saveWithPicker',
      {'bytes': bytes, 'fileName': fileName},
    );

    if (raw == null) {
      throw PlatformException(code: 'empty_result', message: '下载结果为空。');
    }

    return DownloadsSaveResult(
      fileName: raw['fileName'] as String? ?? fileName,
      locationLabel: raw['locationLabel'] as String? ?? '所选位置/$fileName',
      uri: raw['uri'] as String?,
    );
  }

  String _defaultLocationLabel(String fileName, String subdirectory) {
    final normalized = subdirectory
        .replaceAll('\\', '/')
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .join('/');
    if (normalized.isEmpty) {
      return '下载/$fileName';
    }
    return '下载/$normalized/$fileName';
  }
}
