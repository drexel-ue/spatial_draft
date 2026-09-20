import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Modal bottom sheet for interactive 3D manipulation of a sketching plane.
class PlaneTransformSheet extends StatefulWidget {
  /// Creates a [PlaneTransformSheet].
  const PlaneTransformSheet({
    super.key,
    required this.theme,
    required this.plane,
    required this.onPlaneUpdated,
    required this.onDuplicatePlane,
    required this.onDeletePlane,
  });

  /// Opens the [PlaneTransformSheet] modal.
  static Future<void> show({
    required BuildContext context,
    required AppThemeTokens theme,
    required CanvasPlane3D plane,
    required ValueChanged<CanvasPlane3D> onPlaneUpdated,
    required VoidCallback onDuplicatePlane,
    required VoidCallback onDeletePlane,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlaneTransformSheet(
        theme: theme,
        plane: plane,
        onPlaneUpdated: onPlaneUpdated,
        onDuplicatePlane: onDuplicatePlane,
        onDeletePlane: onDeletePlane,
      ),
    );
  }

  /// Design theme tokens.
  final AppThemeTokens theme;

  /// Current 3D plane being edited.
  final CanvasPlane3D plane;

  /// Callback when plane parameters update.
  final ValueChanged<CanvasPlane3D> onPlaneUpdated;

  /// Callback to duplicate active plane.
  final VoidCallback onDuplicatePlane;

  /// Callback to delete active plane.
  final VoidCallback onDeletePlane;

  @override
  State<PlaneTransformSheet> createState() => _PlaneTransformSheetState();
}

class _PlaneTransformSheetState extends State<PlaneTransformSheet> {
  late CanvasPlane3D _plane;

  @override
  void initState() {
    super.initState();
    _plane = widget.plane;
  }

  void _update(CanvasPlane3D updated) {
    setState(() {
      _plane = updated;
    });
    widget.onPlaneUpdated(updated);
  }

  void _applyPreset(
    double yawDeg,
    double pitchDeg,
    double rollDeg,
    double ox,
    double oy,
    double oz,
  ) {
    _update(
      _plane.copyWith(
        yaw: yawDeg * math.pi / 180.0,
        pitch: pitchDeg * math.pi / 180.0,
        roll: rollDeg * math.pi / 180.0,
        originX: ox,
        originY: oy,
        originZ: oz,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final yawDeg = (_plane.yaw * 180.0 / math.pi).round();
    final pitchDeg = (_plane.pitch * 180.0 / math.pi).round();
    final rollDeg = (_plane.roll * 180.0 / math.pi).round();

    return Container(
      constraints: const BoxConstraints(maxHeight: 580),
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: theme.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _plane.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _plane.name,
                    style: theme.headingStyle.copyWith(
                      fontSize: 16,
                      color: theme.defaultInk,
                    ),
                  ),
                ),

                // Visibility Eye Toggle
                IconButton(
                  tooltip: _plane.isVisible ? 'Hide Plane' : 'Show Plane',
                  icon: Icon(
                    _plane.isVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: _plane.isVisible
                        ? theme.accentCyan
                        : theme.secondaryInk,
                    size: 20,
                  ),
                  onPressed: () {
                    _update(_plane.copyWith(isVisible: !_plane.isVisible));
                  },
                ),

                // Lock Toggle
                IconButton(
                  tooltip: _plane.isLocked ? 'Unlock Plane' : 'Lock Plane',
                  icon: Icon(
                    _plane.isLocked
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    color: _plane.isLocked
                        ? theme.warning
                        : theme.secondaryInk,
                    size: 20,
                  ),
                  onPressed: () {
                    _update(_plane.copyWith(isLocked: !_plane.isLocked));
                  },
                ),

                // Close
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.secondaryInk,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Quick Orientation Presets
                Text(
                  'ALIGNMENT PRESETS',
                  style: theme.monoStyle.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: theme.secondaryInk,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPresetPill('Front (XY)', () {
                      _applyPreset(0, 0, 0, 0, 0, 0);
                    }),
                    _buildPresetPill('Ground (XZ)', () {
                      _applyPreset(0, 90, 0, 0, 450, 0);
                    }),
                    _buildPresetPill('Left Wall (YZ)', () {
                      _applyPreset(90, 0, 0, -450, 0, 0);
                    }),
                    _buildPresetPill('Right Wall (YZ)', () {
                      _applyPreset(-90, 0, 0, 450, 0, 0);
                    }),
                    _buildPresetPill('45° Isometric', () {
                      _applyPreset(45, 35, 0, 0, 0, 0);
                    }),
                    _buildPresetPill('Backdrop (Z)', () {
                      _applyPreset(0, 0, 0, 0, 0, -600);
                    }),
                  ],
                ),

                const SizedBox(height: 18),

                // Euler Rotation Angles
                Text(
                  'ROTATION (EULER ANGLES)',
                  style: theme.monoStyle.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: theme.secondaryInk,
                  ),
                ),
                const SizedBox(height: 4),

