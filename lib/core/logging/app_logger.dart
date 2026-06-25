import 'package:flutter/foundation.dart';
import "package:logger/logger.dart" as logger;

class AppLogger {
  AppLogger._();

  static final logger.ConsoleLogger _logger = logger.ConsoleLogger(
    filter: logger.DevelopmentFilter(),
    level: logger.LogLevel.debug,
    output: logger.ConsoleOutput(),
    printer: logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      printTime: true,
      colors: true,
    ),
  );

  static void debug(Object? message) {
    if (!kDebugMode) return;
    _logger.debug(message);
  }

  static void info(Object? message) {
    if (!kDebugMode) return;
    _logger.info(message);
  }

  static void warning(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    _logger.warning(message, error: error, stackTrace: stackTrace);
  }

  static void error(
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    _logger.error(message, error: error, stackTrace: stackTrace);
  }
}
