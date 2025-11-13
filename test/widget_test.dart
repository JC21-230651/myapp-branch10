
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myapp/character_state.dart';
import 'package:myapp/chat_state.dart';
import 'package:myapp/health_state.dart';
import 'package:myapp/main.dart';
import 'package:myapp/medication_state.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/task_state.dart';

// Mock implementation of INotificationService for testing.
class MockNotificationService implements INotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleDailyNotification(
      {required int id, required String title, required String body, required TimeOfDay time}) async {}

  @override
  Future<void> cancelNotification(int id) async {}
}

// CRITICAL FIX 2: Mock HealthState to use the app's internal HealthData model.
class MockHealthState extends HealthState {
  // Override getters to provide dummy data of the correct type (HealthData, not HealthDataPoint).
  @override
  List<HealthData> get sleepData => [
        HealthData(date: DateTime.now(), value: 8, unit: '時間')
      ];

  @override
  List<HealthData> get stepsData => [
        HealthData(date: DateTime.now(), value: 5000, unit: '歩')
      ];

  // Override the method that causes issues in a test environment.
  @override
  Future<void> checkPermissionsAndFetchData() async {
    // Do nothing in the mock to avoid async operations and permission requests.
  }
}

class MockTaskState extends TaskState {}

void main() {
  // Required for all widget tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up common initializations for all tests in this file.
  setUpAll(() async {
    await initializeDateFormatting('ja_JP');
    SharedPreferences.setMockInitialValues({}); // Mock SharedPreferences.
  });

  testWidgets('App starts at Calendar screen and can navigate to Health screen', (WidgetTester tester) async {
    // Arrange: Set up mock providers.
    final prefs = await SharedPreferences.getInstance();
    final themeState = ThemeState(prefs);
    final medicationState = MedicationState(notificationService: MockNotificationService());
    await medicationState.init(); // Await async initialization.

    final characterState = CharacterState();
    final healthState = MockHealthState(); // Use the correct mock.
    final chatState = ChatState(healthState);
    final taskState = MockTaskState();

    // Act: Build the main application widget.
    await tester.pumpWidget(MyApp(
      themeState: themeState,
      healthState: healthState,
      chatState: chatState,
      medicationState: medicationState,
      characterState: characterState,
      taskState: taskState,
    ));

    // Wait for all animations and async operations to complete.
    await tester.pumpAndSettle();

    // Assert 1: The app starts on the Calendar screen.
    expect(find.byWidgetPredicate((widget) => widget is TableCalendar), findsOneWidget,
        reason: 'The Calendar screen with the TableCalendar should be the initial screen.');

    // Act 2: Tap the 'ヘルスケア' navigation button.
    final healthCareNavigationButton = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('ヘルスケア'),
    );
    await tester.tap(healthCareNavigationButton);
    await tester.pumpAndSettle();

    // Assert 2: The Health screen is displayed.
    // Check for a widget unique to the HealthScreen, like the title of a card.
    expect(find.text('睡眠'), findsOneWidget, reason: 'The Health screen with the Sleep card should be displayed after navigation.');
    expect(find.text('歩数'), findsOneWidget, reason: 'The Health screen with the Steps card should be displayed after navigation.');
  });
}
