import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:spatial_draft/core/models/app_drill_mode.dart';
import 'package:spatial_draft/core/models/draft_capture.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/skill_profile_dialog.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';
import 'package:spatial_draft/drills/form/loomis_head_drill.dart';
import 'package:spatial_draft/drills/form/pose_mannequin_drill.dart';
import 'package:spatial_draft/drills/precision/ellipse_drill.dart';
import 'package:spatial_draft/drills/precision/ghosting_drill.dart';
import 'package:spatial_draft/drills/precision/isometric_drill.dart';
import 'package:spatial_draft/drills/sandbox/freeform_sandbox.dart';
import 'package:spatial_draft/onboarding/onboarding_modal.dart';
import 'package:spatial_draft/onboarding/splash_screen.dart';
import 'package:spatial_draft/services/app_log_service.dart';
import 'package:spatial_draft/services/gallery_service.dart';
import 'package:spatial_draft/views/diagnostics/crash_report_screen.dart';
import 'package:spatial_draft/views/gallery/gallery_screen.dart';

export 'package:spatial_draft/core/models/app_drill_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging and crash reporting first
  await AppLogService.instance.init();

  // Initialize draft gallery archive
  await GalleryService.instance.init();

  // Global Flutter framework error hook
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogService.instance.crash(
      'FLUTTER_FRAMEWORK',
      details.exceptionAsString(),
      stackTrace: details.stack,
    );
  };

  // Global uncaught asynchronous errors hook
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogService.instance.crash(
      'UNCAUGHT_ASYNC',
      error.toString(),
      stackTrace: stack,
    );
    return true; // prevent application from dying
  };

  AppLogService.instance.info(
    'SYSTEM',
    'SpatialDraft application initialized',
  );

  runApp(const SpatialDraftApp());
}

class SpatialDraftApp extends StatefulWidget {

  const SpatialDraftApp({
    super.key,
    this.autoShowOnboarding = true,
    this.showSplash = false, // false for tests, toggleable
  });
  final bool autoShowOnboarding;
  final bool showSplash;

  @override
  State<SpatialDraftApp> createState() => _SpatialDraftAppState();
}

class _SpatialDraftAppState extends State<SpatialDraftApp> {
  AppThemeMode _themeMode = AppThemeMode.dark;
  late bool _displaySplash;

  @override
  void initState() {
    super.initState();
    _displaySplash = widget.showSplash;
  }

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
      home: _displaySplash
          ? SplashScreen(
              onFinish: () => setState(() => _displaySplash = false),
            )
          : DraftingStudioScreen(
              themeMode: _themeMode,
              onThemeChanged: _setThemeMode,
              autoShowOnboarding: widget.autoShowOnboarding,
              onReplaySplash: () => setState(() => _displaySplash = true),
            ),
    );
  }
}

class DraftingStudioScreen extends StatefulWidget {

  const DraftingStudioScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.autoShowOnboarding,
    this.onReplaySplash,
  });
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final bool autoShowOnboarding;
  final VoidCallback? onReplaySplash;

  @override
  State<DraftingStudioScreen> createState() => _DraftingStudioScreenState();
}

class _DraftingStudioScreenState extends State<DraftingStudioScreen> {
  GridStyle _gridStyle = GridStyle.solid;
  GridType _gridType = GridType.squareMetric;
  AppDrillMode _currentDrill = AppDrillMode.ghosting;

  final SkillProfile _skillProfile = SkillProfile();
  bool _hasSeenOnboarding = false;
  final GlobalKey _canvasCaptureKey = GlobalKey();
  bool _isCapturing = false;
  double _flashOpacity = 0.0;

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

  void _openGallery() {
    final theme = AppThemeTokens.of(widget.themeMode);
    GalleryScreen.open(
      context: context,
      theme: theme,
    );
  }

