import 'package:flutter/material.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Floating HUD dock displaying metric scale bar and logarithmic zoom controls.
class InfiniteZoomHud extends StatelessWidget {
  /// Creates an [InfiniteZoomHud].
  const InfiniteZoomHud({
    super.key,
    required this.theme,
    required this.zoomScale,
    required this.onZoomPresetSelected,
    required this.onZoomStep,
    required this.onResetZoom,
  });

  /// Design theme tokens.
  final AppThemeTokens theme;

  /// Current canvas magnification factor.
  final double zoomScale;

  /// Callback when a preset magnification level is tapped.
  final ValueChanged<double> onZoomPresetSelected;

  /// Callback when +/- step zoom button is tapped.
  final ValueChanged<double> onZoomStep;

  /// Callback to reset scale to 1.0.
  final VoidCallback onResetZoom;

  /// Computes human-friendly metric scale label (km -> m -> cm -> mm -> um).
  static String formatMetricScale(double scale) {
    if (scale <= 0) return '1 m';
    final realMeters = 1.0 / scale;
    if (realMeters >= 1000.0) {
      final km = realMeters / 1000.0;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
    }
    if (realMeters >= 1.0) {
      return '${realMeters.toStringAsFixed(realMeters >= 10 ? 0 : 1)} m';
    }
    if (realMeters >= 0.01) {
      final cm = realMeters * 100.0;
      return '${cm.toStringAsFixed(cm >= 10 ? 0 : 1)} cm';
    }
    if (realMeters >= 0.001) {
      final mm = realMeters * 1000.0;
      return '${mm.toStringAsFixed(mm >= 10 ? 0 : 1)} mm';
    }
    final um = realMeters * 1000000.0;
    return '${um.toStringAsFixed(um >= 10 ? 0 : 1)} μm';
  }

  /// Formatted magnification string (e.g. 1.0x, 15.2x, 1.5k x).
  static String formatMagnification(double scale) {
    if (scale >= 1000.0) {
      final k = scale / 1000.0;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k×';
    }
    if (scale >= 10.0) {
      return '${scale.toStringAsFixed(0)}×';
    }
    if (scale >= 1.0) {
      return '${scale.toStringAsFixed(1)}×';
    }
    return '${scale.toStringAsFixed(2)}×';
  }

  @override
  Widget build(BuildContext context) {
    final metricLabel = formatMetricScale(zoomScale);
    final magLabel = formatMagnification(zoomScale);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Metric Scale Bar Indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: 13,
                    color: theme.accentCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    metricLabel,
                    style: theme.monoStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.accentCyan,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.borderHighlight.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      magLabel,
                      style: theme.monoStyle.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: theme.borderHighlight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Calibrated 80px scale bar with tick marks
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.accentCyan.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 24,
            color: theme.borderSubtle,
          ),
          const SizedBox(width: 10),

          // Preset Magnification Chips
          _buildPresetChip('1×', 1.0),
          const SizedBox(width: 4),
          _buildPresetChip('10×', 10.0),
          const SizedBox(width: 4),
          _buildPresetChip('100×', 100.0),
          const SizedBox(width: 4),
          _buildPresetChip('1000×', 1000.0),

          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 24,
            color: theme.borderSubtle,
          ),
          const SizedBox(width: 6),

          // Fine Step Zoom Buttons
          IconButton(
            tooltip: 'Zoom Out (0.5×)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.remove_rounded,
              size: 16,
              color: theme.defaultInk,
            ),
            onPressed: () => onZoomStep(0.5),
          ),
          IconButton(
            tooltip: 'Zoom In (2.0×)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.add_rounded,
              size: 16,
              color: theme.defaultInk,
            ),
            onPressed: () => onZoomStep(2.0),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, double scale) {
    final isNearby = (zoomScale / scale >= 0.8) && (zoomScale / scale <= 1.25);
    return InkWell(
      onTap: () => onZoomPresetSelected(scale),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isNearby
              ? theme.borderHighlight.withOpacity(0.25)
              : theme.borderSubtle.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isNearby ? theme.borderHighlight : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: theme.monoStyle.copyWith(
            fontSize: 10,
            fontWeight: isNearby ? FontWeight.w700 : FontWeight.w500,
            color: isNearby ? theme.borderHighlight : theme.secondaryInk,
          ),
        ),
      ),
    );
  }
}
