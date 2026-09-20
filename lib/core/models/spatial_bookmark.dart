/// Represents a saved multi-scale waypoint for cinematic fly-through.
class SpatialBookmark {
  /// Creates a [SpatialBookmark].
  const SpatialBookmark({
    required this.id,
    required this.name,
    required this.zoomScale,
    this.panOffsetX = 0.0,
    this.panOffsetY = 0.0,
    required this.createdAt,
  });

  /// Deserializes a [SpatialBookmark] from JSON map.
  factory SpatialBookmark.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final createdStr = json['createdAt'] as String?;
    return SpatialBookmark(
      id: json['id'] as String? ?? 'bm_${now.microsecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Waypoint',
      zoomScale: (json['zoomScale'] as num?)?.toDouble() ?? 1.0,
      panOffsetX: (json['panOffsetX'] as num?)?.toDouble() ?? 0.0,
      panOffsetY: (json['panOffsetY'] as num?)?.toDouble() ?? 0.0,
      createdAt: createdStr != null
          ? DateTime.tryParse(createdStr) ?? now
          : now,
    );
  }

  /// Unique bookmark identifier.
  final String id;

  /// User-defined waypoint title (e.g. "Overview", "Valve Assembly").
  final String name;

  /// Magnification scale factor at this bookmark.
  final double zoomScale;

  /// Camera pan offset X.
  final double panOffsetX;

  /// Camera pan offset Y.
  final double panOffsetY;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Serializes this [SpatialBookmark] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zoomScale': zoomScale,
      'panOffsetX': panOffsetX,
      'panOffsetY': panOffsetY,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy with modified fields.
  SpatialBookmark copyWith({
    String? id,
    String? name,
    double? zoomScale,
    double? panOffsetX,
    double? panOffsetY,
    DateTime? createdAt,
  }) {
    return SpatialBookmark(
      id: id ?? this.id,
      name: name ?? this.name,
      zoomScale: zoomScale ?? this.zoomScale,
      panOffsetX: panOffsetX ?? this.panOffsetX,
      panOffsetY: panOffsetY ?? this.panOffsetY,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
