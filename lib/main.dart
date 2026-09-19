import 'package:flutter/material.dart';
import 'core/models/skill_profile.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/skill_profile_dialog.dart';
import 'drills/common/concept_guide_sheet.dart';
import 'drills/form/loomis_head_drill.dart';
import 'drills/form/pose_mannequin_drill.dart';
import 'drills/precision/ellipse_drill.dart';
import 'drills/precision/ghosting_drill.dart';
import 'drills/precision/isometric_drill.dart';
import 'drills/sandbox/freeform_sandbox.dart';
import 'onboarding/onboarding_modal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpatialDraftApp());
}

enum AppDrillMode {
  ghosting('Line Quality', 'Ghosting & Acceleration (Wk 1)', Icons.timeline_rounded),
  ellipse('Ellipses', 'Perspective Ellipses (Wk 2)', Icons.radio_button_unchecked_rounded),
  isometric('Isometric', '3D Voxel Carving (Wk 3)', Icons.view_in_ar_rounded),
  loomisHead('Loomis Head', '3D Cranial Planes (Form)', Icons.face_retouching_natural_rounded),
  poseGesture('Pose Gesture', 'Kinematic Mannequin (Form)', Icons.directions_run_rounded),
  sandbox('Sandbox', 'Infinite Drafting Canvas', Icons.draw_rounded);

  final String shortLabel;
  final String fullLabel;
  final IconData icon;
  const AppDrillMode(this.shortLabel, this.fullLabel, this.icon);
}

class SpatialDraftApp extends StatefulWidget {
  final bool autoShowOnboarding;

  const SpatialDraftApp({
    super.key,
    this.autoShowOnboarding = true,
  });

  @override
  State<SpatialDraftApp> createState() => _SpatialDraftAppState();
}

class _SpatialDraftAppState extends State<SpatialDraftApp> {
  AppThemeMode _themeMode = AppThemeMode.dark;

  void _setThemeMode(AppThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeTokens.of(_themeMode);

    return MaterialApp(
      title: 'SpatialDraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _themeMode == AppThemeMode.light ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: theme.canvasBackground,
      ),
      home: DraftingStudioScreen(
        themeMode: _themeMode,
        onThemeChanged: _setThemeMode,
        autoShowOnboarding: widget.autoShowOnboarding,
      ),
    );
  }
}

class DraftingStudioScreen extends StatefulWidget {
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final bool autoShowOnboarding;

  const DraftingStudioScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.autoShowOnboarding,
  });

  @override
  State<DraftingStudioScreen> createState() => _DraftingStudioScreenState();
}

class _DraftingStudioScreenState extends State<DraftingStudioScreen> {
  GridStyle _gridStyle = GridStyle.solid;
  GridType _gridType = GridType.squareMetric;
  AppDrillMode _currentDrill = AppDrillMode.ghosting;

