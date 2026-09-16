import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/bgm_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../game/providers/level_band_theme_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../data/services/update_service.dart';
import '../../shared/widgets/adventure_ribbon_banner.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/update_dialog.dart';
import '../providers/level_stars_provider.dart';
import '../providers/level_transition_provider.dart';
import '../providers/player_profile_provider.dart';
import 'mascot_node_character.dart';
import 'floating_bottom_dock.dart';
import 'level_node.dart';
import 'milestone_chest_node.dart';

/// Koordinat piksel tetap terkalibrasi pada kanvas 768 x 1376 px.
/// Menjamin node level duduk 100% tepat di tengah lekukan jalan setapak berbatu (cobblestone S-curve).
const List<Offset> kDefaultNodeAnchors = [
  Offset(265, 1020), // Level 1 (lekukan bawah)
  Offset(510, 848), // Level 2 (belokan kanan)
  Offset(270, 724), // Level 3 (belokan kiri tengah)
  Offset(475, 556), // Level 4 (belokan kanan atas)
  Offset(265, 450), // Level 5 (belokan kiri atas)
];

/// Koordinat piksel tetap terkalibrasi untuk Peti Harta Milestone di gerbang puncak stage.
const Offset kDefaultChestAnchor = Offset(380, 360);

/// Faktor skala kedalaman perspektif 3D dari depan (bawah) ke belakang (puncak).
/// Index 0 = Level 1 (foreground paling besar 1.25x), Index 4 = Level 5 (paling jauh 0.78x).
const List<double> kStagePerspectiveScales = [1.25, 1.12, 1.00, 0.88, 0.78];

/// Skala kedalaman untuk Peti Harta Milestone di puncak gerbang stage.
const double kMilestoneChestPerspectiveScale = 0.80;

/// Data konfigurasi satu stage zona (berisi 5 level per gambar kanvas).
class StageData {
  const StageData({
    required this.stageIndex,
    required this.startLevel,
    required this.endLevel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.assetPath,
    required this.accentColor,
    required this.bgmAssetPath,
    this.nodeAnchors = kDefaultNodeAnchors,
    this.chestAnchor = kDefaultChestAnchor,
  });

  final int stageIndex;
  final int startLevel;
  final int endLevel;
  final String title;
  final String subtitle;
  final String icon;
  final String assetPath;
  final Color accentColor;
  final String bgmAssetPath;
  final List<Offset> nodeAnchors;
  final Offset chestAnchor;
}

