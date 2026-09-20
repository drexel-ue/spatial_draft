import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spatial_draft/canvas/canvas_grid_painter.dart';
import 'package:spatial_draft/canvas/hardware/stylus_hover_reticle.dart';
import 'package:spatial_draft/canvas/ink_layer_painter.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

class InteractiveCanvas extends StatefulWidget {

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
    this.showRecenterHud = true,
    this.isInfiniteZoom = false,
    this.activePlaneId = 'plane_primary',
    this.transformationController,
    this.onStrokeCompleted,
    required this.strokes,
    this.onClear,
    this.onTransformChanged,
    this.onScaleChanged,
  });
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final LineWeightType currentLineWeight;
  final Color? overrideInkColor;
  final Widget? backgroundDrillOverlay;
  final bool showHeatmap;
  final bool allowFingerDrawing;
  final bool showRecenterHud;
  final bool isInfiniteZoom;
  final String activePlaneId;
  final TransformationController? transformationController;
  final void Function(Stroke stroke)? onStrokeCompleted;
  final List<Stroke> strokes;
  final VoidCallback? onClear;
  final void Function(Matrix4 transform)? onTransformChanged;
  final ValueChanged<double>? onScaleChanged;

  @override
  State<InteractiveCanvas> createState() => _InteractiveCanvasState();
}

class _InteractiveCanvasState extends State<InteractiveCanvas> {
  late final TransformationController _transformController;
  final ValueNotifier<double> _scaleNotifier = ValueNotifier<double>(1.0);
  final List<StrokePoint> _activePoints = [];
  bool _isDrawing = false;
  int _activePointerId = -1;
  Offset? _hoverPosition;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _transformController = widget.transformationController ??
        TransformationController(
          Matrix4.identity()..translate(-1433.0, -1628.0),
        );
    _transformController.addListener(_onTransformUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.transformationController == null) {
        _centerCanvas();
      }
    });
  }

  void _onTransformUpdated() {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    _scaleNotifier.value = scale;
    widget.onTransformChanged?.call(matrix);
    widget.onScaleChanged?.call(scale);
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
    _transformController.removeListener(_onTransformUpdated);
    if (widget.transformationController == null) {
      _transformController.dispose();
    }
    _scaleNotifier.dispose();
    super.dispose();
  }

  Color get _currentInkColor => widget.overrideInkColor ?? widget.theme.defaultInk;

  void _handlePointerHover(PointerHoverEvent event) {
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.mouse) {
      setState(() {
        _hoverPosition = event.localPosition;
        _isHovering = true;
      });
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Stylus or Mouse primary click or touch if allowed
    final isStylus = event.kind == PointerDeviceKind.stylus;
    final isMouse = event.kind == PointerDeviceKind.mouse &&
        event.buttons == kPrimaryMouseButton;
    final isAllowedTouch =
        event.kind == PointerDeviceKind.touch && widget.allowFingerDrawing;

    if (isStylus || isMouse || isAllowedTouch) {
      if (_isDrawing) return;

      final canvasPos = _screenToCanvas(event.localPosition);
      _activePointerId = event.pointer;
      _isDrawing = true;
      _isHovering = false;
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
    _isHovering = false;
    _finalizeStroke();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_isDrawing || event.pointer != _activePointerId) return;
    _isHovering = false;
    _finalizeStroke();
  }

  void _finalizeStroke() {
    if (_activePoints.isNotEmpty) {
      final currentScale = _transformController.value.getMaxScaleOnAxis();
      final newStroke = Stroke(
        points: List.from(_activePoints),
        color: _currentInkColor,
        lineWeight: widget.currentLineWeight,
        planeId: widget.activePlaneId,
        authoringScale: currentScale,
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
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final liveStroke = _isDrawing && _activePoints.isNotEmpty
        ? Stroke(
            points: _activePoints,
            color: _currentInkColor,
            lineWeight: widget.currentLineWeight,
            planeId: widget.activePlaneId,
            authoringScale: currentScale,
          )
        : null;

    return ColoredBox(
      color: widget.theme.canvasBackground,
      child: Stack(
        children: [
          // Infinite Canvas Pan/Zoom Layer
          InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: widget.isInfiniteZoom
                ? const EdgeInsets.all(12000)
                : const EdgeInsets.all(3000),
            minScale: widget.isInfiniteZoom ? 0.001 : 0.25,
            maxScale: widget.isInfiniteZoom ? 25000.0 : 6.0,
            panEnabled: !_isDrawing,
            scaleEnabled: !_isDrawing,
            constrained: false,
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
              onPointerHover: _handlePointerHover,
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
            ),
          ),

          // Stylus Precision Hover Reticle
          if (_isHovering && _hoverPosition != null && !_isDrawing)
            StylusHoverReticle(
              theme: widget.theme,
              position: _hoverPosition!,
              currentLineWeight: widget.currentLineWeight,
            ),

          // Floating Recenter & Zoom HUD dock
          if (widget.showRecenterHud)
            Positioned(
              top: 16,
              right: 16,
              child: _buildRecenterHud(widget.theme),
            ),
        ],
      ),
    );
  }

  Widget _buildRecenterHud(AppThemeTokens theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom percentage badge (tap to reset to 100%)
            InkWell(
              onTap: _centerCanvas,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: ValueListenableBuilder<double>(
                  valueListenable: _scaleNotifier,
                  builder: (ctx, scale, _) {
                    final percent = (scale * 100).round();
                    return Text(
                      '$percent%',
                      style: theme.monoStyle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.secondaryInk,
                      ),
                    );
                  },
                ),
              ),
            ),

            Container(
              width: 1,
              height: 16,
              color: theme.borderSubtle,
            ),

            // Recenter button
            IconButton(
              icon: Icon(
                Icons.filter_center_focus_rounded,
                color: theme.secondaryInk,
                size: 18,
              ),
              tooltip: 'Recenter Canvas (1:1)',
              splashRadius: 18,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 34,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _centerCanvas,
            ),
          ],
        ),
      ),
    );
  }
}
