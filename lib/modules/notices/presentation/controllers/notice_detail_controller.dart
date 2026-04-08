import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/app_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/campus_notice.dart';

final noticeDetailProvider = FutureProvider.autoDispose
    .family<CampusNoticeDetail, CampusNoticeItem>((ref, item) async {
      final authState = await ref.watch(authControllerProvider.future);
      final session = authState.session;
      if (session == null) {
        throw const AuthenticationFailure('当前未登录，无法加载通知正文。');
      }

      final result = await ref.read(fetchNoticeDetailUseCaseProvider)(
        session: session,
        item: item,
        forceRefresh: true,
      );

      if (result case Success<CampusNoticeDetail>(data: final detail)) {
        return detail;
      }

      // If the CAS session expired, try refreshing it and retrying.
      if (result.failureOrNull is SessionExpiredFailure) {
        final refreshed = await ref
            .read(authRepositoryProvider)
            .refreshSession();
        if (refreshed case Success<AppSession>(data: final newSession)) {
          // Persist the new session so other providers benefit too.
          ref.read(authControllerProvider.notifier).replaceSession(newSession);

          final retry = await ref.read(fetchNoticeDetailUseCaseProvider)(
            session: newSession,
            item: item,
            forceRefresh: true,
          );
          return retry.requireValue();
        }
        // Refresh failed — prompt re-login.
        ref
            .read(authControllerProvider.notifier)
            .requireReauth(refreshed.failureOrNull!);
      }

      return result.requireValue();
    });

final noticeImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, ({String url, String referer})>((ref, request) async {
      final authState = await ref.watch(authControllerProvider.future);
      final session = authState.session;
      if (session == null) {
        throw const AuthenticationFailure('当前未登录，无法加载通知图片。');
      }

      var result = await ref
          .read(wyuNoticeApiProvider)
          .fetchImageBytes(
            session: session,
            imageUri: Uri.parse(request.url),
            referer: Uri.tryParse(request.referer),
          );

      if (result case Success<Uint8List>(data: final bytes)) {
        // Keep successful image bytes alive so scrolling out/in doesn't
        // trigger another protected image fetch.
        ref.keepAlive();
        return bytes;
      }

      if (result.failureOrNull is SessionExpiredFailure) {
        final refreshed = await ref
            .read(authRepositoryProvider)
            .refreshSession();
        if (refreshed case Success<AppSession>(data: final newSession)) {
          ref.read(authControllerProvider.notifier).replaceSession(newSession);

          final retry = await ref
              .read(wyuNoticeApiProvider)
              .fetchImageBytes(
                session: newSession,
                imageUri: Uri.parse(request.url),
                referer: Uri.tryParse(request.referer),
              );
          if (retry case Success<Uint8List>()) {
            ref.keepAlive();
          }
          return retry.requireValue();
        }

        ref
            .read(authControllerProvider.notifier)
            .requireReauth(refreshed.failureOrNull!);
      }

      return result.requireValue();
    });

final noticeAttachmentDownloadingProvider = StateProvider.autoDispose
    .family<bool, String>((ref, url) => false);

final noticeImageSavingProvider = StateProvider.autoDispose
    .family<bool, String>((ref, url) => false);

final noticeFileSaverProvider = Provider<NoticeFileSaver>(NoticeFileSaver.new);

final noticeAttachmentDownloaderProvider = Provider<NoticeAttachmentDownloader>(
  NoticeAttachmentDownloader.new,
);

class NoticeFileSaver {
  NoticeFileSaver(this._ref);

  final Ref _ref;

