/// Represents a saved multi-scale or 3D waypoint for cinematic fly-through.
class SpatialBookmark {
  /// Creates a [SpatialBookmark].
  const SpatialBookmark({
    required this.id,
    required this.name,
    required this.zoomScale,
    this.panOffsetX = 0.0,
    this.panOffsetY = 0.0,
    this.cameraYaw,
    this.cameraPitch,
    this.cameraDistance,
    this.targetPlaneId,
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
      cameraYaw: (json['cameraYaw'] as num?)?.toDouble(),
      cameraPitch: (json['cameraPitch'] as num?)?.toDouble(),
      cameraDistance: (json['cameraDistance'] as num?)?.toDouble(),
      targetPlaneId: json['targetPlaneId'] as String?,
      createdAt: createdStr != null
          ? DateTime.tryParse(createdStr) ?? now
          : now,
    );
  }

  /// Factory helper for creating a 3D orbital camera keyframe waypoint.
  factory SpatialBookmark.waypoint3D({
    required String id,
    required String name,
    required double cameraYaw,
    required double cameraPitch,
    required double cameraDistance,
    String? targetPlaneId,
    DateTime? createdAt,
  }) {
    return SpatialBookmark(
      id: id,
      name: name,
      zoomScale: 1.0,
      cameraYaw: cameraYaw,
      cameraPitch: cameraPitch,
      cameraDistance: cameraDistance,
      targetPlaneId: targetPlaneId,
      createdAt: createdAt ?? DateTime.now(),
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

  /// Orbital camera yaw angle in radians (for 3D Mental Canvas tours).
  final double? cameraYaw;

  /// Orbital camera pitch angle in radians (for 3D Mental Canvas tours).
  final double? cameraPitch;

  /// Orbital camera distance in pixels (for 3D Mental Canvas tours).
  final double? cameraDistance;

  /// Optional active plane ID focused at this 3D camera vantage point.
  final String? targetPlaneId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Whether this bookmark represents a 3D orbital camera vantage point.
  bool get is3D => cameraYaw != null && cameraPitch != null;

  /// Serializes this [SpatialBookmark] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zoomScale': zoomScale,
      'panOffsetX': panOffsetX,
      'panOffsetY': panOffsetY,
      'createdAt': createdAt.toIso8601String(),
      if (cameraYaw != null) 'cameraYaw': cameraYaw,
      if (cameraPitch != null) 'cameraPitch': cameraPitch,
      if (cameraDistance != null) 'cameraDistance': cameraDistance,
      if (targetPlaneId != null) 'targetPlaneId': targetPlaneId,
    };
  }

  /// Creates a copy with modified fields.
  SpatialBookmark copyWith({
    String? id,
    String? name,
    double? zoomScale,
    double? panOffsetX,
    double? panOffsetY,
    double? cameraYaw,
    double? cameraPitch,
    double? cameraDistance,
    String? targetPlaneId,
    DateTime? createdAt,
  }) {
    return SpatialBookmark(
      id: id ?? this.id,
      name: name ?? this.name,
      zoomScale: zoomScale ?? this.zoomScale,
      panOffsetX: panOffsetX ?? this.panOffsetX,
      panOffsetY: panOffsetY ?? this.panOffsetY,
      cameraYaw: cameraYaw ?? this.cameraYaw,
      cameraPitch: cameraPitch ?? this.cameraPitch,
      cameraDistance: cameraDistance ?? this.cameraDistance,
      targetPlaneId: targetPlaneId ?? this.targetPlaneId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
