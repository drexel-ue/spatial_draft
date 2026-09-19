import 'package:flutter/material.dart';

/// Major categories of the procedural form and constructive shape library.
enum FormCategory {
  shapes2D(
    '2D Shapes',
    'Planar primitives & rhythm curves',
    Icons.polyline_rounded,
  ),
  volumes3D(
    '3D Volumes',
    'Spatial geometric solids & cross-contours',
    Icons.view_in_ar_rounded,
  ),
  facial(
    'Facial Features',
    'Eyes, nose, lips & cranial planes',
    Icons.face_rounded,
  ),
  appendages(
    'Limbs & Hands',
    'Arms, legs, hands & kinematic joints',
    Icons.pan_tool_rounded,
  ),
  torso(
    'Core & Torso',
    'Ribcage, pelvis & spinal action line',
    Icons.accessibility_new_rounded,
  );

  FormCategory(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

/// Unique identifiers for every procedural form in the library.
enum ProceduralFormId {
  // 2D Primitives
  circleAxes(
    'circle_axes',
    'Circle & Major Axes',
    FormCategory.shapes2D,
  ),
  perspectiveQuad(
    'perspective_quad',
    'Perspective Quadrilateral',
    FormCategory.shapes2D,
  ),
  dynamicPolygon(
    'dynamic_polygon',
    'Dynamic Polygon & Centroid',
    FormCategory.shapes2D,
  ),
  rhythmSCurve(
    'rhythm_s_curve',
    'Rhythm S-Curve & Accents',
    FormCategory.shapes2D,
  ),
  goldenSpiral(
    'golden_spiral',
    'Logarithmic Golden Spiral',
    FormCategory.shapes2D,
  ),

  // 3D Geometric Volumes
  cubeVoxel(
    'cube_voxel',
    'Bounding Perspective Cube',
    FormCategory.volumes3D,
  ),
  cylinderAxle(
    'cylinder_axle',
    'Cylinder & Axle Contours',
    FormCategory.volumes3D,
  ),
  coneFrustum(
    'cone_frustum',
    'Cone & Truncated Frustum',
    FormCategory.volumes3D,
  ),
  sphereContours(
    'sphere_contours',
    'Sphere Lat / Long Contours',
    FormCategory.volumes3D,
  ),
  torusRing(
    'torus_ring',
    'Torus Cross-Contour Ring',
    FormCategory.volumes3D,
  ),
  inclineWedge(
    'incline_wedge',
    'Perspective Incline Wedge',
    FormCategory.volumes3D,
  ),
  compoundVolumes(
    'compound_volumes',
    'Intersecting Box & Cylinder',
    FormCategory.volumes3D,
  ),

  // Facial & Cranial Anatomy
  eyeOrbit(
    'eye_orbit',
    '3D Eyeball & Eyelid Shells',
    FormCategory.facial,
  ),
  nosePrism(
    'nose_prism',
    'Nasal Keystone & Planes',
    FormCategory.facial,
  ),
  mouthBarrel(
    'mouth_barrel',
    'Dental Arch & Lip Volumes',
    FormCategory.facial,
  ),
  earPlane(
    'ear_plane',
    'Concha & Helix Ear Wedge',
    FormCategory.facial,
  ),

  // Appendages & Extremities
  armCylinders(
    'arm_cylinders',
    'Arm Cylinders & Elbow Joint',
    FormCategory.appendages,
  ),
  legVolumes(
    'leg_volumes',
    'Thigh Sweep & Knee Patella',
    FormCategory.appendages,
  ),
  handSpade(
    'hand_spade',
    'Palm Spade & 5-Digit Rays',
    FormCategory.appendages,
  ),
  footWedge(
    'foot_wedge',
    'Heel Box & Instep Arch Wedge',
    FormCategory.appendages,
  ),

  // Core & Torso Masses
  ribcageEgg(
    'ribcage_egg',
    'Thoracic Egg & Ribcage Box',
    FormCategory.torso,
  ),
  pelvisBucket(
    'pelvis_bucket',
    'Pelvic Bucket & Contrapposto',
    FormCategory.torso,
  ),
  spinalAction(
    'spinal_action',
    'Spinal Action & Disc Stack',
    FormCategory.torso,
  );

  ProceduralFormId(this.code, this.defaultTitle, this.category);

  final String code;
  final String defaultTitle;
  final FormCategory category;
}

/// Definition containing metadata and pedagogical drawing guidance.
class ProceduralFormDefinition {
  const ProceduralFormDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.draftingTip,
    required this.anatomicalLandmarks,
  });

  final ProceduralFormId id;
  final String title;
  final String subtitle;
  final String difficulty;
  final String draftingTip;
  final List<String> anatomicalLandmarks;

  FormCategory get category => id.category;
}

/// Parametric configuration for rendering and posing a procedural form.
class ProceduralFormConfig {
  const ProceduralFormConfig({
    this.yaw = 0.35,
    this.pitch = 0.25,
    this.roll = 0.0,
    this.scale = 1.0,
    this.showWireframe = true,
    this.showAxes = true,
    this.showBoundingBox = true,
    this.showHiddenLines = true,
    this.crossContourCount = 5,
    this.seed = 42,
  });

  /// Horizontal turntable rotation angle in radians.
  final double yaw;

  /// Vertical tilt angle in radians.
  final double pitch;

  /// Roll tilt angle in radians.
  final double roll;

  /// Overall scale multiplier.
  final double scale;

  /// Whether cross-contour wireframe rings and lat/long bands are rendered.
  final bool showWireframe;

  /// Whether primary rotational axles, centers, and action lines are rendered.
  final bool showAxes;

  /// Whether exterior envelope or planar scaffolding is displayed.
  final bool showBoundingBox;

  /// Whether back-facing occluded segments are drawn as dashed hidden lines.
  final bool showHiddenLines;

  /// Number of cross-contour divisions.
  final int crossContourCount;

  /// Procedural seed for randomized organic variations.
  final int seed;

  ProceduralFormConfig copyWith({
    double? yaw,
    double? pitch,
    double? roll,
    double? scale,
    bool? showWireframe,
    bool? showAxes,
    bool? showBoundingBox,
    bool? showHiddenLines,
    int? crossContourCount,
    int? seed,
  }) {
    return ProceduralFormConfig(
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      scale: scale ?? this.scale,
      showWireframe: showWireframe ?? this.showWireframe,
      showAxes: showAxes ?? this.showAxes,
      showBoundingBox: showBoundingBox ?? this.showBoundingBox,
      showHiddenLines: showHiddenLines ?? this.showHiddenLines,
      crossContourCount: crossContourCount ?? this.crossContourCount,
      seed: seed ?? this.seed,
    );
  }
}