  Future<Result<SavedNoticeFile>> saveBytesSafely({
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

  Future<SavedNoticeFile> saveBytes({
    required String fileName,
    required Uint8List bytes,
    String subdirectory = '',
  }) async {
    if (Platform.isAndroid) {
      try {
        final saved = await _ref
            .read(downloadsServiceProvider)
            .saveToPublicDownloads(
              bytes: bytes,
              fileName: fileName,
              subdirectory: subdirectory,
            );
        return SavedNoticeFile(
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
    return SavedNoticeFile(
      fileName: file.uri.pathSegments.last,
      path: file.path,
      byteLength: bytes.length,
    );
  }

  Future<SavedNoticeFile> saveBytesWithPicker({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (!Platform.isAndroid) {
      throw PlatformException(
        code: 'not_supported',
        message: '当前平台暂不支持另存为。',
      );
    }

    final saved = await _ref
        .read(downloadsServiceProvider)
        .saveWithPicker(bytes: bytes, fileName: fileName);
    return SavedNoticeFile(
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
    final normalized = raw
        .replaceAll('\\', '/')
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .join('/');
    return normalized;
  }
}

class NoticeAttachmentDownloader {
  NoticeAttachmentDownloader(this._ref);

  final Ref _ref;

  Future<Result<SavedNoticeFile>> download({
    required CampusNoticeAttachment attachment,
    required Uri referer,
    bool pickLocation = false,
  }) async {
    try {
      final authState = await _ref.read(authControllerProvider.future);
      final session = authState.session;
      if (session == null) {
        return const FailureResult(AuthenticationFailure('当前未登录，无法下载通知附件。'));
      }

      var result = await _ref
          .read(wyuNoticeApiProvider)
          .fetchAttachmentBytes(
            session: session,
            attachmentUri: Uri.parse(attachment.url),
            referer: referer,
          );

      if (result.failureOrNull is SessionExpiredFailure) {
        final refreshed = await _ref
            .read(authRepositoryProvider)
            .refreshSession();
        if (refreshed case Success<AppSession>(data: final newSession)) {
          _ref.read(authControllerProvider.notifier).replaceSession(newSession);
          result = await _ref
              .read(wyuNoticeApiProvider)
              .fetchAttachmentBytes(
                session: newSession,
                attachmentUri: Uri.parse(attachment.url),
                referer: referer,
              );
        } else if (refreshed.failureOrNull != null) {
          _ref
              .read(authControllerProvider.notifier)
              .requireReauth(refreshed.failureOrNull!);
          return FailureResult(refreshed.failureOrNull!);
        }
      }

      if (result case FailureResult<Uint8List>(failure: final failure)) {
        return FailureResult(failure);
      }

      final bytes = result.requireValue();
      final fileName = _buildFileName(attachment);
      final fileSaver = _ref.read(noticeFileSaverProvider);
      final saved = pickLocation
          ? await fileSaver.saveBytesWithPicker(
              fileName: fileName,
              bytes: bytes,
            )
          : await fileSaver.saveBytes(
              fileName: fileName,
              bytes: bytes,
              subdirectory: '',
            );
      return Success(saved.copyWith(byteLength: bytes.length));
    } on FileSystemException catch (error, stackTrace) {
      return FailureResult(
        StorageFailure('附件保存失败，请稍后重试。', cause: error, stackTrace: stackTrace),
      );
    } on PlatformException catch (error, stackTrace) {
      if (error.code == 'cancelled') {
        return FailureResult(
          BusinessFailure('附件保存已取消。', cause: error, stackTrace: stackTrace),
        );
      }
      return FailureResult(
        StorageFailure(
          _formatPlatformSaveError('附件', error),
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        StorageFailure('附件保存失败，请稍后重试。', cause: error, stackTrace: stackTrace),
      );
    }
  }

  String _buildFileName(CampusNoticeAttachment attachment) {
    final raw = attachment.title.trim().isEmpty
        ? '附件'
        : attachment.title.trim();
    final sanitized = raw
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.isEmpty ? '附件' : sanitized;
  }
}

String _formatPlatformSaveError(String label, PlatformException error) {
  final message = error.message?.trim();
  if (message != null && message.isNotEmpty) {
    return '$label保存失败：$message';
  }
  return '$label保存失败，请稍后重试。';
}

class SavedNoticeFile {
  const SavedNoticeFile({
    required this.fileName,
    required this.path,
    required this.byteLength,
    this.uri,
  });

  final String fileName;
  final String path;
  final int byteLength;
  final String? uri;

  SavedNoticeFile copyWith({
    String? fileName,
    String? path,
    int? byteLength,
    String? uri,
  }) {
    return SavedNoticeFile(
      fileName: fileName ?? this.fileName,
      path: path ?? this.path,
      byteLength: byteLength ?? this.byteLength,
      uri: uri ?? this.uri,
    );
  }
}
