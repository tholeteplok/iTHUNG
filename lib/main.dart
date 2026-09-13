import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'domain/models/session_result.dart';
import 'presentation/challenges/screens/challenge_screen.dart';
import 'presentation/daily_challenge/widgets/daily_challenge_screen.dart';
import 'presentation/game/widgets/game_screen.dart';
import 'presentation/home/widgets/home_screen.dart';
import 'presentation/leaderboard/widgets/leaderboard_screen.dart';
import 'presentation/profile/widgets/profile_screen.dart';
import 'presentation/profile/widgets/public_profile_screen.dart';
import 'presentation/results/widgets/results_screen.dart';
import 'presentation/settings/widgets/settings_screen.dart';
import 'presentation/shared/widgets/app_shell.dart';
import 'presentation/splash/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter uncaught error: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform uncaught error: $error\n$stack');
    return true;
  };

  // Inisialisasi Hive CE storage
  await Hive.initFlutter();

  // Inisialisasi Firebase (aman / fail-open jika offline atau di test environment)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }

  runApp(const ProviderScope(child: IthungApp()));
}

/// Konfigurasi rute navigasi terpusat aplikasi iTHUNG.
///
/// Mengacu pada `math-speed-game-navigation-spec.md` §1 - §5:
/// - ShellRoute membungkus transisi antar layar agar kanvas warna tetap persisten
/// - Guard redirect pada `/results` mencegah akses langsung tanpa hasil sesi
/// - Mendukung deep link `/daily`
/// - SplashScreen sebagai rute awal sebelum memasuki ShellRoute
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(
        state: state,
        child: child,
      ),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/game/:level',
          builder: (context, state) {
            final level =
                int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
            return GameScreen(level: level);
          },
        ),
        GoRoute(
          path: '/challenges',
          builder: (context, state) => const ChallengeScreen(),
        ),
        GoRoute(
          path: '/daily',
          builder: (context, state) => const DailyChallengeGate(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/daily/play',
      builder: (context, state) => const DailyChallengeScreen(),
    ),
    GoRoute(
      path: '/results',
      redirect: (context, state) {
        if (state.extra is! SessionResult) return '/';
        return null;
      },
      builder: (context, state) =>
          ResultsScreen(result: state.extra as SessionResult),
    ),
    GoRoute(
      path: '/profile/:username',
      builder: (context, state) => PublicProfileScreen(
        username: state.pathParameters['username'] ?? '',
      ),
    ),
  ],
);

class IthungApp extends StatelessWidget {
  const IthungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iTHUNG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
