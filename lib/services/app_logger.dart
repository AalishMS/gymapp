import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class _RedactingPrinter extends LogPrinter {
  final PrettyPrinter _printer = PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 3,
    lineLength: 100,
    colors: false,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.none,
  );

  static final RegExp _sensitivePattern = RegExp(
    r'(token|authorization|password|secret|api[_-]?key)',
    caseSensitive: false,
  );

  @override
  List<String> log(LogEvent event) {
    final sanitizedMessage = _sanitize(event.message);
    final sanitizedError = _sanitize(event.error);

    return _printer.log(
      LogEvent(
        event.level,
        sanitizedMessage,
        error: sanitizedError,
        stackTrace: event.stackTrace,
        time: event.time,
      ),
    );
  }

  dynamic _sanitize(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (_sensitivePattern.hasMatch(key)) {
          sanitized[key] = '<redacted>';
        } else {
          sanitized[key] = _sanitize(entry.value);
        }
      }
      return sanitized;
    }

    if (value is Iterable) {
      return value.map(_sanitize).toList();
    }

    if (value is String && _sensitivePattern.hasMatch(value)) {
      return '<redacted>';
    }

    return value;
  }
}

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: _RedactingPrinter(),
  );

  static void d(dynamic message, {Object? error, StackTrace? stackTrace}) {
    if (!kReleaseMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  static void i(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