/// Daftar definisi stage petualangan mencakup seluruh 5 Level Band (Level 1 hingga 60+).
final List<StageData> kIthungStages = [
  // Band 1: Onboarding (Level 1–5)
  const StageData(
    stageIndex: 0,
    startLevel: 1,
    endLevel: 5,
    title: 'Fresh Sprout Meadow',
    subtitle: 'Zona 1 • Level 1–5',
    icon: '🌱',
    assetPath: 'assets/images/meadow_canvas.jpg',
    accentColor: Color(0xFF639922),
    bgmAssetPath: 'assets/sounds/musics/meadow_tone.mp3',
  ),

  // Band 2: Basic (Level 6–15)
  const StageData(
    stageIndex: 1,
    startLevel: 6,
    endLevel: 10,
    title: 'Golden Sun Canyon',
    subtitle: 'Zona 2 • Level 6–10',
    icon: '🏜️',
    assetPath: 'assets/images/canyon_canvas.jpg',
    accentColor: Color(0xFFBA7517),
    bgmAssetPath: 'assets/sounds/musics/canyon_tone.mp3',
  ),
  const StageData(
    stageIndex: 2,
    startLevel: 11,
    endLevel: 15,
    title: 'Golden Sun Canyon',
    subtitle: 'Zona 2 • Level 11–15',
    icon: '🏜️',
    assetPath: 'assets/images/canyon_canvas.jpg',
    accentColor: Color(0xFFBA7517),
    bgmAssetPath: 'assets/sounds/musics/canyon_tone.mp3',
  ),

  // Band 3: Intermediate (Level 16–30)
  const StageData(
    stageIndex: 3,
    startLevel: 16,
    endLevel: 20,
    title: 'Coral Sunset Ridge',
    subtitle: 'Zona 3 • Level 16–20',
    icon: '🍂',
    assetPath: 'assets/images/ridge_canvas.jpg',
    accentColor: Color(0xFFD85A30),
    bgmAssetPath: 'assets/sounds/musics/ridge_tone.mp3',
  ),
  const StageData(
    stageIndex: 4,
    startLevel: 21,
    endLevel: 25,
    title: 'Coral Sunset Ridge',
    subtitle: 'Zona 3 • Level 21–25',
    icon: '🍂',
    assetPath: 'assets/images/ridge_canvas.jpg',
    accentColor: Color(0xFFD85A30),
    bgmAssetPath: 'assets/sounds/musics/ridge_tone.mp3',
  ),
  const StageData(
    stageIndex: 5,
    startLevel: 26,
    endLevel: 30,
    title: 'Coral Sunset Ridge',
    subtitle: 'Zona 3 • Level 26–30',
    icon: '🍂',
    assetPath: 'assets/images/ridge_canvas.jpg',
    accentColor: Color(0xFFD85A30),
    bgmAssetPath: 'assets/sounds/musics/ridge_tone.mp3',
  ),

  // Band 4: Advanced (Level 31–50)
  const StageData(
    stageIndex: 6,
    startLevel: 31,
    endLevel: 35,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 31–35',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
    bgmAssetPath: 'assets/sounds/musics/twilight_tone.mp3',
  ),
  const StageData(
    stageIndex: 7,
    startLevel: 36,
    endLevel: 40,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 36–40',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
    bgmAssetPath: 'assets/sounds/musics/twilight_tone.mp3',
  ),
  const StageData(
    stageIndex: 8,
    startLevel: 41,
    endLevel: 45,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 41–45',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
    bgmAssetPath: 'assets/sounds/musics/twilight_tone.mp3',
  ),
  const StageData(
    stageIndex: 9,
    startLevel: 46,
    endLevel: 50,
    title: 'Twilight Forest',
    subtitle: 'Zona 4 • Level 46–50',
    icon: '✨',
    assetPath: 'assets/images/twilight_canvas.jpg',
    accentColor: Color(0xFFD4537E),
    bgmAssetPath: 'assets/sounds/musics/twilight_tone.mp3',
  ),

  // Band 5: Expert (Highland Wind, Level 51–75)
  const StageData(
    stageIndex: 10,
    startLevel: 51,
    endLevel: 55,
    title: 'Highland Wind',
    subtitle: 'Zona 5 • Level 51–55',
    icon: '🌄',
    assetPath: 'assets/images/Highland_canvas.jpg',
    accentColor: Color(0xFF4A7C36),
    bgmAssetPath: 'assets/sounds/musics/Highland_tone.mp3',
  ),
  const StageData(
    stageIndex: 11,
    startLevel: 56,
    endLevel: 60,
    title: 'Highland Wind',
    subtitle: 'Zona 5 • Level 56–60',
    icon: '🌄',
    assetPath: 'assets/images/Highland_canvas.jpg',
    accentColor: Color(0xFF4A7C36),
    bgmAssetPath: 'assets/sounds/musics/Highland_tone.mp3',
  ),
  const StageData(
    stageIndex: 12,
    startLevel: 61,
    endLevel: 65,
    title: 'Highland Wind',
    subtitle: 'Zona 5 • Level 61–65',
    icon: '🌄',
    assetPath: 'assets/images/Highland_canvas.jpg',
    accentColor: Color(0xFF4A7C36),
    bgmAssetPath: 'assets/sounds/musics/Highland_tone.mp3',
  ),
  const StageData(
    stageIndex: 13,
    startLevel: 66,
    endLevel: 70,
    title: 'Highland Wind',
    subtitle: 'Zona 5 • Level 66–70',
    icon: '🌄',
    assetPath: 'assets/images/Highland_canvas.jpg',
    accentColor: Color(0xFF4A7C36),
    bgmAssetPath: 'assets/sounds/musics/Highland_tone.mp3',
  ),
  const StageData(
    stageIndex: 14,
    startLevel: 71,
    endLevel: 75,
    title: 'Highland Wind',
    subtitle: 'Zona 5 • Level 71–75',
    icon: '🌄',
    assetPath: 'assets/images/Highland_canvas.jpg',
    accentColor: Color(0xFF4A7C36),
    bgmAssetPath: 'assets/sounds/musics/Highland_tone.mp3',
  ),

  // Band 6: Master (Frost Wind, Level 76–100)
  const StageData(
    stageIndex: 15,
    startLevel: 76,
    endLevel: 80,
    title: 'Frost Wind',
    subtitle: 'Zona 6 • Level 76–80',
    icon: '🏔️',
    assetPath: 'assets/images/frost_canvas.jpg',
    accentColor: Color(0xFF2B829E),
    bgmAssetPath: 'assets/sounds/musics/Frost_tone.mp3',
  ),
  const StageData(
    stageIndex: 16,
    startLevel: 81,
    endLevel: 85,
    title: 'Frost Wind',
    subtitle: 'Zona 6 • Level 81–85',
    icon: '🏔️',
    assetPath: 'assets/images/frost_canvas.jpg',
    accentColor: Color(0xFF2B829E),
    bgmAssetPath: 'assets/sounds/musics/Frost_tone.mp3',
  ),
  const StageData(
    stageIndex: 17,
    startLevel: 86,
    endLevel: 90,
    title: 'Frost Wind',
    subtitle: 'Zona 6 • Level 86–90',
    icon: '🏔️',
    assetPath: 'assets/images/frost_canvas.jpg',
    accentColor: Color(0xFF2B829E),
    bgmAssetPath: 'assets/sounds/musics/Frost_tone.mp3',
  ),
  const StageData(
    stageIndex: 18,
    startLevel: 91,
    endLevel: 95,
    title: 'Frost Wind',
    subtitle: 'Zona 6 • Level 91–95',
    icon: '🏔️',
    assetPath: 'assets/images/frost_canvas.jpg',
    accentColor: Color(0xFF2B829E),
    bgmAssetPath: 'assets/sounds/musics/Frost_tone.mp3',
  ),
  const StageData(
    stageIndex: 19,
    startLevel: 96,
    endLevel: 100,
    title: 'Frost Wind',
    subtitle: 'Zona 6 • Level 96–100',
    icon: '🏔️',
    assetPath: 'assets/images/frost_canvas.jpg',
    accentColor: Color(0xFF2B829E),
    bgmAssetPath: 'assets/sounds/musics/Frost_tone.mp3',
  ),
];

