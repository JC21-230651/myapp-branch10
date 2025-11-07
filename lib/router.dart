import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/weekly_report_screen.dart'; // Add this line

import 'calendar_screen.dart';
import 'chat_screen.dart';
import 'event_edit_screen.dart';
import 'game_screen.dart';
import 'health_screen.dart';
import 'character_setting_screen.dart';
import 'medication_screen.dart';
import 'memo_screen.dart';
import 'notification_setting_screen.dart';
import 'other_screen.dart';
import 'register_screen.dart';
import 'route_generation_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/health',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/calendar',
              builder: (BuildContext context, GoRouterState state) =>
                  const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/route_generation',
              builder: (BuildContext context, GoRouterState state) =>
                  const RouteGenerationScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/game',
              builder: (BuildContext context, GoRouterState state) =>
                  const GameScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/health',
              builder: (BuildContext context, GoRouterState state) =>
                  const HealthScreen(),
              routes: [
                GoRoute(
                  path: 'weekly_report',
                  builder: (BuildContext context, GoRouterState state) =>
                      const WeeklyReportScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/other',
              builder: (BuildContext context, GoRouterState state) =>
                  const OtherScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/memo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final DateTime? selectedDate = state.extra as DateTime?;
        return MemoScreen(selectedDate: selectedDate);
      },
    ),
    GoRoute(
      path: '/notification_setting',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NotificationSettingScreen(),
    ),
    GoRoute(
      path: '/medication',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MedicationScreen(),
    ),
    GoRoute(
      path: '/event/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
        return EventEditScreen(
          event: args['event'],
          calendar: args['calendar'],
          selectedDate: args['selectedDate'],
        );
      },
    ),
    // Add new routes for chat and image generation that are not in the nav bar
    GoRoute(
      path: '/chat',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/character_setting',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CharacterSettingScreen(),
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: '経路生成',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'ゲーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite), // FIX: Changed icon to a heart shape.
            label: 'ヘルスケア',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'その他',
          ),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: (int index) => _onTap(context, index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
