import 'dart:convert';
import 'dart:typed_data';

import 'package:spatial_draft/core/models/app_drill_mode.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Represents a single captured draft snapshot from the interactive canvas.
class DraftCapture {
  /// Creates a [DraftCapture] instance.
  const DraftCapture({
    required this.id,
    required this.title,
    required this.drillMode,
    required this.themeMode,
    required this.gridStyle,
    required this.gridType,
    required this.timestamp,
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  /// Deserializes a [DraftCapture] from a JSON map.
  factory DraftCapture.fromJson(Map<String, dynamic> json) {
    final base64String = json['pngBytes'] as String? ?? '';
    final bytes = base64String.isNotEmpty
        ? base64Decode(base64String)
        : Uint8List(0);

    return DraftCapture(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Draft Snapshot',
      drillMode: AppDrillMode.values.firstWhere(
        (m) => m.name == json['drillMode'],
        orElse: () => AppDrillMode.ghosting,
      ),
      themeMode: AppThemeMode.values.firstWhere(
        (t) => t.name == json['themeMode'],
        orElse: () => AppThemeMode.dark,
      ),
      gridStyle: GridStyle.values.firstWhere(
        (g) => g.name == json['gridStyle'],
        orElse: () => GridStyle.solid,
      ),
      gridType: GridType.values.firstWhere(
        (g) => g.name == json['gridType'],
        orElse: () => GridType.squareMetric,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      pngBytes: bytes,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
    );
  }

  /// Unique identifier for this capture.
  final String id;

  /// User-facing descriptive title.
  final String title;

  /// Practice drill or mode active when captured.
  final AppDrillMode drillMode;

  /// Studio color theme active during capture.
  final AppThemeMode themeMode;

  /// Grid line styling active during capture.
  final GridStyle gridStyle;

  /// Grid projection system active during capture.
  final GridType gridType;

  /// Timestamp when snapshot was created.
  final DateTime timestamp;

  /// Raw PNG image byte payload.
  final Uint8List pngBytes;

  /// Pixel width of the rendered snapshot.
  final int width;

  /// Pixel height of the rendered snapshot.
  final int height;

  /// Formatted date string for UI display.
  String get formattedDate {
    final local = timestamp.toLocal();
    final year = local.year;
    final month = _monthName(local.month);
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year • $hour:$minute $period';
  }

  /// Formatted resolution label (e.g. 1920 × 1080 px).
  String get resolutionLabel => '$width × $height px';

  /// Serializes this capture to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'drillMode': drillMode.name,
      'themeMode': themeMode.name,
      'gridStyle': gridStyle.name,
      'gridType': gridType.name,
      'timestamp': timestamp.toIso8601String(),
      'pngBytes': base64Encode(pngBytes),
      'width': width,
      'height': height,
    };
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
