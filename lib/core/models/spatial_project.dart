import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Available creative studio modes in the drafting sandbox.
enum SandboxMode {
  /// Classic high-precision 2D technical drafting vellum.
  vellum2D(
    label: '2D Technical Vellum',
    shortLabel: '2D Vellum',
    description: 'Precision engineering drafting with calibrated grids.',
    icon: Icons.architecture_rounded,
  ),

  /// Multi-scale deep zoom art canvas (Endless Paper style).
  infiniteZoom(
    label: 'Deep Infinite Zoom',
    shortLabel: 'Deep Zoom',
    description: 'Logarithmic multi-scale vector canvas across magnitudes.',
    icon: Icons.zoom_in_map_rounded,
  ),

  /// 3D spatial drawing planes with orbital camera parallax (Mental Canvas).
  mentalCanvas3D(
    label: 'Mental Canvas (3D Parallax)',
    shortLabel: '3D Spatial',
    description: '2D sketches mapped onto 3D planes with motion parallax.',
    icon: Icons.view_in_ar_rounded,
  );

  SandboxMode({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
  });

  /// Full descriptive title.
  final String label;

  /// Compact chip label.
  final String shortLabel;

  /// Pedagogical/feature description.
  final String description;

  /// Identifying UI icon.
  final IconData icon;
}

/// Represents an editable, persistent creative project in the drafting sandbox.
class SpatialProject {
  /// Creates a [SpatialProject].
  const SpatialProject({
    required this.id,
    required this.title,
    this.mode = SandboxMode.vellum2D,
    required this.createdAt,
    required this.updatedAt,
    this.strokes = const <Stroke>[],
    this.gridType = GridType.squareMetric,
    this.gridStyle = GridStyle.solid,
    this.thumbnailBase64,
    this.zoomScale = 1.0,
    this.panOffsetX = 0.0,
    this.panOffsetY = 0.0,
  });

  /// Deserializes a [SpatialProject] from a JSON map.
  factory SpatialProject.fromJson(Map<String, dynamic> json) {
    final modeString = json['mode'] as String? ?? 'vellum2D';
    final parsedMode = SandboxMode.values.firstWhere(
      (m) => m.name == modeString,
      orElse: () => SandboxMode.vellum2D,
    );

    final gridTypeStr = json['gridType'] as String? ?? 'squareMetric';
    final parsedGridType = GridType.values.firstWhere(
      (GridType g) => g.name == gridTypeStr,
      orElse: () => GridType.squareMetric,
    );

    final gridStyleStr = json['gridStyle'] as String? ?? 'solid';
    final parsedGridStyle = GridStyle.values.firstWhere(
      (GridStyle s) => s.name == gridStyleStr,
      orElse: () => GridStyle.solid,
    );

    final rawStrokes = json['strokes'] as List<dynamic>? ?? <dynamic>[];
    final parsedStrokes = rawStrokes
        .whereType<Map<String, dynamic>>()
        .map(Stroke.fromJson)
        .toList();

    return SpatialProject(
      id: json['id'] as String? ?? UniqueKey().toString(),
      title: json['title'] as String? ?? 'Untitled Draft',
      mode: parsedMode,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      strokes: parsedStrokes,
      gridType: parsedGridType,
      gridStyle: parsedGridStyle,
      thumbnailBase64: json['thumbnailBase64'] as String?,
      zoomScale: (json['zoomScale'] as num?)?.toDouble() ?? 1.0,
      panOffsetX: (json['panOffsetX'] as num?)?.toDouble() ?? 0.0,
      panOffsetY: (json['panOffsetY'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Unique identifier.
  final String id;

  /// User-defined project title.
  final String title;

  /// Creative mode.
  final SandboxMode mode;

  /// Timestamp when created.
  final DateTime createdAt;

  /// Timestamp when last modified.
  final DateTime updatedAt;

  /// All vector strokes belonging to this project.
  final List<Stroke> strokes;

  /// Background grid projection.
  final GridType gridType;

  /// Background grid pattern style.
  final GridStyle gridStyle;

  /// Optional base64 encoded PNG thumbnail for fast card previews.
  final String? thumbnailBase64;

  /// Last active viewport zoom scale.
  final double zoomScale;

  /// Last active viewport horizontal pan offset.
  final double panOffsetX;

  /// Last active viewport vertical pan offset.
  final double panOffsetY;

  /// Serializes the project into a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'mode': mode.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'gridType': gridType.name,
      'gridStyle': gridStyle.name,
      'thumbnailBase64': thumbnailBase64,
      'zoomScale': zoomScale,
      'panOffsetX': panOffsetX,
      'panOffsetY': panOffsetY,
    };
  }

  /// Formatted date string for UI display.
  String get formattedDate {
    final months = [
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
    final m = months[updatedAt.month - 1];
    final d = updatedAt.day;
    final y = updatedAt.year;
    final hr = updatedAt.hour.toString().padLeft(2, '0');
    final min = updatedAt.minute.toString().padLeft(2, '0');
    return '$m $d, $y • $hr:$min';
  }

  /// Total stroke count label.
  String get strokeCountLabel {
    final count = strokes.length;
    return count == 1 ? '1 stroke' : '$count strokes';
  }

  /// Creates a copy of this project with optional field replacements.
  SpatialProject copyWith({
    String? id,
    String? title,
    SandboxMode? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Stroke>? strokes,
    GridType? gridType,
    GridStyle? gridStyle,
    String? thumbnailBase64,
    double? zoomScale,
    double? panOffsetX,
    double? panOffsetY,
  }) {
    return SpatialProject(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      strokes: strokes ?? this.strokes,
      gridType: gridType ?? this.gridType,
      gridStyle: gridStyle ?? this.gridStyle,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      zoomScale: zoomScale ?? this.zoomScale,
      panOffsetX: panOffsetX ?? this.panOffsetX,
      panOffsetY: panOffsetY ?? this.panOffsetY,
    );
  }

  /// Serializes to a formatted JSON string for native file export.
  String toExportJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}
