import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spatial_draft/canvas/mental_canvas/mental_canvas_painter.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Interactive viewport for 3D multi-plane sketching & turntable orbiting.
class MentalCanvasViewport extends StatefulWidget {
  /// Creates a [MentalCanvasViewport].
  const MentalCanvasViewport({
    super.key,
    required this.theme,
    required this.planes,
    required this.activePlaneId,
    required this.strokes,
    this.currentLineWeight = LineWeightType.crease,
    this.currentBrushStyle = LineBrushStyle.ink,
    this.overrideInkColor,
    required this.cameraYaw,
    required this.cameraPitch,
    this.cameraDistance = 900.0,
    required this.onStrokeCompleted,
    required this.onCameraChanged,
  });

  /// Design theme tokens.
  final AppThemeTokens theme;

  /// All spatial 3D planes.
  final List<CanvasPlane3D> planes;

  /// Active plane ID receiving vector strokes.
  final String activePlaneId;

  /// Completed strokes in document.
  final List<Stroke> strokes;

  /// Active line weight.
  final LineWeightType currentLineWeight;

  /// Active brush style (ink outline vs. cel wash).
  final LineBrushStyle currentBrushStyle;

  /// Optional ink color override.
  final Color? overrideInkColor;

  /// Camera orbital yaw angle (radians).
  final double cameraYaw;

  /// Camera orbital pitch tilt (radians).
  final double cameraPitch;

  /// Camera focal distance.
  final double cameraDistance;

  /// Callback when a 3D stroke is drawn and finalized.
  final ValueChanged<Stroke> onStrokeCompleted;

  /// Callback when two-finger orbit / pinch gestures change camera.
  final void Function(
    double yaw,
    double pitch,
    double distance,
  ) onCameraChanged;

  @override
  State<MentalCanvasViewport> createState() => _MentalCanvasViewportState();
}

class _MentalCanvasViewportState extends State<MentalCanvasViewport> {
  final List<StrokePoint> _activePoints = [];
  bool _isDrawing = false;
  int _activeDrawPointerId = -1;

  // Multitouch gesture tracking for two-finger 3D orbit
  final Map<int, Offset> _touchPointers = {};
  double _initialSpan = 0.0;
  double _initialCameraDistance = 900.0;
  Offset _lastCentroid = Offset.zero;

  CanvasPlane3D get _activePlane {
    return widget.planes.firstWhere(
      (p) => p.id == widget.activePlaneId,
      orElse: () => widget.planes.isNotEmpty
          ? widget.planes.first
          : CanvasPlane3D.primaryFront(),
    );
  }

  Color get _inkColor => widget.overrideInkColor ?? widget.theme.defaultInk;

