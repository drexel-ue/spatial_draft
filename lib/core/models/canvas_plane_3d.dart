import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Represents an oriented 2D sketching plane positioned in 3D spatial space.
class CanvasPlane3D {
  /// Creates a [CanvasPlane3D].
  const CanvasPlane3D({
    required this.id,
    required this.name,
    this.originX = 0.0,
    this.originY = 0.0,
    this.originZ = 0.0,
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.width = 2000.0,
    this.height = 2000.0,
    this.colorValue = 0xFF00FFCC,
    this.opacity = 0.85,
    this.isLocked = false,
  });

  /// Factory template: primary front-facing elevation plane.
  factory CanvasPlane3D.primaryFront() {
    return const CanvasPlane3D(
      id: 'plane_primary',
      name: 'Primary Canvas (XY)',
      originX: 0.0,
      originY: 0.0,
      originZ: 0.0,
      colorValue: 0xFF00FFCC,
    );
  }

  /// Factory template: horizontal ground/floor plane.
  factory CanvasPlane3D.groundFloor() {
    return const CanvasPlane3D(
      id: 'plane_ground',
      name: 'Ground Plane (XZ)',
      originX: 0.0,
      originY: 450.0,
      originZ: 0.0,
      pitch: math.pi / 2.0, // 90 degrees
      colorValue: 0xFF38BDF8,
    );
  }

  /// Factory template: vertical left wall plane.
  factory CanvasPlane3D.leftWall() {
    return const CanvasPlane3D(
      id: 'plane_wall_left',
      name: 'Left Wall (YZ)',
      originX: -450.0,
      originY: 0.0,
      originZ: 0.0,
      yaw: math.pi / 2.0, // 90 degrees
      colorValue: 0xFFF59E0B,
    );
  }

  /// Factory template: vertical right wall plane.
  factory CanvasPlane3D.rightWall() {
    return const CanvasPlane3D(
      id: 'plane_wall_right',
      name: 'Right Wall (YZ)',
      originX: 450.0,
      originY: 0.0,
      originZ: 0.0,
      yaw: -math.pi / 2.0, // -90 degrees
      colorValue: 0xFFA855F7,
    );
  }

  /// Factory template: recessed background depth plane.
  factory CanvasPlane3D.backdrop() {
    return const CanvasPlane3D(
      id: 'plane_backdrop',
      name: 'Backdrop Plane (Z-Depth)',
      originX: 0.0,
      originY: 0.0,
      originZ: -600.0,
      colorValue: 0xFF10B981,
    );
  }

