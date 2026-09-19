import 'package:spatial_draft/core/models/procedural_form.dart';

/// Catalog and registry of all procedural geometric and anatomical forms.
class ProceduralFormRegistry {
  static final List<ProceduralFormDefinition> _definitions = [
    // ----------------- 2D Primitives -----------------
    const ProceduralFormDefinition(
      id: ProceduralFormId.circleAxes,
      title: 'Circle & Major Axes',
      subtitle: 'Geometric Center & Quadrant Scaffolding',
      difficulty: 'Foundational',
      draftingTip:
          'Construct horizontal and vertical axes first. Ellipses and circles '
          'must bisect all four quadrants symmetrically without wobble.',
      anatomicalLandmarks: ['Geometric Center', 'Quadrant Quadrature', 'Crosshairs'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.perspectiveQuad,
      title: 'Perspective Quadrilateral',
      subtitle: 'Foreshortened Planar Grid Scaffolding',
      difficulty: 'Foundational',
      draftingTip:
          'Connect opposite diagonal vertices to find the true perspective center. '
          'Midpoint axes pass through the center toward vanishing points.',
      anatomicalLandmarks: ['Perspective Center', 'Diagonal Cross', 'Vanishing Rays'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.dynamicPolygon,
      title: 'Dynamic Polygon & Centroid',
      subtitle: 'Planar Silhouette & Median Vectors',
      difficulty: 'Foundational',
      draftingTip:
          'Draw median lines from each vertex to the midpoint of the opposite '
          'edge. Their single point of intersection is the center of mass.',
      anatomicalLandmarks: ['Centroid of Mass', 'Vertex Nodes', 'Median Vectors'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.rhythmSCurve,
      title: 'Rhythm S-Curve & Accents',
      subtitle: 'Dynamic Gesture & Force Flow',
      difficulty: 'Intermediate',
      draftingTip:
          'Maintain one continuous acceleration through the inflection point. '
          'Avoid sharp elbows—let the curvature transition smoothly.',
      anatomicalLandmarks: ['Inflection Pivot', 'Tangent Accents', 'Flow Vector'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.goldenSpiral,
      title: 'Logarithmic Golden Spiral',
      subtitle: 'Proportional Subdivision & Growth',
      difficulty: 'Intermediate',
      draftingTip:
          'Subdivide golden rectangles with ratio 1.618. Sweep smooth arcs '
          'through opposing quadrant corners with shoulder momentum.',
      anatomicalLandmarks: ['Whirling Squares', 'Pole Focus', 'Subdivision Rails'],
    ),

    // ----------------- 3D Volumes -----------------
    const ProceduralFormDefinition(
      id: ProceduralFormId.cubeVoxel,
      title: 'Perspective Cube / Voxel',
      subtitle: 'Spatial Bounding Envelope Scaffolding',
      difficulty: 'Foundational',
      draftingTip:
          'Ensure parallel edges converge slightly toward distant vanishing '
          'points. Draw through the form to construct the 3 hidden back edges.',
      anatomicalLandmarks: ['8 Vertex Nodes', 'Silhouette Edges', 'Hidden Lines'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.cylinderAxle,
      title: 'Cylinder & Axle Contours',
      subtitle: 'Rotational Symmetry & Elliptical Cross-Sections',
      difficulty: 'Intermediate',
      draftingTip:
          'The minor axis of both end ellipses must strictly align with the '
          'central rotational axle. Far ellipse is wider due to foreshortening.',
      anatomicalLandmarks: ['Core Axle', 'Tangency Rails', 'Cross-Contour Rings'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.coneFrustum,
      title: 'Cone & Truncated Frustum',
      subtitle: 'Tapering Perspective & Apex Vector',
      difficulty: 'Intermediate',
      draftingTip:
          'Align the altitude axis from the base center to the apex. Tangent '
          'silhouette rays touch the base ellipse at its widest diameter.',
      anatomicalLandmarks: ['Apex Point', 'Base Ellipse', 'Altitude Centerline'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.sphereContours,
      title: 'Sphere Lat / Long Contours',
      subtitle: 'Omnidirectional Volumetric Mass',
      difficulty: 'Foundational',
      draftingTip:
          'A sphere always has a circular silhouette regardless of rotation. '
          'Latitude and longitude ellipses define its 3D spatial orientation.',
      anatomicalLandmarks: ['Equator Band', 'Pole Axis', 'Great Circle Cross'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.torusRing,
      title: 'Torus Cross-Contour Ring',
      subtitle: 'Revolved Cross-Sectional Geometry',
      difficulty: 'Advanced',
      draftingTip:
          'Construct the circular path orbit first, then revolve cross-sectional '
          'circular contour rings around the central hole axis.',
      anatomicalLandmarks: ['Major Orbit', 'Minor Cross-Sections', 'Inner Rim'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.inclineWedge,
      title: 'Perspective Incline Wedge',
      subtitle: 'Ramp Planes & Auxiliary Vanishing Points',
      difficulty: 'Intermediate',
      draftingTip:
          'The inclined plane slopes upward to an auxiliary vanishing point '
          'located vertically above the ground vanishing point.',
      anatomicalLandmarks: ['Incline Slope', 'Ground Base', 'Plumb Wall'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.compoundVolumes,
      title: 'Intersecting Box & Cylinder',
      subtitle: 'Compound Masses & Penetration Curves',
      difficulty: 'Advanced',
      draftingTip:
          'Map where the curved surface of the cylinder penetrates the planar '
          'walls of the box. The intersection creates saddle-curve seams.',
      anatomicalLandmarks: ['Intersection Seam', 'Box Facet', 'Cylinder Core'],
    ),

    // ----------------- Facial & Cranial Anatomy -----------------
    const ProceduralFormDefinition(
      id: ProceduralFormId.eyeOrbit,
      title: '3D Eyeball & Eyelid Shells',
      subtitle: 'Orbital Sphere & Curved Eyelid Volumes',
      difficulty: 'Intermediate',
      draftingTip:
          'The eye is a sphere embedded in the orbital socket. Upper and lower '
          'eyelids have visible thickness and wrap across the sphere curvature.',
      anatomicalLandmarks: ['Eyeball Sphere', 'Upper Lid Fold', 'Tear Duct Caruncle', 'Pupil / Iris'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.nosePrism,
      title: 'Nasal Keystone & Planes',
      subtitle: 'Architectural Bridge, Ball & Nostril Wings',
      difficulty: 'Intermediate',
      draftingTip:
          'Block the nose as a 4-sided trapezoidal prism: top plane, two side '
          'slopes, and bottom triangular under-plane with nostrils.',
      anatomicalLandmarks: ['Keystone Glabella', 'Bridge Ridge', 'Nasal Ball', 'Alar Cartilage'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.mouthBarrel,
      title: 'Dental Arch & Lip Volumes',
      subtitle: 'Cylindrical Muzzle & Muscular Pads',
      difficulty: 'Intermediate',
      draftingTip:
          'The teeth form a cylindrical muzzle barrel. The upper lip has 3 '
          'fullness pads (1 center, 2 side), lower lip has 2 lateral pillows.',
      anatomicalLandmarks: ['Maxillary Barrel', 'Philtrum Column', 'Lip Pillows', 'Corner Nodes'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.earPlane,
      title: 'Concha & Helix Ear Wedge',
      subtitle: 'Spiral Cartilage & Planar Tilts',
      difficulty: 'Advanced',
      draftingTip:
          'The ear aligns with the brow line and nose base, tilting backward '
          'parallel to the jawline. Construct the C-shape outer helix first.',
      anatomicalLandmarks: ['Helix Rim', 'Concha Bowl', 'Tragus Notch', 'Lobule'],
    ),

    // ----------------- Appendages & Extremities -----------------
    const ProceduralFormDefinition(
      id: ProceduralFormId.armCylinders,
      title: 'Arm Cylinders & Elbow Joint',
      subtitle: 'Deltoid Interlock & Tapering Forearm',
      difficulty: 'Intermediate',
      draftingTip:
          'The teardrop deltoid clasps between the bicep and tricep. The forearm '
          'tapers into a flattened box at the wrist joint.',
      anatomicalLandmarks: ['Deltoid Clasp', 'Bicep Cylinder', 'Elbow Hinge', 'Forearm Wedge'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.legVolumes,
      title: 'Leg Volumes & Knee Patella',
      subtitle: 'Quadriceps Rhythm & Tibia S-Curve',
      difficulty: 'Intermediate',
      draftingTip:
          'The thigh sweeps forward with an S-curve rhythm. The knee is a '
          'distinct boxy hinge (patella) connecting to the tibial crest.',
      anatomicalLandmarks: ['Thigh Cylinder', 'Patella Box', 'Calf Gastrocnemius', 'Ankle Malleoli'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.handSpade,
      title: 'Hand Spade & 5-Digit Rays',
      subtitle: 'Metacarpal Wedge & Articulated Phalanges',
      difficulty: 'Advanced',
      draftingTip:
          'The palm is a curved spade wedge thicker at the heel. Fingers radiate '
          'in arches with cylindrical segments and planar box knuckles.',
      anatomicalLandmarks: ['Palm Arch', 'Thenar Thumb Pad', 'Knuckle Ridge', 'Phalange Segments'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.footWedge,
      title: 'Foot Wedge & Instep Arch',
      subtitle: 'Calcaneus Block & Tarsal Bridge',
      difficulty: 'Advanced',
      draftingTip:
          'The foot is an asymmetrical triangular wedge. The inner arch is high '
          'and hollowed; the outer arch rests flat on the ground plane.',
      anatomicalLandmarks: ['Heel Calcaneus', 'Medial High Arch', 'Metatarsal Ball', 'Toe Pads'],
    ),

    // ----------------- Core & Torso Masses -----------------
    const ProceduralFormDefinition(
      id: ProceduralFormId.ribcageEgg,
      title: 'Thoracic Egg & Ribcage Box',
      subtitle: 'Thoracic Volume, Sternum & Clavicle Bar',
      difficulty: 'Intermediate',
      draftingTip:
          'Treat the ribcage as an ovoid volume with a flattened back. The '
          'sternum defines the anterior centerline and thoracic arch base.',
      anatomicalLandmarks: ['Clavicle Bar', 'Sternum Line', 'Thoracic Arch', '10th Rib Base'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.pelvisBucket,
      title: 'Pelvic Bucket & Contrapposto',
      subtitle: 'Planar Pelvic Bowl & Opposing Tilts',
      difficulty: 'Intermediate',
      draftingTip:
          'The pelvis is a tilted bowl/bucket. In standing poses, its tilt '
          'opposes the ribcage tilt (contrapposto) to balance the gravity line.',
      anatomicalLandmarks: ['Iliac Crest Rim', 'ASIS Spines', 'Pubic Symphysis', 'Sacral Triangle'],
    ),
    const ProceduralFormDefinition(
      id: ProceduralFormId.spinalAction,
      title: 'Spinal Action & Disc Stack',
      subtitle: 'Line of Action & Intervertebral Cylinders',
      difficulty: 'Foundational',
      draftingTip:
          'The human spine has 4 natural curvature sweeps (cervical, thoracic, '
          'lumbar, sacral). Draw stacked contour discs to show 3D twist.',
      anatomicalLandmarks: ['Cervical Lordosis', 'Thoracic Kyphosis', 'Lumbar Arch', 'Sacral Anchor'],
    ),
  ];

  /// Retrieves all procedural form definitions.
  static List<ProceduralFormDefinition> getAllDefinitions() {
    return List.unmodifiable(_definitions);
  }

  /// Filters definitions by category.
  static List<ProceduralFormDefinition> getDefinitionsByCategory(
    FormCategory category,
  ) {
    return _definitions.where((d) => d.category == category).toList();
  }

  /// Searches definitions by query string matching title, subtitle, or tip.
  static List<ProceduralFormDefinition> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getAllDefinitions();
    return _definitions.where((d) {
      return d.title.toLowerCase().contains(clean) ||
          d.subtitle.toLowerCase().contains(clean) ||
          d.draftingTip.toLowerCase().contains(clean) ||
          d.anatomicalLandmarks.any((l) => l.toLowerCase().contains(clean));
    }).toList();
  }

  /// Gets a definition by its ID with fallback.
  static ProceduralFormDefinition getById(ProceduralFormId id) {
    return _definitions.firstWhere(
      (d) => d.id == id,
      orElse: () => _definitions.first,
    );
  }
}
