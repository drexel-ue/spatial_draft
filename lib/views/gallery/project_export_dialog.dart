import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/services/svg_export_service.dart';
import 'package:spatial_draft/views/gallery/interactive_3d_html_exporter.dart';

/// Modal dialog allowing users to export a project as SVG or Native JSON.
class ProjectExportDialog extends StatefulWidget {
  /// Creates a [ProjectExportDialog].
  const ProjectExportDialog({
    super.key,
    required this.project,
    required this.theme,
  });

  /// The project to export.
  final SpatialProject project;

  /// Active theme design tokens.
  final AppThemeTokens theme;

  /// Convenience show method.
  static Future<void> show({
    required BuildContext context,
    required SpatialProject project,
    required AppThemeTokens theme,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ProjectExportDialog(
        project: project,
        theme: theme,
      ),
    );
  }

  @override
  State<ProjectExportDialog> createState() => _ProjectExportDialogState();
}

enum _ExportFormat {
  svg(
    'Vector SVG (.svg)',
    'Resolution-independent paths for CAD & Illustrator',
    Icons.polyline_rounded,
  ),
  spatialJson(
    'Native Project (.spatial)',
    'Full vector scene graph with layers & camera',
    Icons.data_object_rounded,
  ),
  interactiveHtml(
    'Interactive 3D Web (.html)',
    'Standalone browser turntable viewer with zero install',
    Icons.view_in_ar_rounded,
  );

  _ExportFormat(this.label, this.subtitle, this.icon);
  final String label;
  final String subtitle;
  final IconData icon;
}

class _ProjectExportDialogState extends State<ProjectExportDialog> {
  _ExportFormat _format = _ExportFormat.svg;
  late final TextEditingController _nameController;
  bool _includeBackground = false;

  @override
  void initState() {
    super.initState();
    final sanitized = widget.project.title
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_]+'), '_')
        .replaceAll(RegExp('_+'), '_');
    _nameController = TextEditingController(
      text: sanitized.isNotEmpty ? sanitized : 'draft_export',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _currentExtension {
    switch (_format) {
      case _ExportFormat.svg:
        return '.svg';
      case _ExportFormat.spatialJson:
        return '.spatial';
      case _ExportFormat.interactiveHtml:
        return '.html';
    }
  }

  Future<void> _handleExport() async {
    final filename = '${_nameController.text.trim()}$_currentExtension';
    final theme = widget.theme;

    String exportPayload;
    switch (_format) {
      case _ExportFormat.svg:
        exportPayload = SvgExportService.exportToSvg(
          strokes: widget.project.strokes,
          title: widget.project.title,
          backgroundColor: _includeBackground ? theme.canvasBackground : null,
        );
        break;
      case _ExportFormat.spatialJson:
        exportPayload = widget.project.toExportJson();
        break;
      case _ExportFormat.interactiveHtml:
        exportPayload = Interactive3dHtmlExporter.generateHtml(widget.project);
        break;
    }

    await Clipboard.setData(ClipboardData(text: exportPayload));

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Copied $filename (${exportPayload.length} bytes) to clipboard',
        ),
        backgroundColor: theme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return AlertDialog(
      backgroundColor: theme.surfaceBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.borderSubtle, width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.borderHighlight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.ios_share_rounded,
              color: theme.borderHighlight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Export Draft Document',
            style: theme.headingStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export "${widget.project.title}" '
              '(${widget.project.strokeCountLabel}) '
              'into vector or native drafting formats.',
              style: theme.bodyStyle.copyWith(
                fontSize: 13,
                color: theme.secondaryInk,
              ),
            ),
            const SizedBox(height: 16),

            // Filename input
            Text(
              'FILE EXPORT NAME',
              style: theme.monoStyle.copyWith(
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: theme.secondaryInk,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: theme.monoStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.defaultInk,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.canvasBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                suffixText: _currentExtension,
                suffixStyle: theme.monoStyle.copyWith(
                  color: theme.borderHighlight,
                  fontWeight: FontWeight.w700,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: theme.borderHighlight,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Format Selection Cards
            Text(
              'SELECT FORMAT',
              style: theme.monoStyle.copyWith(
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: theme.secondaryInk,
              ),
            ),
            const SizedBox(height: 8),

            ..._ExportFormat.values.map((fmt) {
              final isSelected = _format == fmt;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _format = fmt),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.borderHighlight.withOpacity(0.1)
                          : theme.canvasBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.borderHighlight
                            : theme.borderSubtle,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          fmt.icon,
                          color: isSelected
                              ? theme.borderHighlight
                              : theme.secondaryInk,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fmt.label,
                                style: theme.headingStyle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.defaultInk,
                                ),
                              ),
                              Text(
                                fmt.subtitle,
                                style: theme.bodyStyle.copyWith(
                                  fontSize: 11,
                                  color: theme.secondaryInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.borderHighlight,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (_format == _ExportFormat.svg) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Checkbox(
                    value: _includeBackground,
                    activeColor: theme.borderHighlight,
                    onChanged: (val) {
                      setState(() => _includeBackground = val ?? false);
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Include theme canvas background color in SVG',
                      style: theme.bodyStyle.copyWith(
                        fontSize: 12,
                        color: theme.secondaryInk,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.borderHighlight,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
          ),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy File Code'),
          onPressed: _handleExport,
        ),
      ],
    );
  }
}
