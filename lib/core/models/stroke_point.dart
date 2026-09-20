import 'package:flutter/material.dart';

class StrokePoint {
  const StrokePoint({
    required this.position,
    this.pressure = 0.5,
    this.tilt = 0.0,
    required this.timestampMicros,
  });

  /// Deserializes a [StrokePoint] from a JSON map.
  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0.0,
        (json['y'] as num?)?.toDouble() ?? 0.0,
      ),
      pressure: (json['p'] as num?)?.toDouble() ?? 0.5,
      tilt: (json['t'] as num?)?.toDouble() ?? 0.0,
      timestampMicros: (json['time'] as num?)?.toInt() ?? 0,
    );
  }

  final Offset position;
  final double pressure; // 0.0 to 1.0
  final double tilt; // radians from perpendicular
  final int timestampMicros;

  /// Serializes to a compact JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'x': position.dx,
        'y': position.dy,
        'p': pressure,
        't': tilt,
        'time': timestampMicros,
      };

  StrokePoint copyWith({
    Offset? position,
    double? pressure,
    double? tilt,
    int? timestampMicros,
  }) {
    return StrokePoint(
      position: position ?? this.position,
      pressure: pressure ?? this.pressure,
      tilt: tilt ?? this.tilt,
      timestampMicros: timestampMicros ?? this.timestampMicros,
    );
  }
}
