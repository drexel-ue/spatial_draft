import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/spatial_bookmark.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Floating control dock for 3D Mental Canvas orbital camera & plane switching.
class MentalCanvasTurntableDock extends StatelessWidget {
  /// Creates a [MentalCanvasTurntableDock].
  const MentalCanvasTurntableDock({
    super.key,
    required this.theme,
    required this.planes,
    required this.activePlaneId,
    required this.cameraYaw,
    required this.cameraPitch,
    required this.onCameraChanged,
    required this.onSelectPlane,
    required this.onAddPlane,
    required this.onSnapToPlane,
    required this.onResetOrbit,
    this.onEditPlane,
    this.bookmarks = const [],
    this.onSelectBookmark,
    this.onAddBookmark,
    this.onPlayTour,
    this.isPlayingTour = false,
  });

  /// Design tokens.
  final AppThemeTokens theme;

  /// All spatial planes in the project.
  final List<CanvasPlane3D> planes;

  /// Currently active plane ID.
  final String activePlaneId;

  /// Current orbital yaw in radians.
  final double cameraYaw;

  /// Current orbital pitch in radians.
  final double cameraPitch;

  /// Callback when camera rotation updates.
  final void Function(double yaw, double pitch) onCameraChanged;

  /// Callback when user selects an active plane.
  final ValueChanged<String> onSelectPlane;

  /// Callback when user adds a new plane template.
  final ValueChanged<CanvasPlane3D> onAddPlane;

  /// Callback to align camera perpendicular to active plane.
  final VoidCallback onSnapToPlane;

  /// Callback to reset orbital rotation to 0,0.
  final VoidCallback onResetOrbit;

  /// Optional callback to open plane transformation editor.
  final VoidCallback? onEditPlane;

  /// Spatial bookmarks / 3D camera waypoints.
  final List<SpatialBookmark> bookmarks;

  /// Callback when a 3D bookmark is selected.
  final ValueChanged<SpatialBookmark>? onSelectBookmark;

  /// Callback to record a new 3D camera keyframe bookmark.
  final VoidCallback? onAddBookmark;

  /// Callback to play or pause cinematic tour.
  final VoidCallback? onPlayTour;

  /// Whether cinematic tour is currently playing.
  final bool isPlayingTour;

  CanvasPlane3D get _activePlane {
    return planes.firstWhere(
      (p) => p.id == activePlaneId,
      orElse: () => planes.isNotEmpty
          ? planes.first
          : CanvasPlane3D.primaryFront(),
    );
  }

  void _stepYaw(double deltaDegrees) {
    final deltaRad = deltaDegrees * math.pi / 180.0;
    onCameraChanged(cameraYaw + deltaRad, cameraPitch);
  }

  void _stepPitch(double deltaDegrees) {
    final deltaRad = deltaDegrees * math.pi / 180.0;
    final newPitch = (cameraPitch + deltaRad).clamp(
      -math.pi / 2.5,
      math.pi / 2.5,
    );
    onCameraChanged(cameraYaw, newPitch);
  }

