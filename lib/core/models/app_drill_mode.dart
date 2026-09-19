import 'package:flutter/material.dart';

/// Available practice drills and studio modes in SpatialDraft.
enum AppDrillMode {
  /// Week 1 ghosting and kinematic acceleration practice.
  ghosting(
    'Line Quality',
    'Ghosting & Acceleration (Wk 1)',
    Icons.timeline_rounded,
  ),

  /// Week 2 perspective ellipses and major/minor axes.
  ellipse(
    'Ellipses',
    'Perspective Ellipses (Wk 2)',
    Icons.radio_button_unchecked_rounded,
  ),

  /// Week 3 technical isometric 3D voxel carve-outs.
  isometric(
    'Isometric',
    '3D Voxel Carving (Wk 3)',
    Icons.view_in_ar_rounded,
  ),

  /// Loomis method 3D cranial planes and form rotation.
  loomisHead(
    'Loomis Head',
    '3D Cranial Planes (Form)',
    Icons.face_retouching_natural_rounded,
  ),

  /// Kinematic mannequin contrapposto and gesture drawing.
  poseGesture(
    'Pose Gesture',
    'Kinematic Mannequin (Form)',
    Icons.directions_run_rounded,
  ),

  /// Procedural constructive shapes, 3D volumes, and anatomy library.
  formLibrary(
    'Form Library',
    'Procedural Shapes & Anatomy',
    Icons.category_rounded,
  ),

  /// Unconstrained freeform infinite drafting sandbox.
  sandbox(
    'Sandbox',
    'Infinite Drafting Canvas',
    Icons.draw_rounded,
  );

  AppDrillMode(this.shortLabel, this.fullLabel, this.icon);

  /// Compact label for chips and tabs.
  final String shortLabel;

  /// Full descriptive title with syllabus week or discipline.
  final String fullLabel;

  /// Material icon representing the drill discipline.
  final IconData icon;
}