                _buildSliderRow(
                  label: 'Yaw (Y-Axis)',
                  valStr: '$yawDeg°',
                  value: _plane.yaw,
                  min: -math.pi,
                  max: math.pi,
                  onChanged: (v) => _update(_plane.copyWith(yaw: v)),
                ),
                _buildSliderRow(
                  label: 'Pitch (X-Axis)',
                  valStr: '$pitchDeg°',
                  value: _plane.pitch,
                  min: -math.pi / 2.0,
                  max: math.pi / 2.0,
                  onChanged: (v) => _update(_plane.copyWith(pitch: v)),
                ),
                _buildSliderRow(
                  label: 'Roll (Z-Axis)',
                  valStr: '$rollDeg°',
                  value: _plane.roll,
                  min: -math.pi,
                  max: math.pi,
                  onChanged: (v) => _update(_plane.copyWith(roll: v)),
                ),

                const SizedBox(height: 16),

                // World Position Offsets
                Text(
                  'WORLD POSITION OFFSET',
                  style: theme.monoStyle.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: theme.secondaryInk,
                  ),
                ),
                const SizedBox(height: 4),

                _buildSliderRow(
                  label: 'X (Lateral)',
                  valStr: '${_plane.originX.round()} px',
                  value: _plane.originX,
                  min: -1500.0,
                  max: 1500.0,
                  onChanged: (v) => _update(_plane.copyWith(originX: v)),
                ),
                _buildSliderRow(
                  label: 'Y (Vertical)',
                  valStr: '${_plane.originY.round()} px',
                  value: _plane.originY,
                  min: -1500.0,
                  max: 1500.0,
                  onChanged: (v) => _update(_plane.copyWith(originY: v)),
                ),
                _buildSliderRow(
                  label: 'Z (Depth)',
                  valStr: '${_plane.originZ.round()} px',
                  value: _plane.originZ,
                  min: -1500.0,
                  max: 1500.0,
                  onChanged: (v) => _update(_plane.copyWith(originZ: v)),
                ),

                const SizedBox(height: 16),

                // Opacity Slider
                _buildSliderRow(
                  label: 'Wireframe Opacity',
                  valStr: '${(_plane.opacity * 100).round()}%',
                  value: _plane.opacity,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) => _update(_plane.copyWith(opacity: v)),
                ),

                const SizedBox(height: 20),

                // Actions: Duplicate & Delete
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(
                          'Duplicate Plane',
                          style: theme.headingStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.borderHighlight,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.borderHighlight,
                          side: BorderSide(color: theme.borderHighlight),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDuplicatePlane();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: Text(
                          'Delete Plane',
                          style: theme.headingStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.danger,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.danger,
                          side: BorderSide(color: theme.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDeletePlane();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPill(String label, VoidCallback onTap) {
    final theme = widget.theme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.surfaceGlass,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderSubtle),
        ),
        child: Text(
          label,
          style: theme.monoStyle.copyWith(
            fontSize: 11,
            color: theme.defaultInk,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valStr,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = widget.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.bodyStyle.copyWith(
                fontSize: 12,
                color: theme.defaultInk,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 12,
                ),
                activeTrackColor: theme.borderHighlight,
                thumbColor: theme.borderHighlight,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 65,
            child: Text(
              valStr,
              textAlign: TextAlign.end,
              style: theme.monoStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.secondaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
