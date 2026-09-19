import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/models/stroke.dart';
import '../core/models/stroke_point.dart';
import '../core/theme/app_theme.dart';
import 'canvas_grid_painter.dart';
import 'ink_layer_painter.dart';

class InteractiveCanvas extends StatefulWidget {
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final LineWeightType currentLineWeight;
  final Color? overrideInkColor;
  final Widget? backgroundDrillOverlay;
  final bool showHeatmap;
  final bool allowFingerDrawing;
  final Function(Stroke stroke)? onStrokeCompleted;
  final List<Stroke> strokes;
  final VoidCallback? onClear;

  const InteractiveCanvas({
    super.key,
    required this.theme,
    this.gridStyle = GridStyle.solid,
    this.gridType = GridType.squareMetric,
    this.currentLineWeight = LineWeightType.crease,
    this.overrideInkColor,
    this.backgroundDrillOverlay,
    this.showHeatmap = false,
    this.allowFingerDrawing = true,
    this.onStrokeCompleted,
    required this.strokes,
    this.onClear,
  });

  @override
  State<InteractiveCanvas> createState() => _InteractiveCanvasState();
}

class _InteractiveCanvasState extends State<InteractiveCanvas> {
  late final TransformationController _transformController;
  final List<StrokePoint> _activePoints = [];
  bool _isDrawing = false;
  int _activePointerId = -1;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController(
      Matrix4.identity()..translate(-1433.0, -1628.0),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _centerCanvas();
      }
    });
  }

  void _centerCanvas() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final tx = (size.width - 4000.0) / 2.0;
      final ty = (size.height - 4000.0) / 2.0;
      _transformController.value = Matrix4.identity()..translate(tx, ty);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Color get _currentInkColor => widget.overrideInkColor ?? widget.theme.defaultInk;

  void _handlePointerDown(PointerDownEvent event) {
    // Stylus or Mouse primary click or touch if allowed
    final isStylus = event.kind == PointerDeviceKind.stylus;
    final isMouse = event.kind == PointerDeviceKind.mouse && event.buttons == kPrimaryMouseButton;
    final isAllowedTouch = event.kind == PointerDeviceKind.touch && widget.allowFingerDrawing;

    if (isStylus || isMouse || isAllowedTouch) {
      if (_isDrawing) return;

      final canvasPos = _screenToCanvas(event.localPosition);
      _activePointerId = event.pointer;
      _isDrawing = true;
      _activePoints.clear();
      _activePoints.add(
        StrokePoint(
          position: canvasPos,
          pressure: event.pressure > 0.0 ? event.pressure : 0.5,
          tilt: event.tilt,
          timestampMicros: DateTime.now().microsecondsSinceEpoch,
        ),
      );
      setState(() {});
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isDrawing || event.pointer != _activePointerId) return;

    final canvasPos = _screenToCanvas(event.localPosition);
    _activePoints.add(
      StrokePoint(
        position: canvasPos,
        pressure: event.pressure > 0.0 ? event.pressure : 0.5,
        tilt: event.tilt,
        timestampMicros: DateTime.now().microsecondsSinceEpoch,
      ),
    );
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isDrawing || event.pointer != _activePointerId) return;

    _finalizeStroke();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_isDrawing || event.pointer != _activePointerId) return;

    _finalizeStroke();
  }

  void _finalizeStroke() {
    if (_activePoints.isNotEmpty) {
      final newStroke = Stroke(
        points: List.from(_activePoints),
        color: _currentInkColor,
        lineWeight: widget.currentLineWeight,
      );
      widget.onStrokeCompleted?.call(newStroke);
    }
    setState(() {
      _isDrawing = false;
      _activePointerId = -1;
      _activePoints.clear();
    });
  }

  Offset _screenToCanvas(Offset screenPos) {
    final matrix = _transformController.value;
    final inverted = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverted, screenPos);
  }

  @override
  Widget build(BuildContext context) {
    final liveStroke = _isDrawing && _activePoints.isNotEmpty
        ? Stroke(
            points: _activePoints,
            color: _currentInkColor,
            lineWeight: widget.currentLineWeight,
          )
        : null;

    return Container(
      color: widget.theme.canvasBackground,
      child: Stack(
        children: [
          // Infinite Canvas Pan/Zoom Layer
          InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(3000),
            minScale: 0.25,
            maxScale: 6.0,
            panEnabled: !_isDrawing,
            scaleEnabled: !_isDrawing,
            child: SizedBox(
              width: 4000,
              height: 4000,
              child: Stack(
                children: [
                  // 1. Procedural Grid Background
                  CustomPaint(
                    size: const Size(4000, 4000),
                    painter: CanvasGridPainter(
                      theme: widget.theme,
                      gridStyle: widget.gridStyle,
                      gridType: widget.gridType,
                      transform: _transformController.value,
                    ),
                  ),

                  // 2. Procedural Exercise / Drill Overlay (if present)
                  if (widget.backgroundDrillOverlay != null)
                    Positioned.fill(
                      child: widget.backgroundDrillOverlay!,
                    ),

                  // 3. Active & Completed Ink Layer
                  CustomPaint(
                    size: const Size(4000, 4000),
                    painter: InkLayerPainter(
                      completedStrokes: widget.strokes,
                      activeStroke: liveStroke,
                      theme: widget.theme,
                      showHeatmap: widget.showHeatmap,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Raw Pointer Event Listener for Low-Latency Input
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
            ),
          ),
        ],
      ),
    );
  }
}
