import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/services/app_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogEntry Tests', () {
    test('creates and formats LogEntry correctly', () {
      final now = DateTime(2026, 9, 19, 14, 30, 45, 123);
      final entry = LogEntry(
        timestamp: now,
        level: LogLevel.crash,
        tag: 'TEST_CRASH',
        message: 'Something crashed',
        stackTrace: 'trace line 1\ntrace line 2',
      );

      expect(entry.level, LogLevel.crash);
      expect(entry.tag, 'TEST_CRASH');
      expect(entry.message, 'Something crashed');
      expect(entry.formattedTime, '14:30:45.123');
      expect(entry.formattedDate, '2026-09-19 14:30:45.123');
      expect(entry.toString(), contains('[14:30:45.123] [CRASH] [TEST_CRASH]'));
      expect(entry.toString(), contains('StackTrace:'));
    });

    test('serializes and deserializes JSON cleanly', () {
      final now = DateTime.now();
      final original = LogEntry(
        timestamp: now,
        level: LogLevel.error,
        tag: 'STORAGE',
        message: 'Failed write',
        stackTrace: 'Stack info',
        metadata: {'file': 'draft.json'},
      );

      final json = original.toJson();
      final restored = LogEntry.fromJson(json);

      expect(restored.level, LogLevel.error);
      expect(restored.tag, 'STORAGE');
      expect(restored.message, 'Failed write');
      expect(restored.stackTrace, 'Stack info');
      expect(restored.metadata?['file'], 'draft.json');
    });

    test('LogEntry handles empty/corrupted JSON gracefully', () {
      final empty = LogEntry.fromJson({});
      expect(empty.level, LogLevel.info);
      expect(empty.tag, 'APP');
      expect(empty.message, '');
    });
  });

  group('AppLogService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppLogService.instance.init();
      await AppLogService.instance.clearLogs();
    });

    test('records logs of various levels', () {
      final service = AppLogService.instance;

      service.debug('TAG_DBG', 'Debug message');
      service.info('TAG_INF', 'Info message');
      service.warning('TAG_WRN', 'Warning message');
      service.error('TAG_ERR', 'Error message', error: 'Code 404');
      service.crash('TAG_CRASH', 'Fatal boom', stackTrace: StackTrace.current);

      expect(service.logs.length, 5);
      expect(service.logs.first.level, LogLevel.crash);
      expect(service.logs.last.level, LogLevel.debug);

      final crashAndErrors = service.crashAndErrorLogs;
      expect(crashAndErrors.length, 2);
      expect(
        crashAndErrors.any((l) => l.level == LogLevel.crash),
        isTrue,
      );
      expect(
        crashAndErrors.any((l) => l.level == LogLevel.error),
        isTrue,
      );
    });

    test('broadcasts new entries on logStream', () async {
      final service = AppLogService.instance;
      final emitted = <LogEntry>[];

      final sub = service.logStream.listen(emitted.add);

      service.info('STREAM_TEST', 'Testing live stream');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.length, 1);
      expect(emitted.first.tag, 'STREAM_TEST');

      await sub.cancel();
    });

    test('respects in-memory log buffer limit', () {
      final service = AppLogService.instance;

      for (int i = 0; i < 300; i++) {
        service.info('BATCH', 'Log #$i');
      }

      expect(service.logs.length, 250);
      expect(service.logs.first.message, 'Log #299');
    });

    test('exports full report text with diagnostic headers', () {
      final service = AppLogService.instance;

      service.info('SYS', 'Boot complete');
      service.crash('SYS', 'Uncaught test crash');

      final report = service.exportFullLogsText();

      expect(report, contains('SPATIAL DRAFT SYSTEM DIAGNOSTICS & CRASH REPORT'));
      expect(report, contains('Total Log Entries: 2'));
      expect(report, contains('Total Crashes/Errors: 1'));
      expect(report, contains('Uncaught test crash'));
    });

    test('clears logs from memory and persistent storage', () async {
      final service = AppLogService.instance;

      service.info('SYS', 'Test log');
      service.crash('SYS', 'Crash log');
      expect(service.logs.length, 2);

      await service.clearLogs();
      expect(service.logs.isEmpty, isTrue);
      expect(service.crashAndErrorLogs.isEmpty, isTrue);
    });

    test('persists crash and error logs across service init calls', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final service = AppLogService.instance;
      await service.init(prefs);
      await service.clearLogs();

      service.crash('PERSIST_TEST', 'Fatal disk crash');
      service.error('PERSIST_TEST', 'Minor storage warning');
      service.info('PERSIST_TEST', 'Ephemeral info');

      // Re-initialize with same persistent storage
      await service.init(prefs);

      expect(service.logs.any((l) => l.message.contains('Fatal disk crash')),
          isTrue);
      expect(service.logs.any((l) => l.message.contains('Minor storage')),
          isTrue);
    });
  });
}