/// Layar beranda (HomeScreen) berbasis Immersive Fullscreen Scenic Canvas Map.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  late BgmService _bgmService;
  int _currentStageIndex = 0;
  bool _initializedPage = false;

  static bool _hasCheckedUpdateThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _bgmService = ref.read(bgmServiceProvider);
    _checkPassiveUpdate();
  }

  void _checkPassiveUpdate() {
    if (_hasCheckedUpdateThisSession) return;
    _hasCheckedUpdateThisSession = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final updateService = ref.read(updateServiceProvider);
        final info = await updateService.checkForUpdate();
        if (info.hasUpdate && mounted) {
          await showUpdateNotificationDialog(
            context: context,
            info: info,
            onUpdate: () {
              showUpdateProgressDialog(context: context, info: info);
            },
          );
        }
      } catch (_) {
        // Silently ignore passive check errors
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache seluruh gambar kanvas biome agar swipe antar stage instan dan bebas jank
    for (final stage in kIthungStages) {
      precacheImage(AssetImage(stage.assetPath), context);
    }
    // Precache aset taktil
    precacheImage(const AssetImage(AppAssets.woodTokenPlay), context);
    precacheImage(const AssetImage(AppAssets.woodTokenChecked), context);
    precacheImage(const AssetImage(AppAssets.woodTokenLocked), context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _bgmService.pause();
    } else if (state == AppLifecycleState.resumed) {
      _bgmService.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _bgmService.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(playerProfileProvider);
    final themeAsync = ref.watch(levelBandThemeProvider);
    final starsAsync = ref.watch(levelStarsProvider);

    final profile = profileAsync.valueOrNull;
    final currentLevel = profile?.currentLevel ?? 1;
    final currentStreak = profile?.streak.currentStreak ?? 0;
    final totalXp = profile?.totalXp ?? 0;
    final avatarId = profile?.avatarId;
    final username = profile?.username;
    final avatarLetter = (username != null && username.isNotEmpty)
        ? username[0].toUpperCase()
        : 'P';
    final accentColor =
        themeAsync.valueOrNull?.accentColor ?? const Color(0xFF639922);
    final canvasColor =
        themeAsync.valueOrNull?.canvasColor ?? const Color(0xFFEAF3DE);
    final starsMap = starsAsync.valueOrNull ?? const {};

    // Fokus otomatis ke stage tempat level aktif pemain berada saat pertama kali load
    if (!_initializedPage && (profileAsync.hasValue || profileAsync.hasError)) {
      _initializedPage = true;
      final targetStage =
          ((currentLevel - 1) ~/ 5).clamp(0, kIthungStages.length - 1);
      _currentStageIndex = targetStage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetStage);
          }
          ref
              .read(bgmServiceProvider)
              .playTrack(kIthungStages[targetStage].bgmAssetPath);
        }
      });
    }

    // Dengarkan transisi zona (Fase 5 - PageView auto-slide ke zona baru)
    ref.listen<LevelTransitionState?>(levelTransitionProvider, (prev, next) {
      if (next != null && next.isZoneTransition && mounted) {
        final targetStage =
            ((next.toLevel - 1) ~/ 5).clamp(0, kIthungStages.length - 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.animateToPage(
              targetStage,
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeInOutCubic,
            );
            ref.read(hapticServiceProvider).mediumImpact();
            ref.read(levelTransitionProvider.notifier).clearTransition();
          }
        });
      }
    });

    final activeStage = kIthungStages[_currentStageIndex];

    return AnimatedContainer(
      duration: AppTokens.canvasColorTransition,
      color: canvasColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Scenic Canvas Background (Fullscreen 100% Edge-to-Edge)
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: kIthungStages.length,
                onPageChanged: (page) {
                  setState(() => _currentStageIndex = page);
                  ref
                      .read(bgmServiceProvider)
                      .playTrack(kIthungStages[page].bgmAssetPath);
                },
                itemBuilder: (context, index) {
                  final stage = kIthungStages[index];
                  return _StageCanvasView(
                    stage: stage,
                    currentLevel: currentLevel,
                    accentColor: accentColor,
                    starsMap: starsMap,
                    avatarId: avatarId,
                    avatarLetter: avatarLetter,
                  );
                },
              ),
            ),

            // 2. Floating Top Bar Overlay (Header + Stage Navigator Bar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: Avatar, Streak, XP, Mute Button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: AppHeader(
                        streak: currentStreak,
                        xp: totalXp,
                        actions: const [
                          _MuteToggleButton(),
                        ],
                      ),
                    ),

                    // Stage Navigator Bar (Pita Spanduk Petualang - Adventure Ribbon)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: AdventureRibbonBanner(
                        title: activeStage.title,
                        subtitle: activeStage.subtitle,
                        icon: activeStage.icon,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Bottom Navigation Dock (Profile, Leaderboard, Daily, Settings)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: FloatingBottomDock(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget yang merender 1 lembar kanvas pemandangan dengan koordinat piksel terpadu 768 x 1376 px,
/// mendukung pergerakan lompatan parabolik maskot (Parabolic Hop) antar node level.
class _StageCanvasView extends ConsumerStatefulWidget {
  const _StageCanvasView({
    required this.stage,
    required this.currentLevel,
    required this.accentColor,
    required this.starsMap,
    this.avatarId,
    this.avatarLetter = 'P',
  });

  final StageData stage;
  final int currentLevel;
  final Color accentColor;
  final Map<int, int> starsMap;
  final String? avatarId;
  final String avatarLetter;

  static const double canvasWidth = 768.0;
  static const double canvasHeight = 1376.0;

  @override
  ConsumerState<_StageCanvasView> createState() => _StageCanvasViewState();
}

class _StageCanvasViewState extends ConsumerState<_StageCanvasView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hopController;
  late final Animation<double> _hopAnimation;

  LevelTransitionState? _activeTransition;

  @override
  void initState() {
    super.initState();
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _hopAnimation = CurvedAnimation(
      parent: _hopController,
      curve: Curves.easeInOutQuad,
    );

    _hopController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(hapticServiceProvider).lightImpact();
        ref.read(levelTransitionProvider.notifier).clearTransition();
        if (mounted) {
          setState(() {
            _activeTransition = null;
          });
        }
      }
    });

    _checkAndStartTransition();
  }

  void _checkAndStartTransition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final transition = ref.read(levelTransitionProvider);
      if (transition != null && !transition.isZoneTransition) {
        final fromIdx = transition.fromLevel - widget.stage.startLevel;
        final toIdx = transition.toLevel - widget.stage.startLevel;
        if (fromIdx >= 0 && fromIdx < 5 && toIdx >= 0 && toIdx < 5) {
          setState(() {
            _activeTransition = transition;
          });
          _hopController.forward(from: 0.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _hopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LevelTransitionState?>(levelTransitionProvider, (prev, next) {
      if (next != null && !next.isZoneTransition && mounted) {
        final fromIdx = next.fromLevel - widget.stage.startLevel;
        final toIdx = next.toLevel - widget.stage.startLevel;
        if (fromIdx >= 0 && fromIdx < 5 && toIdx >= 0 && toIdx < 5) {
          setState(() {
            _activeTransition = next;
          });
          _hopController.forward(from: 0.0);
        }
      }
    });

    return SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          child: SizedBox(
            width: _StageCanvasView.canvasWidth,
            height: _StageCanvasView.canvasHeight,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // 1. Scenic Canvas Background Image (768 x 1376 px)
                Image.asset(
                  widget.stage.assetPath,
                  width: _StageCanvasView.canvasWidth,
                  height: _StageCanvasView.canvasHeight,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: widget.stage.accentColor.withValues(alpha: 0.15),
                      child: Center(
                        child: Text(
                          widget.stage.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),

                // 2. Dynamic Interactive Level Nodes Overlay
                for (var i = 0; i < 5; i++)
                  _buildNodeItem(
                    context: context,
                    level: widget.stage.startLevel + i,
                    pos: widget.stage.nodeAnchors[i],
                    scale: kStagePerspectiveScales[i],
                  ),

                // 3. Milestone Chest Node at summit destination
                Positioned(
                  left: widget.stage.chestAnchor.dx - 26,
                  top: widget.stage.chestAnchor.dy - 26,
                  width: 52,
                  height: 52,
                  child: Transform.scale(
                    scale: kMilestoneChestPerspectiveScale,
                    alignment: Alignment.center,
                    child: MilestoneChestNode(
                      level: widget.stage.endLevel,
                      isUnlocked: widget.stage.endLevel <= widget.currentLevel,
                      accentColor: widget.stage.accentColor,
                    ),
                  ),
                ),

                // 4. Mascot Layer (Independent layer over nodes for smooth parabolic jumping)
                _buildMascotLayer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascotLayer() {
    final stage = widget.stage;
    final currentLvl = widget.currentLevel;

    // Transisi Lompatan Parabolik Aktif
    if (_activeTransition != null && _hopController.isAnimating) {
      final fromIdx = _activeTransition!.fromLevel - stage.startLevel;
      final toIdx = _activeTransition!.toLevel - stage.startLevel;

      if (fromIdx >= 0 && fromIdx < 5 && toIdx >= 0 && toIdx < 5) {
        final startPos = stage.nodeAnchors[fromIdx];
        final endPos = stage.nodeAnchors[toIdx];
        final startScale = kStagePerspectiveScales[fromIdx];
        final endScale = kStagePerspectiveScales[toIdx];

        return AnimatedBuilder(
          animation: _hopAnimation,
          builder: (context, _) {
            final t = _hopAnimation.value;
            final currentX = startPos.dx + (endPos.dx - startPos.dx) * t;

            // Parabola: Garis dasar + lengkungan busur ke atas (puncak di t = 0.5)
            final baseY = startPos.dy + (endPos.dy - startPos.dy) * t;
            final jumpArc = 120.0 * 4.0 * t * (1.0 - t);
            final currentY = baseY - jumpArc;

            // Skala perspektif kedalaman
            final currentScale = startScale + (endScale - startScale) * t;

            // Squash & Stretch dinamis saat mendarat
            double squashX = 1.0;
            double squashY = 1.0;
            if (t > 0.85) {
              final landT = (t - 0.85) / 0.15;
              squashX = 1.0 + (0.12 * math.sin(landT * math.pi));
              squashY = 1.0 - (0.10 * math.sin(landT * math.pi));
            }

            final finalTop =
                currentY - (172 * currentScale).clamp(140.0, 206.0);

            return Positioned(
              left: currentX - 140,
              top: finalTop,
              width: 280,
              child: Center(
                child: Transform.scale(
                  scaleX: squashX,
                  scaleY: squashY,
                  alignment: Alignment.bottomCenter,
                  child: MascotNodeCharacter(
                    level: _activeTransition!.toLevel,
                    scale: currentScale,
                    avatarId: widget.avatarId,
                    avatarLetter: widget.avatarLetter,
                    onTap: () =>
                        context.go('/game/${_activeTransition!.toLevel}'),
                  ),
                ),
              ),
            );
          },
        );
      }
    }

    // Posisi statis biasa pada node level aktif
    final isLevelInThisStage =
        currentLvl >= stage.startLevel && currentLvl <= stage.endLevel;
    if (!isLevelInThisStage) return const SizedBox.shrink();

    final activeIndex = (currentLvl - stage.startLevel).clamp(0, 4);
    final pos = stage.nodeAnchors[activeIndex];
    final scale = kStagePerspectiveScales[activeIndex];

    return Positioned(
      left: pos.dx - 140,
      top: pos.dy - (172 * scale).clamp(140.0, 206.0),
      width: 280,
      child: Center(
        child: MascotNodeCharacter(
          level: currentLvl,
          scale: scale,
          avatarId: widget.avatarId,
          avatarLetter: widget.avatarLetter,
          onTap: () => context.go('/game/$currentLvl'),
        ),
      ),
    );
  }

  Widget _buildNodeItem({
    required BuildContext context,
    required int level,
    required Offset pos,
    required double scale,
  }) {
    final status = level < widget.currentLevel
        ? LevelNodeStatus.completed
        : level == widget.currentLevel
        ? LevelNodeStatus.active
        : LevelNodeStatus.locked;

    final starCount = widget.starsMap[level] ?? 0;

    return Positioned(
      left: pos.dx - 75,
      top: status == LevelNodeStatus.active
          ? pos.dy - (43 * scale)
          : (status == LevelNodeStatus.completed
              ? pos.dy - (29 * scale)
              : pos.dy - (27 * scale)),
      width: 150,
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: LevelNode(
            level: level,
            status: status,
            accentColor: status == LevelNodeStatus.active
                ? AppTheme.colorSage
                : widget.stage.accentColor,
            starCount: starCount,
            onTap: () {
              if (status != LevelNodeStatus.locked) {
                context.go('/game/$level');
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Tombol Mute / Unmute BGM loop bergaya Neobrutalism di header HomeScreen.
class _MuteToggleButton extends ConsumerWidget {
  const _MuteToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(audioSettingsProvider.select((s) => s.bgmMuted));
    return Tooltip(
      message: isMuted ? 'Nyalakan Musik' : 'Matikan Musik',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(audioSettingsProvider.notifier).toggleBgm(),
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.colorTranslucentSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.colorTranslucentBorder,
                width: 1.5,
              ),
            ),
            child: Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              size: 20,
              color: isMuted
                  ? AppTheme.colorTaupe.withValues(alpha: 0.6)
                  : AppTheme.colorEspresso,
            ),
          ),
        ),
      ),
    );
  }
}