  final SkillProfile _skillProfile = SkillProfile();
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoShowOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasSeenOnboarding && mounted) {
          _showOnboarding();
        }
      });
    }
  }

  void _showOnboarding() {
    final theme = AppThemeTokens.of(widget.themeMode);
    OnboardingModal.show(
      context: context,
      theme: theme,
      onComplete: () => setState(() => _hasSeenOnboarding = true),
    );
  }

  void _openSkillProfile() {
    final theme = AppThemeTokens.of(widget.themeMode);
    SkillProfileDialog.show(
      context: context,
      profile: _skillProfile,
      theme: theme,
    );
  }

  void _openActiveGuide() {
    final theme = AppThemeTokens.of(widget.themeMode);
    switch (_currentDrill) {
      case AppDrillMode.ghosting:
        ConceptGuideSheet.show(
          context: context,
          drillTitle: 'The Ghosting Method',
          categorySubtitle: 'Motor Control & Kinematics',
          theme: theme,
          sections: const [
            GuideSectionItem(
              title: 'Shoulder Biomechanics',
              content:
                  'Lock your wrist and elbow. Drive the stylus from your shoulder ball-and-socket joint to avoid curved arcs.',
              icon: Icons.fitness_center_rounded,
            ),
            GuideSectionItem(
              title: 'The Ghosting Protocol',
              content:
                  'Hover 2 to 3 times along the vector. Strike through with unbroken, confident speed.',
              icon: Icons.air_rounded,
            ),
            GuideSectionItem(
              title: 'Scoring Acceleration (d²s/dt²)',
              content:
                  'Hesitation wobbles and mid-stroke slowing down are penalized more than minor aim offset.',
              icon: Icons.speed_rounded,
            ),
          ],
        );
        break;
      case AppDrillMode.ellipse:
        ConceptGuideSheet.show(
          context: context,
          drillTitle: 'Perspective Ellipses',
          categorySubtitle: 'Spatial Volume & Form',
          theme: theme,
          sections: const [
            GuideSectionItem(
              title: 'The Minor Axis Rule',
              content:
                  'The minor axis must strictly align with the 3D cylinder axle. Parallel lines remain parallel.',
              icon: Icons.rotate_right_rounded,
            ),
            GuideSectionItem(
              title: 'Four-Point Tangency',
              content:
                  'Touch all 4 bounding edges with smooth curved contact points.',
              icon: Icons.border_clear_rounded,
            ),
          ],
        );
        break;
      case AppDrillMode.isometric:
        ConceptGuideSheet.show(
          context: context,
          drillTitle: 'Isometric Carve-Outs',
          categorySubtitle: 'Technical Draftsmanship (ISO 128)',
          theme: theme,
          sections: const [
            GuideSectionItem(
              title: 'Subtractive Thinking',
              content:
                  'Always establish the maximum bounding billet, then carve away negative space steps and slots.',
              icon: Icons.view_in_ar_rounded,
            ),
            GuideSectionItem(
              title: 'Line Weight Hierarchy',
              content:
                  'Silhouette = 3.5px Thick, Crease = 2.0px Medium, Hidden Geometry = 1.2px Dashed.',
              icon: Icons.line_weight_rounded,
            ),
          ],
        );
        break;
      case AppDrillMode.loomisHead:
        ConceptGuideSheet.show(
          context: context,
          drillTitle: 'The Loomis Cranial Ball',
          categorySubtitle: 'Volumetric Form & Anatomy',
          theme: theme,
          sections: const [
            GuideSectionItem(
              title: 'Cranial Sphere & Temporal Slice',
              content:
                  'The head begins as a sphere with two flat side cuts. Your perspective ellipse skills define these cuts.',
              icon: Icons.face_rounded,
            ),
            GuideSectionItem(
              title: 'Brow & Center Cross',
              content:
                  'Two great circles intersect at 90° to anchor the eye orbits and nose bridge.',
              icon: Icons.architecture_rounded,
            ),
          ],
        );
        break;
      case AppDrillMode.poseGesture:
        ConceptGuideSheet.show(
          context: context,
          drillTitle: 'Kinematic Gesture & Volumes',
          categorySubtitle: 'Dynamic Form & Mannequin',
          theme: theme,
          sections: const [
            GuideSectionItem(
              title: 'Line of Action',
              content:
                  'Capture the kinetic thrust in one fluid spine stroke before drawing volumes.',
              icon: Icons.flash_on_rounded,
            ),
            GuideSectionItem(
              title: 'Opposing Tilts',
              content:
                  'When shoulders tilt down to the left, the pelvis tilts up to the left (contrapposto).',
              icon: Icons.compare_arrows_rounded,
            ),
          ],
        );
        break;
      case AppDrillMode.sandbox:
        ConceptGuideSheet.show(
          context: context,
          drillTitle: 'Infinite Drafting Sandbox',
          categorySubtitle: 'Freeform Studio',
          theme: theme,
          sections: const [
            GuideSectionItem(
              title: 'Infinite Canvas Pan & Zoom',
              content:
                  'Two fingers pan and zoom infinitely. Apple Pencil draws with zero palm touch interference.',
              icon: Icons.zoom_out_map_rounded,
            ),
            GuideSectionItem(
              title: 'Switching Grids & Themes',
              content:
                  'Toggle between Light Studio, Dark Obsidian, and Blueprint modes with Solid, Dotted, or Dashed grids.',
              icon: Icons.palette_rounded,
            ),
          ],
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeTokens.of(widget.themeMode);

    return Scaffold(
      backgroundColor: theme.canvasBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top Technical App Bar
            _buildTopBar(theme),

            // Active Drill View
            Expanded(
              child: _buildActiveDrill(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppThemeTokens theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        border: Border(bottom: BorderSide(color: theme.borderSubtle, width: 1.2)),
      ),
      child: Row(
        children: [
          // Logo & Branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.accentCyan.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.architecture_rounded, color: theme.accentCyan, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPATIAL DRAFT',
                    style: theme.headingStyle.copyWith(
                      fontSize: 13,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'ADAPTIVE KINEMATIC DRAFTING',
                    style: theme.monoStyle.copyWith(
                      fontSize: 8,
                      letterSpacing: 0.8,
                      color: theme.secondaryInk,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Drill Selector Chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppDrillMode.values.map((drill) {
                  final isSelected = _currentDrill == drill;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _currentDrill = drill),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.borderHighlight.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? theme.borderHighlight : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              drill.icon,
                              size: 14,
                              color: isSelected ? theme.borderHighlight : theme.secondaryInk,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              drill.shortLabel,
                              style: theme.headingStyle.copyWith(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? theme.borderHighlight : theme.secondaryInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Theme Switcher Menu (Light, Dark, Blueprint)
          PopupMenuButton<AppThemeMode>(
            tooltip: 'App Theme',
            initialValue: widget.themeMode,
            onSelected: (mode) => widget.onThemeChanged(mode),
            icon: Icon(
              widget.themeMode == AppThemeMode.light
                  ? Icons.light_mode_outlined
                  : (widget.themeMode == AppThemeMode.dark ? Icons.dark_mode_outlined : Icons.brush_outlined),
              size: 20,
              color: theme.defaultInk,
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: AppThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Light Studio'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Dark Obsidian'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppThemeMode.blueprint,
                child: Row(
                  children: [
                    Icon(Icons.brush_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Drafting Blueprint'),
                  ],
                ),
              ),
            ],
          ),

          // Grid Style Selector (Solid, Dotted, Dashed, None)
          PopupMenuButton<GridStyle>(
            tooltip: 'Grid Line Style',
            initialValue: _gridStyle,
            onSelected: (style) => setState(() => _gridStyle = style),
            icon: Icon(Icons.grid_4x4_rounded, size: 20, color: theme.defaultInk),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: GridStyle.solid, child: Text('Solid Lines')),
              const PopupMenuItem(value: GridStyle.dotted, child: Text('Dotted Grid')),
              const PopupMenuItem(value: GridStyle.dashed, child: Text('Dashed Lines')),
              const PopupMenuItem(value: GridStyle.none, child: Text('No Grid (Blank)')),
            ],
          ),

          // Grid Type Selector (Square, Isometric, Perspective)
          PopupMenuButton<GridType>(
            tooltip: 'Grid Projection',
            initialValue: _gridType,
            onSelected: (type) => setState(() => _gridType = type),
            icon: Icon(Icons.straighten_rounded, size: 20, color: theme.defaultInk),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: GridType.squareMetric, child: Text('Square Metric')),
              const PopupMenuItem(value: GridType.isometric, child: Text('Isometric 30°')),
              const PopupMenuItem(value: GridType.perspective, child: Text('Perspective Vanishing')),
            ],
          ),

          const VerticalDivider(width: 20, indent: 14, endIndent: 14),

          // Neuromotor Profile Button
          IconButton(
            tooltip: 'Neuromotor Skill Matrix',
            icon: Icon(Icons.hub_rounded, color: theme.accentCyan, size: 20),
            onPressed: _openSkillProfile,
          ),

          // Concept Guide [ℹ️]
          IconButton(
            tooltip: 'Concept Guide & Scoring Formulas',
            icon: Icon(Icons.info_outline_rounded, color: theme.accentAmber, size: 20),
            onPressed: _openActiveGuide,
          ),

          // Orientation Primer [?]
          IconButton(
            tooltip: 'Replay Orientation Primer',
            icon: Icon(Icons.help_outline_rounded, color: theme.secondaryInk, size: 20),
            onPressed: _showOnboarding,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDrill(AppThemeTokens theme) {
    switch (_currentDrill) {
      case AppDrillMode.ghosting:
        return GhostingDrill(
          theme: theme,
          gridStyle: _gridStyle,
          gridType: _gridType,
          skillProfile: _skillProfile,
          onProfileUpdated: () => setState(() {}),
        );
      case AppDrillMode.ellipse:
        return EllipseDrill(
          theme: theme,
          gridStyle: _gridStyle,
          gridType: _gridType,
          skillProfile: _skillProfile,
          onProfileUpdated: () => setState(() {}),
        );
      case AppDrillMode.isometric:
        return IsometricDrill(
          theme: theme,
          gridStyle: _gridStyle,
          gridType: _gridType,
          skillProfile: _skillProfile,
          onProfileUpdated: () => setState(() {}),
        );
      case AppDrillMode.loomisHead:
        return LoomisHeadDrill(
          theme: theme,
          gridStyle: _gridStyle,
          gridType: _gridType,
          skillProfile: _skillProfile,
          onProfileUpdated: () => setState(() {}),
        );
      case AppDrillMode.poseGesture:
        return PoseMannequinDrill(
          theme: theme,
          gridStyle: _gridStyle,
          gridType: _gridType,
          skillProfile: _skillProfile,
          onProfileUpdated: () => setState(() {}),
        );
      case AppDrillMode.sandbox:
        return FreeformSandbox(
          theme: theme,
          gridStyle: _gridStyle,
          gridType: _gridType,
        );
    }
  }
}