  Future<void> _captureCanvasSnapshot() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _flashOpacity = 0.7;
    });

    try {
      await HapticFeedback.mediumImpact();
      final boundary = _canvasCaptureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(
        format: ImageByteFormat.png,
      );
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final now = DateTime.now();
      final capture = DraftCapture(
        id: now.millisecondsSinceEpoch.toString(),
        title: '${_currentDrill.shortLabel} Draft',
        drillMode: _currentDrill,
        themeMode: widget.themeMode,
        gridStyle: _gridStyle,
        gridType: _gridType,
        timestamp: now,
        pngBytes: pngBytes,
        width: image.width,
        height: image.height,
      );

      await GalleryService.instance.saveCapture(capture);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Snapshot saved to Gallery (${capture.resolutionLabel})',
                ),
              ),
            ],
          ),
          backgroundColor: widget.themeMode == AppThemeMode.light
              ? const Color(0xFF0284C7)
              : const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: _openGallery,
          ),
        ),
      );
    } catch (e, stack) {
      AppLogService.instance.error(
        'GALLERY',
        'Failed to take canvas capture: $e',
        stackTrace: stack,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _flashOpacity = 0.0;
        });
      }
    }
  }

  void _openDiagnostics() {
    final theme = AppThemeTokens.of(widget.themeMode);
    CrashReportScreen.open(
      context: context,
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
              child: Stack(
                children: [
                  RepaintBoundary(
                    key: _canvasCaptureKey,
                    child: _buildActiveDrill(theme),
                  ),
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _flashOpacity,
                      duration: const Duration(milliseconds: 150),
                      child: const ColoredBox(
                        color: Colors.white,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppThemeTokens theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        border: Border(
          bottom: BorderSide(color: theme.borderSubtle, width: 1.2),
        ),
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
                  child: Icon(
                    Icons.architecture_rounded,
                    color: theme.accentCyan,
                    size: 20,
                  ),
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

            const SizedBox(width: 12),

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.borderHighlight.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.borderHighlight
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                drill.icon,
                                size: 14,
                                color: isSelected
                                    ? theme.borderHighlight
                                    : theme.secondaryInk,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                drill.shortLabel,
                                style: theme.headingStyle.copyWith(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? theme.borderHighlight
                                      : theme.secondaryInk,
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

            const SizedBox(width: 8),

            // Right-hand tools & action icons
            IconButtonTheme(
              data: const IconButtonThemeData(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStatePropertyAll(EdgeInsets.all(4)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

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
                    Expanded(child: Text('Light Studio')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_outlined, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Dark Obsidian')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppThemeMode.blueprint,
                child: Row(
                  children: [
                    Icon(Icons.brush_outlined, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Drafting Blueprint')),
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

          // Draft Gallery [🖼️]
          IconButton(
            tooltip: 'Draft Gallery',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.collections_rounded,
                  color: theme.defaultInk,
                  size: 20,
                ),
                ValueListenableBuilder<List<DraftCapture>>(
                  valueListenable: GalleryService.instance.capturesNotifier,
                  builder: (ctx, captures, _) {
                    if (captures.isEmpty) return const SizedBox.shrink();
                    return Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.accentCyan,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${captures.length}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: _openGallery,
          ),

          // Canvas Snapshot [📸]
          IconButton(
            tooltip: 'Capture Canvas Snapshot',
            icon: Icon(
              Icons.camera_alt_outlined,
              color: theme.accentCyan,
              size: 20,
            ),
            onPressed: _captureCanvasSnapshot,
          ),

          // Diagnostics & Crash Logs [🐛]
          IconButton(
            tooltip: 'Diagnostics & Crash Logs',
            icon: Icon(
              Icons.bug_report_outlined,
              color: theme.warning,
              size: 20,
            ),
            onPressed: _openDiagnostics,
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

          // Splash Screen [🎬]
            if (widget.onReplaySplash != null)
              IconButton(
                tooltip: 'Preview Animated Splash',
                icon: Icon(
                  Icons.movie_filter_outlined,
                  color: theme.secondaryInk,
                  size: 20,
                ),
                onPressed: widget.onReplaySplash,
              ),
                ],
              ),
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
