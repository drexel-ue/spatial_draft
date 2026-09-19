import 'package:flutter/material.dart';

class StrokePoint {

  const StrokePoint({
    required this.position,
    this.pressure = 0.5,
    this.tilt = 0.0,
    required this.timestampMicros,
  });
  final Offset position;
  final double pressure; // 0.0 to 1.0
  final double tilt;     // radians from perpendicular
  final int timestampMicros;

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
