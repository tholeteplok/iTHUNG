import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mathmo_app/presentation/home/widgets/floating_bottom_dock.dart';

void main() {
  testWidgets('FloatingBottomDock renders all 4 navigation items', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: FloatingBottomDock()),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile Screen')),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const Scaffold(body: Text('Leaderboard Screen')),
        ),
        GoRoute(
          path: '/challenges',
          builder: (context, state) => const Scaffold(body: Text('Challenges Screen')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    expect(find.byTooltip('Profil'), findsOneWidget);
    expect(find.byTooltip('Peringkat'), findsOneWidget);
    expect(find.byTooltip('Tantangan'), findsOneWidget);
    expect(find.byTooltip('Pengaturan'), findsOneWidget);

    // Tap Profile
    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profile Screen'), findsOneWidget);
  });
}
