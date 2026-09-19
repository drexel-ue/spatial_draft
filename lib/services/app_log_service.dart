import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Severity level of log records.
enum LogLevel {
  /// Verbose diagnostic information.
  debug,

  /// General system and user flow information.
  info,

  /// Potential issues or degradations.
  warning,

  /// Recovered errors or runtime failure conditions.
  error,

  /// Fatal or uncaught exceptions / system crashes.
  crash,
}

/// A structured log record containing metadata and an optional stack trace.
class LogEntry {
  /// Constructs a [LogEntry] with the given parameters.
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
    this.metadata,
  });

  /// Deserializes a [LogEntry] from a JSON map.
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      level: LogLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => LogLevel.info,
      ),
      tag: json['tag'] as String? ?? 'APP',
      message: json['message'] as String? ?? '',
      stackTrace: json['stackTrace'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Exact time the entry occurred.
  final DateTime timestamp;

  /// Severity level of the entry.
  final LogLevel level;

  /// Category tag, e.g. 'SYSTEM', 'FLUTTER_FRAMEWORK', 'UNCAUGHT_ASYNC'.
  final String tag;

  /// Descriptive message text.
  final String message;

  /// Optional stack trace string.
  final String? stackTrace;

  /// Optional contextual data.
  final Map<String, dynamic>? metadata;

  /// Formats the time as HH:mm:ss.SSS.
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  /// Formats the date and time as yyyy-MM-dd HH:mm:ss.SSS.
  String get formattedDate {
    final y = timestamp.year.toString().padLeft(4, '0');
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    return '$y-$m-$d $formattedTime';
  }

  /// Serializes this entry to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'tag': tag,
      'message': message,
      'stackTrace': stackTrace,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer(
      '[$formattedTime] [${level.name.toUpperCase()}] [$tag] $message',
    );
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.write('\nStackTrace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// In-memory and persistent crash and diagnostics logging service.
class AppLogService {
  AppLogService._internal();

  /// Shared singleton instance.
  static final AppLogService instance = AppLogService._internal();

  static const String _keyPersistentLogs =
      'spatial_draft_persistent_crash_logs_v1';
  static const int _maxInMemoryLogs = 250;
  static const int _maxPersistentLogs = 50;

  final List<LogEntry> _logs = <LogEntry>[];
  SharedPreferences? _prefs;
  final StreamController<LogEntry> _logStreamController =
      StreamController<LogEntry>.broadcast();

  /// Live broadcast stream of newly recorded log entries.
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// All in-memory logs, sorted latest first.
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Subset of logs that are either crash or error level.
  List<LogEntry> get crashAndErrorLogs => _logs
      .where(
        (l) => l.level == LogLevel.crash || l.level == LogLevel.error,
      )
      .toList();

  /// Initializes the service and restores persistent logs from storage.
  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    _loadPersistentLogs();
  }

  void _loadPersistentLogs() {
    if (_prefs == null) return;
    try {
      final jsonStr = _prefs!.getString(_keyPersistentLogs);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        for (final item in list) {
          _logs.add(LogEntry.fromJson(item as Map<String, dynamic>));
        }
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (_) {}
  }

  Future<void> _savePersistentLogs() async {
    if (_prefs == null) return;
    try {
      final persistent = _logs
          .where(
            (l) =>
                l.level == LogLevel.crash ||
                l.level == LogLevel.error ||
                l.level == LogLevel.warning,
          )
          .take(_maxPersistentLogs)
          .map((l) => l.toJson())
          .toList();
      await _prefs!.setString(_keyPersistentLogs, jsonEncode(persistent));
    } catch (_) {}
  }

  void _addLog(LogEntry entry) {
    _logs.insert(0, entry);
    if (_logs.length > _maxInMemoryLogs) {
      _logs.removeRange(_maxInMemoryLogs, _logs.length);
    }
    _logStreamController.add(entry);

    if (kDebugMode) {
      debugPrint(entry.toString());
    }

    if (entry.level == LogLevel.crash || entry.level == LogLevel.error) {
      _savePersistentLogs();
    }
  }

  /// Records a debug log entry.
  void debug(String tag, String message, {Map<String, dynamic>? meta}) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        tag: tag,
        message: message,
        metadata: meta,
      ),
    );
  }

  /// Records an info log entry.
  void info(String tag, String message, {Map<String, dynamic>? meta}) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        tag: tag,
        message: message,
        metadata: meta,
      ),
    );
  }

  /// Records a warning log entry.
  void warning(
    String tag,
    String message, {
    String? stackTrace,
    Map<String, dynamic>? meta,
  }) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.warning,
        tag: tag,
        message: message,
        stackTrace: stackTrace,
        metadata: meta,
      ),
    );
  }

  /// Records an error log entry.
  void error(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? meta,
  }) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.error,
        tag: tag,
        message: '$message${error != null ? ' | Error: $error' : ''}',
        stackTrace: stackTrace?.toString(),
        metadata: meta,
      ),
    );
  }

  /// Records an uncaught exception / crash log entry.
  void crash(
    String tag,
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? meta,
  }) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.crash,
        tag: tag,
        message: 'CRASH/UNCAUGHT: $exception',
        stackTrace: stackTrace?.toString(),
        metadata: meta,
      ),
    );
  }

  /// Clears all logs from both memory and local persistent storage.
  Future<void> clearLogs() async {
    _logs.clear();
    if (_prefs != null) {
      await _prefs!.remove(_keyPersistentLogs);
    }
  }

  /// Exports the entire log history as a formatted report.
  String exportFullLogsText() {
    final buffer = StringBuffer()
      ..writeln('====================================')
      ..writeln('SPATIAL DRAFT SYSTEM DIAGNOSTICS & CRASH REPORT')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Total Log Entries: ${_logs.length}')
      ..writeln('Total Crashes/Errors: ${crashAndErrorLogs.length}')
      ..writeln('====================================\n');

    for (final log in _logs) {
      buffer
        ..writeln(log.toString())
        ..writeln('------------------------------------');
    }

    return buffer.toString();
  }
}