  void _onPointerDown(PointerDownEvent event, Size size) {
    _touchPointers[event.pointer] = event.localPosition;

    if (_touchPointers.length >= 2) {
      // Transition to camera orbit mode: cancel active stroke
      _cancelActiveStroke();
      _startMultiTouchOrbit();
      return;
    }

    final isStylus = event.kind == PointerDeviceKind.stylus;
    final isMouse =
        event.kind == PointerDeviceKind.mouse &&
        event.buttons == kPrimaryMouseButton;
    final isTouch = event.kind == PointerDeviceKind.touch;

    if ((isStylus || isMouse || isTouch) && !_isDrawing) {
      final uv = _activePlane.intersectRay(
        screenPos: event.localPosition,
        screenSize: size,
        cameraYaw: widget.cameraYaw,
        cameraPitch: widget.cameraPitch,
        cameraDistance: widget.cameraDistance,
      );

      if (uv != null) {
        _isDrawing = true;
        _activeDrawPointerId = event.pointer;
        _activePoints.clear();
        final nowMicros = DateTime.now().microsecondsSinceEpoch;
        _activePoints.add(
          StrokePoint(
            position: Offset(uv.dx + 2000.0, uv.dy + 2000.0),
            pressure: event.pressure > 0.0 ? event.pressure : 0.5,
            tilt: event.tilt,
            timestampMicros: nowMicros,
          ),
        );
        setState(() {});
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event, Size size) {
    _touchPointers[event.pointer] = event.localPosition;

    if (_touchPointers.length >= 2) {
      _updateMultiTouchOrbit();
      return;
    }

    if (!_isDrawing || event.pointer != _activeDrawPointerId) return;

    final uv = _activePlane.intersectRay(
      screenPos: event.localPosition,
      screenSize: size,
      cameraYaw: widget.cameraYaw,
      cameraPitch: widget.cameraPitch,
      cameraDistance: widget.cameraDistance,
    );

    if (uv != null) {
      final nowMicros = DateTime.now().microsecondsSinceEpoch;
      _activePoints.add(
        StrokePoint(
          position: Offset(uv.dx + 2000.0, uv.dy + 2000.0),
          pressure: event.pressure > 0.0 ? event.pressure : 0.5,
          tilt: event.tilt,
          timestampMicros: nowMicros,
        ),
      );
      setState(() {});
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _touchPointers.remove(event.pointer);

    if (_touchPointers.length < 2) {
      _initialSpan = 0.0;
    }

    if (_isDrawing && event.pointer == _activeDrawPointerId) {
      _finalizeStroke();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _touchPointers.remove(event.pointer);
    if (_touchPointers.length < 2) {
      _initialSpan = 0.0;
    }
    if (_isDrawing && event.pointer == _activeDrawPointerId) {
      _finalizeStroke();
    }
  }

  void _startMultiTouchOrbit() {
    final pts = _touchPointers.values.toList();
    if (pts.length >= 2) {
      _initialSpan = (pts[0] - pts[1]).distance;
      _initialCameraDistance = widget.cameraDistance;
      _lastCentroid = Offset(
        (pts[0].dx + pts[1].dx) / 2.0,
        (pts[0].dy + pts[1].dy) / 2.0,
      );
    }
  }

  void _updateMultiTouchOrbit() {
    final pts = _touchPointers.values.toList();
    if (pts.length < 2) return;

    final centroid = Offset(
      (pts[0].dx + pts[1].dx) / 2.0,
      (pts[0].dy + pts[1].dy) / 2.0,
    );

    final delta = centroid - _lastCentroid;
    _lastCentroid = centroid;

    final newYaw = widget.cameraYaw - delta.dx * 0.006;
    final newPitch = (widget.cameraPitch + delta.dy * 0.006).clamp(
      -math.pi / 2.5,
      math.pi / 2.5,
    );

    double newDist = widget.cameraDistance;
    final currentSpan = (pts[0] - pts[1]).distance;
    if (_initialSpan > 10.0 && currentSpan > 10.0) {
      final ratio = currentSpan / _initialSpan;
      newDist = (_initialCameraDistance / ratio).clamp(300.0, 3000.0);
    }

    widget.onCameraChanged(newYaw, newPitch, newDist);
  }

  void _cancelActiveStroke() {
    if (_isDrawing) {
      setState(() {
        _isDrawing = false;
        _activeDrawPointerId = -1;
        _activePoints.clear();
      });
    }
  }

  void _finalizeStroke() {
    if (_activePoints.isNotEmpty) {
      final stroke = Stroke(
        points: List.from(_activePoints),
        color: _inkColor,
        lineWeight: widget.currentLineWeight,
        brushStyle: widget.currentBrushStyle,
        planeId: _activePlane.id,
      );
      widget.onStrokeCompleted(stroke);
    }

    setState(() {
      _isDrawing = false;
      _activeDrawPointerId = -1;
      _activePoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        final activeStroke = _isDrawing && _activePoints.isNotEmpty
            ? Stroke(
                points: _activePoints,
                color: _inkColor,
                lineWeight: widget.currentLineWeight,
                brushStyle: widget.currentBrushStyle,
                planeId: _activePlane.id,
              )
            : null;

        return Listener(
          onPointerDown: (e) => _onPointerDown(e, size),
          onPointerMove: (e) => _onPointerMove(e, size),
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Container(
            width: size.width,
            height: size.height,
            color: widget.theme.canvasBackground,
            child: CustomPaint(
              size: size,
              painter: MentalCanvasPainter(
                theme: widget.theme,
                planes: widget.planes,
                activePlaneId: widget.activePlaneId,
                strokes: widget.strokes,
                activeStroke: activeStroke,
                cameraYaw: widget.cameraYaw,
                cameraPitch: widget.cameraPitch,
                cameraDistance: widget.cameraDistance,
              ),
            ),
          ),
        );
      },
    );
  }
}
