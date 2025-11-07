import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/calendar_screen.dart';
import 'package:myapp/character_setting_screen.dart';
import 'package:myapp/chat_screen.dart';
import 'package:myapp/event_edit_screen.dart';
import 'package:myapp/game_screen.dart';
import 'package:myapp/health_screen.dart';
import 'package:myapp/medication_screen.dart';
import 'package:myapp/other_screen.dart';
import 'package:myapp/route_generation_screen.dart';
import 'package:myapp/scaffold_with_nav_bar.dart';
import 'package:myapp/weekly_report_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/calendar',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          branches: [
            // Calendar Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/calendar',
                  pageBuilder: (context, state) => const NoTransitionPage(child: CalendarScreen()),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final args = state.extra as Map<String, dynamic>?;
                        return EventEditScreen(
                          event: args?['event'] as dynamic,
                          calendar: args?['calendar'] as dynamic,
                          selectedDate: args?['selectedDate'] as DateTime?,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            // Route Generation Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/route',
                  pageBuilder: (context, state) => const NoTransitionPage(child: RouteGenerationScreen()),
                ),
              ],
            ),
             // Game Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/game',
                  pageBuilder: (context, state) => const NoTransitionPage(child: GameScreen()),
                ),
              ],
            ),
            // Health Care Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/health',
                  pageBuilder: (context, state) => const NoTransitionPage(child: HealthScreen()),
                  routes: [
                    GoRoute(
                      path: 'chat',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const ChatScreen(),
                    ),
                    GoRoute(
                      path: 'weekly_report',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const WeeklyReportScreen(),
                    ),
                  ],
                ),
              ],
            ),
            // Other Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/other',
                  pageBuilder: (context, state) => const NoTransitionPage(child: OtherScreen()),
                   routes: [
                    GoRoute(
                      path: 'medication',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const MedicationScreen(),
                    ),
                    GoRoute(
                      path: 'character_setting',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const CharacterSettingScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
