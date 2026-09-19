import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spatial_draft/core/models/app_drill_mode.dart';
import 'package:spatial_draft/core/models/draft_capture.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/services/gallery_service.dart';

/// Screen displaying the archive of user-captured drawings and drill attempts.
class GalleryScreen extends StatefulWidget {
  /// Creates a [GalleryScreen].
  const GalleryScreen({
    super.key,
    required this.theme,
  });

  /// Theme design tokens.
  final AppThemeTokens theme;

  /// Convenience route navigator.
  static void open({
    required BuildContext context,
    required AppThemeTokens theme,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GalleryScreen(theme: theme),
      ),
    );
  }

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  AppDrillMode? _filterMode;

  void _openDetail(DraftCapture capture) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _DraftDetailDialog(
        capture: capture,
        theme: widget.theme,
        onDelete: () async {
          Navigator.of(ctx).pop();
          await _deleteCaptureWithNotice(capture);
        },
      ),
    );
  }

  Future<void> _deleteCaptureWithNotice(DraftCapture capture) async {
    final theme = widget.theme;
    await GalleryService.instance.deleteCapture(capture.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Deleted snapshot "${capture.title}"'),
        backgroundColor: theme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final theme = widget.theme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderSubtle),
        ),
        title: Text(
          'Clear All Captures?',
          style: theme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'This will permanently remove all archived snapshots from your '
          'device.',
          style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GalleryService.instance.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Cleared all gallery snapshots'),
            backgroundColor: widget.theme.accentCyan,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.canvasBackground,
      appBar: AppBar(
        backgroundColor: theme.surfaceBackground,
        foregroundColor: theme.defaultInk,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DRAFT GALLERY',
              style: theme.headingStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'Snapshot Archive & Kinematic Studies',
              style: theme.monoStyle.copyWith(
                fontSize: 10,
                color: theme.secondaryInk,
              ),
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder<List<DraftCapture>>(
            valueListenable: GalleryService.instance.capturesNotifier,
            builder: (ctx, captures, _) {
              if (captures.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear All Captures',
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.danger,
                  size: 22,
                ),
                onPressed: _confirmClearAll,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterBar(theme),
            Divider(height: 1, color: theme.borderSubtle),
            Expanded(
              child: ValueListenableBuilder<List<DraftCapture>>(
                valueListenable: GalleryService.instance.capturesNotifier,
                builder: (ctx, captures, _) {
                  final filtered = _filterMode == null
                      ? captures
                      : captures
                          .where((c) => c.drillMode == _filterMode)
                          .toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(theme, captures.isNotEmpty);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final capture = filtered[index];
                      return _CaptureCard(
                        capture: capture,
                        theme: theme,
                        onTap: () => _openDetail(capture),
                        onDelete: () => _deleteCaptureWithNotice(capture),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppThemeTokens theme) {
    return ValueListenableBuilder<List<DraftCapture>>(
      valueListenable: GalleryService.instance.capturesNotifier,
      builder: (ctx, captures, _) {
        return Container(
          color: theme.surfaceBackground,
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _buildFilterChip(
                label: 'All (${captures.length})',
                isSelected: _filterMode == null,
                theme: theme,
                onTap: () => setState(() => _filterMode = null),
              ),
              for (final mode in AppDrillMode.values)
                _buildFilterChip(
                  label: '${mode.shortLabel} ('
                      '${captures.where((c) => c.drillMode == mode).length})',
                  isSelected: _filterMode == mode,
                  theme: theme,
                  icon: mode.icon,
                  onTap: () => setState(() => _filterMode = mode),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required AppThemeTokens theme,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentCyan.withOpacity(0.18)
                : theme.surfaceBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.accentCyan : theme.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? theme.accentCyan : theme.secondaryInk,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.monoStyle.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? theme.accentCyan : theme.secondaryInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeTokens theme, bool hasOtherCaptures) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.accentCyan.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: theme.accentCyan,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasOtherCaptures
                  ? 'No Snapshots in Selected Filter'
                  : 'No Draft Snapshots Yet',
              style: theme.headingStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                hasOtherCaptures
                    ? 'Switch back to "All" or select another practice drill '
                        'tab to view other archived snapshots.'
                    : 'Use the Camera icon in the top studio bar to capture '
                        'instant high-resolution snapshots of your drawing '
                        'studies and kinematics.',
                textAlign: TextAlign.center,
                style: theme.bodyStyle.copyWith(
                  color: theme.secondaryInk,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.capture,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  final DraftCapture capture;
  final AppThemeTokens theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppThemeTokens.of(
                      capture.themeMode,
                    ).canvasBackground,
                    child: capture.pngBytes.isNotEmpty
                        ? Image.memory(
                            capture.pngBytes,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.broken_image_outlined,
                            color: theme.secondaryInk,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surfaceBackground.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            capture.drillMode.icon,
                            size: 12,
                            color: theme.accentCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            capture.drillMode.shortLabel,
                            style: theme.monoStyle.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: theme.secondaryInk,
                      ),
                      tooltip: 'Delete Snapshot',
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: theme.surfaceBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capture.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.headingStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          capture.formattedDate,
                          style: theme.monoStyle.copyWith(
                            fontSize: 9,
                            color: theme.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.canvasBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      capture.resolutionLabel,
                      style: theme.monoStyle.copyWith(
                        fontSize: 9,
                        color: theme.secondaryInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftDetailDialog extends StatelessWidget {
  const _DraftDetailDialog({
    required this.capture,
    required this.theme,
    required this.onDelete,
  });

  final DraftCapture capture;
  final AppThemeTokens theme;
  final VoidCallback onDelete;

  void _copyDetails(BuildContext context) {
    final text = 'Draft Snapshot: ${capture.title}\n'
        'Discipline: ${capture.drillMode.fullLabel}\n'
        'Timestamp: ${capture.formattedDate}\n'
        'Resolution: ${capture.resolutionLabel}\n'
        'Projection: ${capture.gridType.name}\n'
        'Theme: ${capture.themeMode.name}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Snapshot details copied to clipboard'),
        backgroundColor: theme.accentCyan,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: theme.canvasBackground,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: capture.pngBytes.isNotEmpty
                        ? Image.memory(
                            capture.pngBytes,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: theme.secondaryInk,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surfaceBackground.withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(color: theme.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        capture.drillMode.icon,
                        color: theme.accentCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capture.title,
                              style: theme.headingStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${capture.drillMode.fullLabel} • '
                              '${capture.formattedDate}',
                              style: theme.monoStyle.copyWith(
                                fontSize: 10,
                                color: theme.secondaryInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Technical Details',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        color: theme.defaultInk,
                        onPressed: () => _copyDetails(context),
                      ),
                      IconButton(
                        tooltip: 'Delete Snapshot',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: theme.danger,
                        ),
                        onPressed: onDelete,
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: theme.defaultInk,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surfaceBackground.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pinch / Scroll to Zoom & Pan',
                          style: theme.monoStyle.copyWith(
                            fontSize: 11,
                            color: theme.secondaryInk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.secondaryInk,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          capture.resolutionLabel,
                          style: theme.monoStyle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
