import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/services/app_log_service.dart';
import 'package:spatial_draft/views/diagnostics/crash_report_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLogService.instance.init();
    await AppLogService.instance.clearLogs();
  });

  Widget createTestWidget() {
    final theme = AppThemeTokens.of(AppThemeMode.dark);
    return MaterialApp(
      home: CrashReportScreen(theme: theme),
    );
  }

  testWidgets('renders empty state when no logs exist', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('DIAGNOSTICS & CRASH LOGS'), findsOneWidget);
    expect(find.text('No matching logs found'), findsOneWidget);
    expect(find.text('TOTAL'), findsOneWidget);
  });

  testWidgets('displays recorded log entries and expands stack trace',
      (tester) async {
    final service = AppLogService.instance;
    service.crash(
      'RENDER_ENGINE',
      'Segmentation fault in canvas buffer',
      stackTrace: StackTrace.fromString('line 1: canvas.dart:42'),
    );
    service.info('NETWORK', 'Connected to sync node');

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('RENDER_ENGINE'), findsOneWidget);
    expect(find.text('NETWORK'), findsOneWidget);
    expect(
      find.textContaining('Segmentation fault in canvas buffer'),
      findsOneWidget,
    );
    expect(find.text('View Stack Trace'), findsOneWidget);

    // Expand stack trace
    await tester.tap(find.text('View Stack Trace'));
    await tester.pumpAndSettle();

    expect(find.text('Hide Stack Trace'), findsOneWidget);
    expect(find.textContaining('line 1: canvas.dart:42'), findsOneWidget);
  });

  testWidgets('filter chips filter logs by severity level', (tester) async {
    final service = AppLogService.instance;
    service.crash('CRASH_TAG', 'Crash occurred');
    service.error('ERROR_TAG', 'Error occurred');
    service.info('INFO_TAG', 'Info occurred');

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('CRASH_TAG'), findsOneWidget);
    expect(find.text('ERROR_TAG'), findsOneWidget);
    expect(find.text('INFO_TAG'), findsOneWidget);

    // Tap CRASHES chip
    await tester.tap(find.widgetWithText(InkWell, 'CRASHES'));
    await tester.pumpAndSettle();

    expect(find.text('CRASH_TAG'), findsOneWidget);
    expect(find.text('ERROR_TAG'), findsNothing);
    expect(find.text('INFO_TAG'), findsNothing);

    // Tap ALL chip to restore
    await tester.tap(find.widgetWithText(InkWell, 'ALL'));
    await tester.pumpAndSettle();

    expect(find.text('CRASH_TAG'), findsOneWidget);
    expect(find.text('ERROR_TAG'), findsOneWidget);
    expect(find.text('INFO_TAG'), findsOneWidget);
  });

  testWidgets('search query filters logs by message or tag', (tester) async {
    final service = AppLogService.instance;
    service.info('DATABASE', 'Loaded 50 cached drills');
    service.info('AUDIO', 'Playing haptic impact');

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('DATABASE'), findsOneWidget);
    expect(find.text('AUDIO'), findsOneWidget);

    // Type 'haptic' into search field
    await tester.enterText(find.byType(TextField), 'haptic');
    await tester.pumpAndSettle();

    expect(find.text('DATABASE'), findsNothing);
    expect(find.text('AUDIO'), findsOneWidget);
  });

  testWidgets('trigger test error records a new diagnostic error',
      (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('DIAGNOSTICS_TEST'), findsNothing);

    // Tap the bug report button
    await tester.tap(find.byTooltip('Trigger Test Error'));
    await tester.pumpAndSettle();

    expect(find.text('DIAGNOSTICS_TEST'), findsOneWidget);
    expect(
      find.textContaining('User-initiated diagnostic probe'),
      findsOneWidget,
    );
  });

  testWidgets('clear logs shows confirmation dialog and clears logs',
      (tester) async {
    final service = AppLogService.instance;
    service.info('LOG', 'Temporary log');

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('LOG'), findsOneWidget);

    // Tap delete sweep icon
    await tester.tap(find.byTooltip('Clear Logs'));
    await tester.pumpAndSettle();

    expect(find.text('Clear Diagnostics & Crash Logs?'), findsOneWidget);

    // Confirm clear
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    expect(find.text('No matching logs found'), findsOneWidget);
    expect(service.logs.isEmpty, isTrue);
  });
}
