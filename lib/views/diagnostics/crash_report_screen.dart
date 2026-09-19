import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/services/app_log_service.dart';

/// Screen displaying runtime diagnostic logs, errors, and system crashes.
class CrashReportScreen extends StatefulWidget {
  /// Creates a [CrashReportScreen].
  const CrashReportScreen({
    super.key,
    required this.theme,
  });

  /// Visual theme tokens.
  final AppThemeTokens theme;

  /// Convenience route opener.
  static void open({
    required BuildContext context,
    required AppThemeTokens theme,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CrashReportScreen(theme: theme),
      ),
    );
  }

  @override
  State<CrashReportScreen> createState() => _CrashReportScreenState();
}

class _CrashReportScreenState extends State<CrashReportScreen> {
  LogLevel? _filterLevel;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyAllLogs() {
    final text = AppLogService.instance.exportFullLogsText();
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Full diagnostics log copied to clipboard'),
        backgroundColor: widget.theme.accentCyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copySingleLog(LogEntry entry) {
    Clipboard.setData(ClipboardData(text: entry.toString()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Copied [${entry.tag}] entry to clipboard'),
        backgroundColor: widget.theme.accentAmber,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearLogs() async {
    final theme = widget.theme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderSubtle),
        ),
        title: Text(
          'Clear Diagnostics & Crash Logs?',
          style: theme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'This will delete all recorded runtime messages and crash traces '
          'from memory and local persistent storage.',
          style: theme.bodyStyle.copyWith(
            fontSize: 13,
            color: theme.secondaryInk,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.secondaryInk),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppLogService.instance.clearLogs();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ All diagnostic logs cleared'),
            backgroundColor: theme.accentAmber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _triggerTestException() {
    AppLogService.instance.error(
      'DIAGNOSTICS_TEST',
      'User-initiated diagnostic probe to verify error tracking.',
      error: 'TestException: Manual telemetry validation',
      stackTrace: StackTrace.current,
    );
    setState(() {});
  }

  Color _levelColor(LogLevel level, AppThemeTokens theme) {
    switch (level) {
      case LogLevel.crash:
        return const Color(0xFFEF4444);
      case LogLevel.error:
        return theme.warning;
      case LogLevel.warning:
        return theme.accentAmber;
      case LogLevel.info:
        return theme.accentCyan;
      case LogLevel.debug:
        return theme.secondaryInk;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final allLogs = AppLogService.instance.logs;

    final filteredLogs = allLogs.where((log) {
      if (_filterLevel != null && log.level != _filterLevel) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTag = log.tag.toLowerCase().contains(q);
        final matchMsg = log.message.toLowerCase().contains(q);
        return matchTag || matchMsg;
      }
      return true;
    }).toList();

    final crashCount =
        allLogs.where((l) => l.level == LogLevel.crash).length;
    final errorCount =
        allLogs.where((l) => l.level == LogLevel.error).length;
    final warnCount =
        allLogs.where((l) => l.level == LogLevel.warning).length;

    return Scaffold(
      backgroundColor: theme.canvasBackground,
      appBar: AppBar(
        backgroundColor: theme.surfaceBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.defaultInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DIAGNOSTICS & CRASH LOGS',
              style: theme.monoStyle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: theme.accentCyan,
              ),
            ),
            Text(
              'Local Runtime Telemetry',
              style: theme.headingStyle.copyWith(fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Trigger Test Error',
            icon: Icon(
              Icons.bug_report_rounded,
              color: theme.warning,
              size: 20,
            ),
            onPressed: _triggerTestException,
          ),
          IconButton(
            tooltip: 'Copy Full Report',
            icon: Icon(
              Icons.copy_all_rounded,
              color: theme.accentAmber,
              size: 20,
            ),
            onPressed: _copyAllLogs,
          ),
          IconButton(
            tooltip: 'Clear Logs',
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: theme.secondaryInk,
              size: 20,
            ),
            onPressed: _clearLogs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surfaceBackground,
              border: Border(
                bottom: BorderSide(color: theme.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                _SummaryKpi(
                  label: 'CRASHES',
                  count: crashCount,
                  color: const Color(0xFFEF4444),
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _SummaryKpi(
                  label: 'ERRORS',
                  count: errorCount,
                  color: theme.warning,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _SummaryKpi(
                  label: 'WARNINGS',
                  count: warnCount,
                  color: theme.accentAmber,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _SummaryKpi(
                  label: 'TOTAL',
                  count: allLogs.length,
                  color: theme.accentCyan,
                  theme: theme,
                ),
              ],
            ),
          ),

          // Search & Filter Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surfaceBackground,
              border: Border(
                bottom: BorderSide(color: theme.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.canvasBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderSubtle),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: theme.bodyStyle.copyWith(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Filter by tag or message...',
                        hintStyle: theme.bodyStyle.copyWith(
                          fontSize: 12,
                          color: theme.secondaryInk,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: theme.secondaryInk,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'ALL',
                  selected: _filterLevel == null,
                  theme: theme,
                  onTap: () => setState(() => _filterLevel = null),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'CRASHES',
                  selected: _filterLevel == LogLevel.crash,
                  color: const Color(0xFFEF4444),
                  theme: theme,
                  onTap: () => setState(() => _filterLevel = LogLevel.crash),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'ERRORS',
                  selected: _filterLevel == LogLevel.error,
                  color: theme.warning,
                  theme: theme,
                  onTap: () => setState(() => _filterLevel = LogLevel.error),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'WARNINGS',
                  selected: _filterLevel == LogLevel.warning,
                  color: theme.accentAmber,
                  theme: theme,
                  onTap: () => setState(() => _filterLevel = LogLevel.warning),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'INFO',
                  selected: _filterLevel == LogLevel.info,
                  color: theme.accentCyan,
                  theme: theme,
                  onTap: () => setState(() => _filterLevel = LogLevel.info),
                ),
              ],
            ),
          ),

          // Log Entries List
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 48,
                          color: theme.success,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No matching logs found',
                          style: theme.headingStyle.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Telemetry is quiet and no matching errors occurred.',
                          style: theme.bodyStyle.copyWith(
                            fontSize: 12,
                            color: theme.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLogs.length,
                    itemBuilder: (ctx, idx) {
                      final entry = filteredLogs[idx];
                      return _LogCard(
                        entry: entry,
                        color: _levelColor(entry.level, theme),
                        theme: theme,
                        onCopy: () => _copySingleLog(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({
    required this.label,
    required this.count,
    required this.color,
    required this.theme,
  });

  final String label;
  final int count;
  final Color color;
  final AppThemeTokens theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.monoStyle.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: theme.headingStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.defaultInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final AppThemeTokens theme;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? theme.accentCyan;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? chipColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? chipColor : theme.borderSubtle,
            width: 1.1,
          ),
        ),
        child: Text(
          label,
          style: theme.monoStyle.copyWith(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? chipColor : theme.secondaryInk,
          ),
        ),
      ),
    );
  }
}

class _LogCard extends StatefulWidget {
  const _LogCard({
    required this.entry,
    required this.color,
    required this.theme,
    required this.onCopy,
  });

  final LogEntry entry;
  final Color color;
  final AppThemeTokens theme;
  final VoidCallback onCopy;

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = widget.theme;
    final color = widget.color;
    final hasTrace = entry.stackTrace != null && entry.stackTrace!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    entry.level.name.toUpperCase(),
                    style: theme.monoStyle.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.tag,
                  style: theme.monoStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.defaultInk,
                  ),
                ),
                const Spacer(),
                Text(
                  entry.formattedTime,
                  style: theme.monoStyle.copyWith(
                    fontSize: 10,
                    color: theme.secondaryInk,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: theme.secondaryInk,
                  ),
                  tooltip: 'Copy Log Entry',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onCopy,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              entry.message,
              style: theme.bodyStyle.copyWith(
                fontSize: 12,
                color: theme.defaultInk,
              ),
            ),
            if (hasTrace) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: theme.accentAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'Hide Stack Trace' : 'View Stack Trace',
                      style: theme.monoStyle.copyWith(
                        fontSize: 10,
                        color: theme.accentAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_expanded)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.canvasBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.borderSubtle),
                  ),
                  child: SelectableText(
                    entry.stackTrace!,
                    style: theme.monoStyle.copyWith(
                      fontSize: 9,
                      color: theme.secondaryInk,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
