import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger();

  static const _chunkSize = 900;

  void debug(String message) {
    debugPrint('[DEBUG] $message');
  }

  void info(String message) {
    debugPrint('[INFO] $message');
  }

  void warn(String message) {
    debugPrint('[WARN] $message');
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('  cause: $error');
    }
    if (stackTrace != null) {
      debugPrint('  stackTrace: $stackTrace');
    }
  }

  void debugBlock(String title, String content) {
    _printBlock(level: 'DEBUG', title: title, content: content);
  }

  void infoBlock(String title, String content) {
    _printBlock(level: 'INFO', title: title, content: content);
  }

  void warnBlock(String title, String content) {
    _printBlock(level: 'WARN', title: title, content: content);
  }

  void _printBlock({
    required String level,
    required String title,
    required String content,
  }) {
    debugPrint('[$level] $title BEGIN');
    if (content.isEmpty) {
      debugPrint('[$level] <empty>');
      debugPrint('[$level] $title END');
      return;
    }

    for (final line in content.split('\n')) {
      if (line.isEmpty) {
        debugPrint('[$level] ');
        continue;
      }
      for (var start = 0; start < line.length; start += _chunkSize) {
        final end = start + _chunkSize > line.length
            ? line.length
            : start + _chunkSize;
        debugPrint('[$level] ${line.substring(start, end)}');
      }
    }
    debugPrint('[$level] $title END');
  }
}
