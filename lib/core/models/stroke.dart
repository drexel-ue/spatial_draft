import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';

enum LineWeightType {
  silhouette, // Thick outer contour (1.2mm / ~3.0px)
  crease,     // Medium interior edge (0.6mm / ~1.8px)
  hidden,     // Thin dashed line for hidden geometry (0.3mm / ~1.0px)
  dimension,  // Faint hairline guide (0.2mm / ~0.7px)
}

extension LineWeightTypeExt on LineWeightType {
  double get baseWidth {
    switch (this) {
      case LineWeightType.silhouette:
        return 3.5;
      case LineWeightType.crease:
        return 2.0;
      case LineWeightType.hidden:
        return 1.2;
      case LineWeightType.dimension:
        return 0.8;
    }
  }

  bool get isDashed => this == LineWeightType.hidden;

  String get label {
    switch (this) {
      case LineWeightType.silhouette:
        return 'Silhouette (Thick)';
      case LineWeightType.crease:
        return 'Crease (Medium)';
      case LineWeightType.hidden:
        return 'Hidden (Dashed)';
      case LineWeightType.dimension:
        return 'Guide (Hairline)';
    }
  }
}

class Stroke {
  Stroke({
    required List<StrokePoint> points,
    required this.color,
    this.lineWeight = LineWeightType.crease,
    this.segmentColors,
    this.planeId = 'plane_primary',
  }) : points = List.unmodifiable(points);

  /// Deserializes a [Stroke] from a JSON map.
  factory Stroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? <dynamic>[];
    final pts = rawPoints
        .whereType<Map<String, dynamic>>()
        .map(StrokePoint.fromJson)
        .toList();

    final colorVal = (json['color'] as num?)?.toInt() ?? 0xFFFFFFFF;
    final weightStr = json['weight'] as String? ?? 'crease';
    final weight = LineWeightType.values.firstWhere(
      (w) => w.name == weightStr,
      orElse: () => LineWeightType.crease,
    );
    final plane = json['planeId'] as String? ?? 'plane_primary';

    return Stroke(
      points: pts,
      color: Color(colorVal),
      lineWeight: weight,
      planeId: plane,
    );
  }

  final List<StrokePoint> points;
  final Color color;
  final LineWeightType lineWeight;
  final List<Color>? segmentColors;

  /// The 3D spatial canvas plane this stroke resides on.
  final String planeId;

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'points': points.map((p) => p.toJson()).toList(),
        'color': color.value,
        'weight': lineWeight.name,
        'planeId': planeId,
      };

  bool get isEmpty => points.isEmpty;
  int get length => points.length;

  StrokePoint? get first => points.isNotEmpty ? points.first : null;
  StrokePoint? get last => points.isNotEmpty ? points.last : null;

  /// Total duration of the stroke in milliseconds
  double get durationMs {
    if (points.length < 2) return 0.0;
    return (points.last.timestampMicros - points.first.timestampMicros) / 1000.0;
  }

  /// Total physical path length in canvas pixels
  double get totalLength {
    if (points.length < 2) return 0.0;
    double dist = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      dist += (points[i + 1].position - points[i].position).distance;
    }
    return dist;
  }

  /// Average velocity in pixels per millisecond
  double get averageVelocity {
    final dur = durationMs;
    if (dur <= 0.0) return 0.0;
    return totalLength / dur;
  }

  /// Returns a smoothed Path connecting all stroke points
  Path toSmoothedPath() {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points.first.position, radius: lineWeight.baseWidth / 2));
      return path;
    }

    path.moveTo(points.first.position.dx, points.first.position.dy);

    if (points.length == 2) {
      path.lineTo(points[1].position.dx, points[1].position.dy);
      return path;
    }

    // Midpoint quadratic Bezier smoothing for silky, low-latency ink
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i].position;
      final p1 = points[i + 1].position;
      final midPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);

      if (i == 0) {
        path.lineTo(midPoint.dx, midPoint.dy);
      } else {
        path.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
      }
    }

    path.lineTo(points.last.position.dx, points.last.position.dy);
    return path;
  }

  /// Extracts dashed path segments for hidden lines
  Path toDashedPath({double dashLength = 8.0, double dashSpace = 5.0}) {
    final smoothed = toSmoothedPath();
    final dashed = Path();
    for (final metric in smoothed.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : dashSpace;
        if (draw) {
          dashed.addPath(
            metric.extractPath(distance, (distance + length).clamp(0.0, metric.length)),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashed;
  }
}