  /// Deserializes a [CanvasPlane3D] from JSON map.
  factory CanvasPlane3D.fromJson(Map<String, dynamic> json) {
    final nowMicros = DateTime.now().microsecondsSinceEpoch;
    return CanvasPlane3D(
      id: json['id'] as String? ?? 'plane_$nowMicros',
      name: json['name'] as String? ?? 'Spatial Plane',
      originX: (json['originX'] as num?)?.toDouble() ?? 0.0,
      originY: (json['originY'] as num?)?.toDouble() ?? 0.0,
      originZ: (json['originZ'] as num?)?.toDouble() ?? 0.0,
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      roll: (json['roll'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 2000.0,
      height: (json['height'] as num?)?.toDouble() ?? 2000.0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF00FFCC,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.85,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  /// Unique plane identifier.
  final String id;

  /// User-visible name label.
  final String name;

  /// World space 3D origin X.
  final double originX;

  /// World space 3D origin Y.
  final double originY;

  /// World space 3D origin Z.
  final double originZ;

  /// Euler yaw angle around Y axis (in radians).
  final double yaw;

  /// Euler pitch angle around X axis (in radians).
  final double pitch;

  /// Euler roll angle around Z axis (in radians).
  final double roll;

  /// Plane width in local spatial units.
  final double width;

  /// Plane height in local spatial units.
  final double height;

  /// Boundary wireframe color int.
  final int colorValue;

  /// Rendering opacity.
  final double opacity;

  /// Whether drawing on this plane is currently locked.
  final bool isLocked;

  /// Color representation of [colorValue].
  Color get color => Color(colorValue);

  /// Transforms a 2D local plane coordinate (u, v) into 3D world space (x, y, z).
  List<double> project2Dto3D(Offset uv) {
    final u = uv.dx;
    final v = uv.dy;

    // 1. Roll rotation (around Z)
    final cosR = math.cos(roll);
    final sinR = math.sin(roll);
    final x1 = u * cosR - v * sinR;
    final y1 = u * sinR + v * cosR;
    const z1 = 0.0;

    // 2. Pitch rotation (around X)
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);
    final x2 = x1;
    final y2 = y1 * cosP - z1 * sinP;
    final z2 = y1 * sinP + z1 * cosP;

    // 3. Yaw rotation (around Y)
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final x3 = x2 * cosY + z2 * sinY;
    final y3 = y2;
    final z3 = -x2 * sinY + z2 * cosY;

    return [originX + x3, originY + y3, originZ + z3];
  }

  /// Transforms a 3D world coordinate (x, y, z) into a 2D local plane coordinate.
  Offset project3Dto2D(double wx, double wy, double wz) {
    // Relative to origin
    final rx = wx - originX;
    final ry = wy - originY;
    final rz = wz - originZ;

    // Inverse Yaw (around Y by -yaw)
    final cosY = math.cos(-yaw);
    final sinY = math.sin(-yaw);
    final x2 = rx * cosY + rz * sinY;
    final y2 = ry;
    final z2 = -rx * sinY + rz * cosY;

    // Inverse Pitch (around X by -pitch)
    final cosP = math.cos(-pitch);
    final sinP = math.sin(-pitch);
    final x1 = x2;
    final y1 = y2 * cosP - z2 * sinP;

    // Inverse Roll (around Z by -roll)
    final cosR = math.cos(-roll);
    final sinR = math.sin(-roll);
    final u = x1 * cosR - y1 * sinR;
    final v = x1 * sinR + y1 * cosR;

    return Offset(u, v);
  }

  /// Returns the 3D unit normal vector of this plane.
  List<double> get normalVector {
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);

    final nx = cosP * sinY;
    final ny = -sinP;
    final nz = cosP * cosY;
    return [nx, ny, nz];
  }

  /// Intersects a camera ray passing through [screenPos] with this 3D plane.
  /// Returns local (u, v) on the plane, or null if ray is parallel or behind.
  Offset? intersectRay({
    required Offset screenPos,
    required Size screenSize,
    required double cameraYaw,
    required double cameraPitch,
    required double cameraDistance,
  }) {
    final center = Offset(screenSize.width / 2.0, screenSize.height / 2.0);

    // 1. Camera position in world space: Eye is at (0, 0, -cameraDistance)
    // transformed by inverse pitch then inverse yaw.
    final cosP = math.cos(cameraPitch);
    final sinP = math.sin(cameraPitch);
    final cosY = math.cos(cameraYaw);
    final sinY = math.sin(cameraYaw);

    final camX = cameraDistance * cosP * sinY;
    final camY = -cameraDistance * sinP;
    final camZ = -cameraDistance * cosP * cosY;

    // 2. Unprojected ray direction through screenPos:
    // Screen point in camera space is (dxC, dyC, 0).
    // Ray vector V = (dxC, dyC, 0) - (0, 0, -cameraDistance)
    //              = (dxC, dyC, cameraDistance).
    final dxC = screenPos.dx - center.dx;
    final dyC = screenPos.dy - center.dy;
    final dzC = cameraDistance;

    // Inverse pitch rotation
    final vx1 = dxC;
    final vy1 = dyC * cosP + dzC * sinP;
    final vz1 = -dyC * sinP + dzC * cosP;

    // Inverse yaw rotation
    final dxW = vx1 * cosY - vz1 * sinY;
    final dyW = vy1;
    final dzW = vx1 * sinY + vz1 * cosY;

    final len = math.sqrt(dxW * dxW + dyW * dyW + dzW * dzW);
    if (len <= 0) return null;
    final rdx = dxW / len;
    final rdy = dyW / len;
    final rdz = dzW / len;

    // 3. Plane normal and origin
    final norm = normalVector;
    final denom = rdx * norm[0] + rdy * norm[1] + rdz * norm[2];
    if (denom.abs() < 1e-4) return null;

    final t = ((originX - camX) * norm[0] +
            (originY - camY) * norm[1] +
            (originZ - camZ) * norm[2]) /
        denom;

    if (t <= 0) return null;

    final wx = camX + t * rdx;
    final wy = camY + t * rdy;
    final wz = camZ + t * rdz;

    return project3Dto2D(wx, wy, wz);
  }

  /// Serializes this [CanvasPlane3D] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originX': originX,
      'originY': originY,
      'originZ': originZ,
      'yaw': yaw,
      'pitch': pitch,
      'roll': roll,
      'width': width,
      'height': height,
      'colorValue': colorValue,
      'opacity': opacity,
      'isLocked': isLocked,
    };
  }

  /// Creates a copy with modified fields.
  CanvasPlane3D copyWith({
    String? id,
    String? name,
    double? originX,
    double? originY,
    double? originZ,
    double? yaw,
    double? pitch,
    double? roll,
    double? width,
    double? height,
    int? colorValue,
    double? opacity,
    bool? isLocked,
  }) {
    return CanvasPlane3D(
      id: id ?? this.id,
      name: name ?? this.name,
      originX: originX ?? this.originX,
      originY: originY ?? this.originY,
      originZ: originZ ?? this.originZ,
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      width: width ?? this.width,
      height: height ?? this.height,
      colorValue: colorValue ?? this.colorValue,
      opacity: opacity ?? this.opacity,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
