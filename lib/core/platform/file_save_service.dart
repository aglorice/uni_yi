import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../error/failure.dart';
import '../result/result.dart';
import 'downloads_service.dart';

class SavedFile {
  const SavedFile({
    required this.fileName,
    required this.path,
    required this.byteLength,
    this.uri,
  });

  final String fileName;
  final String path;
  final int byteLength;
  final String? uri;

  SavedFile copyWith({
    String? fileName,
    String? path,
    int? byteLength,
    String? uri,
  }) {
    return SavedFile(
      fileName: fileName ?? this.fileName,
      path: path ?? this.path,
      byteLength: byteLength ?? this.byteLength,
      uri: uri ?? this.uri,
    );
  }
}

class FileSaveService {
  const FileSaveService(this._downloadsService);

  final DownloadsService _downloadsService;

  Future<Result<SavedFile>> saveBytesSafely({
    required String fileName,
    required Uint8List bytes,
    String subdirectory = '',
    String failureLabel = '文件',
    bool pickLocation = false,
  }) async {
    try {
      final saved = pickLocation
          ? await saveBytesWithPicker(fileName: fileName, bytes: bytes)
          : await saveBytes(
              fileName: fileName,
              bytes: bytes,
              subdirectory: subdirectory,
            );
      return Success(saved);
    } on FileSystemException catch (error, stackTrace) {
      return FailureResult(
        StorageFailure(
          '$failureLabel保存失败，请稍后重试。',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } on PlatformException catch (error, stackTrace) {
      if (error.code == 'cancelled') {
        return FailureResult(
          BusinessFailure(
            '$failureLabel保存已取消。',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
      return FailureResult(
        StorageFailure(
          _formatPlatformSaveError(failureLabel, error),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        StorageFailure(
          '$failureLabel保存失败，请稍后重试。',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<SavedFile> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String subdirectory = '',
  }) async {
    if (Platform.isAndroid) {
      try {
        final saved = await _downloadsService.saveToPublicDownloads(
          bytes: bytes,
          fileName: fileName,
          subdirectory: subdirectory,
        );
        return SavedFile(
          fileName: saved.fileName,
          path: saved.locationLabel,
          byteLength: bytes.length,
          uri: saved.uri,
        );
      } on MissingPluginException {
        // Fall back to app-managed storage when the Android bridge is unavailable.
      }
    }

    final directory = await _resolveDownloadDirectory(subdirectory);
    final file = await _createUniqueFile(directory, fileName);
    await file.writeAsBytes(bytes, flush: true);
    return SavedFile(
      fileName: file.uri.pathSegments.last,
      path: file.path,
      byteLength: bytes.length,
    );
  }

  Future<SavedFile> saveBytesWithPicker({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (!Platform.isAndroid) {
      throw PlatformException(code: 'not_supported', message: '当前平台暂不支持另存为。');
    }

    final saved = await _downloadsService.saveWithPicker(
      bytes: bytes,
      fileName: fileName,
    );
    return SavedFile(
      fileName: saved.fileName,
      path: saved.locationLabel,
      byteLength: bytes.length,
      uri: saved.uri,
    );
  }

  Future<Directory> _resolveDownloadDirectory(String subdirectory) async {
    final downloads = await getDownloadsDirectory();
    final base = downloads ?? await getApplicationDocumentsDirectory();
    final normalized = _normalizeSubdirectory(subdirectory);
    final directory = Directory(
      normalized.isEmpty ? base.path : '${base.path}/$normalized',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<File> _createUniqueFile(Directory directory, String fileName) async {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex <= 0 ? fileName : fileName.substring(0, dotIndex);
    final extension = dotIndex <= 0 ? '' : fileName.substring(dotIndex);

    var candidate = File('${directory.path}/$fileName');
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = File('${directory.path}/${baseName}_$suffix$extension');
      suffix += 1;
    }
    return candidate;
  }

  String _normalizeSubdirectory(String raw) {
    return raw
        .replaceAll('\\', '/')
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .join('/');
  }
}

String _formatPlatformSaveError(String label, PlatformException error) {
  final message = error.message?.trim();
  if (message != null && message.isNotEmpty) {
    return '$label保存失败：$message';
  }
  return '$label保存失败，请稍后重试。';
}