  @override
  Widget build(BuildContext context) {
    final waypoints3D = bookmarks.where((b) => b.is3D).toList();
    final yawDeg = (cameraYaw * 180.0 / math.pi) % 360;
    final pitchDeg = cameraPitch * 180.0 / math.pi;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active Plane Selector Dropdown Menu
            PopupMenuButton<String>(
              tooltip: 'Active Sketching Plane',
              onSelected: (val) {
                if (val.startsWith('add_')) {
                  _handleAddTemplate(val);
                } else {
                  onSelectPlane(val);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.borderHighlight.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.borderHighlight.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.view_in_ar_rounded,
                      size: 15,
                      color: theme.borderHighlight,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        _activePlane.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.monoStyle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.borderHighlight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: theme.secondaryInk,
                  ),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              ...planes.map((p) {
                final isSelected = p.id == activePlaneId;
                return PopupMenuItem<String>(
                  value: p.id,
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: isSelected
                            ? theme.borderHighlight
                            : theme.secondaryInk,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          style: theme.bodyStyle.copyWith(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'add_ground',
                child: Row(
                  children: [
                    Icon(Icons.add_box_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('+ Ground Plane (XZ)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'add_left_wall',
                child: Row(
                  children: [
                    Icon(Icons.add_box_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('+ Left Wall (YZ)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'add_right_wall',
                child: Row(
                  children: [
                    Icon(Icons.add_box_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('+ Right Wall (YZ)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'add_backdrop',
                child: Row(
                  children: [
                    Icon(Icons.add_box_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('+ Backdrop Plane (Z)'),
                  ],
                ),
              ),
            ],
          ),

          if (onEditPlane != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Edit 3D Plane (Transforms & Angles)',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                Icons.tune_rounded,
                size: 16,
                color: theme.borderHighlight,
              ),
              onPressed: onEditPlane,
            ),
          ],

          const SizedBox(width: 6),

          // Face Plane Button (Snap Camera Normal)
          IconButton(
            tooltip: 'Face Plane (Align Camera Normal)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.center_focus_strong_rounded,
              size: 18,
              color: theme.accentCyan,
            ),
            onPressed: onSnapToPlane,
          ),

          const SizedBox(width: 4),
          Container(width: 1, height: 20, color: theme.borderSubtle),
          const SizedBox(width: 6),

          // Orbital Camera Degrees Badge
          Text(
            '${yawDeg.toStringAsFixed(0)}° / ${pitchDeg.toStringAsFixed(0)}°',
            style: theme.monoStyle.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.secondaryInk,
            ),
          ),

          const SizedBox(width: 6),

          // Orbital Step Buttons (Left, Right, Tilt Up, Tilt Down)
          IconButton(
            tooltip: 'Orbit Left (-15°)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.rotate_left_rounded,
              size: 18,
              color: theme.defaultInk,
            ),
            onPressed: () => _stepYaw(-15.0),
          ),
          IconButton(
            tooltip: 'Orbit Right (+15°)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.rotate_right_rounded,
              size: 18,
              color: theme.defaultInk,
            ),
            onPressed: () => _stepYaw(15.0),
          ),
          IconButton(
            tooltip: 'Tilt Up (+10°)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.arrow_upward_rounded,
              size: 16,
              color: theme.defaultInk,
            ),
            onPressed: () => _stepPitch(10.0),
          ),
          IconButton(
            tooltip: 'Tilt Down (-10°)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.arrow_downward_rounded,
              size: 16,
              color: theme.defaultInk,
            ),
            onPressed: () => _stepPitch(-10.0),
          ),

          // Reset Orbit Button
          IconButton(
            tooltip: 'Reset 3D Camera',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.restart_alt_rounded,
              size: 18,
              color: theme.borderHighlight,
            ),
            onPressed: onResetOrbit,
          ),

          // Storyboard Keyframes & Tour Playback
          if (onAddBookmark != null || waypoints3D.isNotEmpty) ...[
            const SizedBox(width: 4),
            Container(width: 1, height: 20, color: theme.borderSubtle),
            const SizedBox(width: 6),
          ],

          if (waypoints3D.isNotEmpty)
            PopupMenuButton<SpatialBookmark>(
              tooltip: 'Storyboard Keyframes (${waypoints3D.length})',
              onSelected: (bm) => onSelectBookmark?.call(bm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.accentAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.accentAmber.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.movie_creation_outlined,
                      size: 14,
                      color: theme.accentAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${waypoints3D.length}',
                      style: theme.monoStyle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.accentAmber,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: theme.secondaryInk,
                    ),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                ...waypoints3D.map((bm) {
                  return PopupMenuItem<SpatialBookmark>(
                    value: bm,
                    child: Row(
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          size: 16,
                          color: theme.accentAmber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bm.name,
                            style: theme.bodyStyle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

          if (onAddBookmark != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Add 3D Camera Keyframe',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                Icons.bookmark_add_rounded,
                size: 17,
                color: theme.accentAmber,
              ),
              onPressed: onAddBookmark,
            ),
          ],

          if (onPlayTour != null && waypoints3D.length >= 2) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: isPlayingTour
                  ? 'Pause Cinematic Tour'
                  : 'Play 3D Cinematic Tour',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(
                isPlayingTour
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                size: 19,
                color: isPlayingTour
                    ? theme.accentAmber
                    : theme.borderHighlight,
              ),
              onPressed: onPlayTour,
            ),
          ],
        ],
      ),
    ),
  );
}

  void _handleAddTemplate(String val) {
    switch (val) {
      case 'add_ground':
        onAddPlane(CanvasPlane3D.groundFloor());
        break;
      case 'add_left_wall':
        onAddPlane(CanvasPlane3D.leftWall());
        break;
      case 'add_right_wall':
        onAddPlane(CanvasPlane3D.rightWall());
        break;
      case 'add_backdrop':
        onAddPlane(CanvasPlane3D.backdrop());
        break;
    }
  }
}
