import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/services/svg_export_service.dart';

void main() {
  group('SvgExportService Unit Tests', () {
    test('exports empty stroke list with valid SVG header and wrapper', () {
      final svg = SvgExportService.exportToSvg(
        strokes: const [],
        title: 'Empty Drafting Canvas',
      );

      expect(svg, contains('<?xml version="1.0" encoding="UTF-8"'));
      expect(svg, contains('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('<title>Empty Drafting Canvas</title>'));
      expect(svg, contains('</svg>'));
    });

    test('exports single dot stroke as SVG circle element', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(
            position: Offset(150, 250),
            pressure: 0.5,
            timestampMicros: 0,
          ),
        ],
        color: const Color(0xFFFF5500),
        lineWeight: LineWeightType.silhouette,
      );

      final svg = SvgExportService.exportToSvg(
        strokes: [stroke],
        title: 'Dot Test',
      );

      expect(svg, contains('<circle'));
      expect(svg, contains('cx="150.00"'));
      expect(svg, contains('cy="250.00"'));
      expect(svg, contains('fill="#FF5500"'));
    });

    test('exports multi-point stroke as quadratic Bezier SVG path', () {
      const points = [
        StrokePoint(
          position: Offset(100, 100),
          pressure: 0.5,
          timestampMicros: 0,
        ),
        StrokePoint(
          position: Offset(150, 120),
          pressure: 0.6,
          timestampMicros: 16000,
        ),
        StrokePoint(
          position: Offset(200, 110),
          pressure: 0.7,
          timestampMicros: 32000,
        ),
        StrokePoint(
          position: Offset(250, 100),
          pressure: 0.8,
          timestampMicros: 48000,
        ),
      ];

      final stroke = Stroke(
        points: points,
        color: const Color(0xFF00AAFF),
        lineWeight: LineWeightType.crease,
      );

      final svg = SvgExportService.exportToSvg(
        strokes: [stroke],
        title: 'Bezier Path Test',
      );

      expect(svg, contains('<path d="M 100.00 100.00 Q'));
      expect(svg, contains('stroke="#00AAFF"'));
      expect(svg, contains('stroke-width="'));
    });

    test('applies dashed stroke attribute for hidden line weight', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(
            position: Offset(50, 50),
            pressure: 0.5,
            timestampMicros: 0,
          ),
          StrokePoint(
            position: Offset(150, 50),
            pressure: 0.5,
            timestampMicros: 1000,
          ),
        ],
        color: const Color(0xFFFFFFFF),
        lineWeight: LineWeightType.hidden,
      );

      final svg = SvgExportService.exportToSvg(
        strokes: [stroke],
      );

      expect(svg, contains('stroke-dasharray="6,4"'));
    });

    test('renders background rect when backgroundColor is provided', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(
            position: Offset(100, 100),
            pressure: 0.5,
            timestampMicros: 0,
          ),
          StrokePoint(
            position: Offset(200, 200),
            pressure: 0.5,
            timestampMicros: 1000,
          ),
        ],
        color: Colors.white,
      );

      final svg = SvgExportService.exportToSvg(
        strokes: [stroke],
        backgroundColor: const Color(0xFF0F172A),
      );

      expect(svg, contains('<rect'));
      expect(svg, contains('fill="#0F172A"'));
    });
  });
}
