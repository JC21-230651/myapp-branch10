
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/routes/app_router.dart';
import 'package:myapp/health_state.dart';
import 'package:myapp/chat_state.dart';
import 'package:myapp/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myapp/medication_state.dart';
import 'package:myapp/character_state.dart';
import 'package:myapp/services/notification_service.dart'; // Import the service

// Top-level function for background tasks - NOT for web
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'weeklyReport') {
      developer.log('Executing weekly report task', name: 'my_app.background');

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      try {
        // Initialize dependencies for background task
        await dotenv.load(fileName: ".env");
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        final healthData = await _getWeeklyHealthData();
        if (healthData.isNotEmpty) {
          final summary = await _generateWeeklySummaryWithChatGPT(healthData);
          await _showNotification(flutterLocalNotificationsPlugin, summary);
          developer.log('Weekly report generated and notification shown.', name: 'my_app.background');
        } else {
          developer.log('Not enough health data to generate a report.', name: 'my_app.background');
        }
      } catch (e, s) {
        developer.log('Error executing background task', name: 'my_app.background', error: e, stackTrace: s);
      }
    }
    return Future.value(true);
  });
}

Future<List<HealthDataPoint>> _getWeeklyHealthData() async {
  final health = Health();
  final now = DateTime.now();
  // Find the last Monday.
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startTime = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  final types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WEIGHT,
  ];

  List<HealthDataPoint> healthData = [];
  bool granted = await health.requestAuthorization(types);
  if (granted) {
    try {
      healthData = await health.getHealthDataFromTypes(startTime: startTime, endTime: now, types: types);
    } catch (e) {
      developer.log("Error fetching health data: $e", name: 'my_app.background');
    }
  }
  // Filter out duplicates. Health package sometimes returns duplicates.
  final uniqueData = <String, HealthDataPoint>{};
  for (final dataPoint in healthData) {
    final key = '${dataPoint.typeString}-${dataPoint.dateFrom.toIso8601String()}';
    uniqueData[key] = dataPoint;
  }
  return uniqueData.values.toList();
}

Future<String> _generateWeeklySummaryWithChatGPT(List<HealthDataPoint> data) async {
  final openAI = OpenAI.instance.build(token: dotenv.env['CHATGPT_API_KEY']);

  final prompt = '''
以下の直近1週間の健康データ（歩数、消費カロリー、睡眠時間、体重）を分析し、ユーザー向けの簡潔な要約と具体的なアドバイスを生成してください。
フレンドリーな口調で、健康習慣の改善につながるような、ポジティブなフィードバックを心がけてください。

データ:
${data.map((d) => '${d.typeString}: ${d.value} at ${DateFormat('MM/dd HH:mm').format(d.dateFrom)}').join('\n')}

生成例:
「今週もお疲れ様！あなたの頑張り、ちゃんとデータに表れているよ。特に睡眠時間が安定していて素晴らしいね！来週は、もう少しだけ歩数を増やしてみると、さらに体が軽くなるかも。週末に近所を散歩してみるのはどうかな？無理せず、自分のペースでいこうね！」
''';

  final request = ChatCompleteText(
    messages: [
      {"role": "user", "content": prompt}
    ],
    maxToken: 500,
    model: GptTurboChatModel(),
  );

  try {
    final response = await openAI.onChatCompletion(request: request);
    return response?.choices.first.message?.content.trim() ?? '週次レポートの生成に失敗しました。';
  } catch (e) {
    developer.log('Error generating summary with ChatGPT', name: 'my_app.background', error: e);
    return 'AIによる分析中にエラーが発生しました。';
  }
}

Future<void> _showNotification(FlutterLocalNotificationsPlugin plugin, String message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('weekly_report_channel', 'Weekly Reports',
          channelDescription: 'Channel for weekly health summary notifications',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''));
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await plugin.show(
    0,
    'あなたの週次ヘルスレポート✨',
    message,
    platformChannelSpecifics,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    // Initialize Workmanager & Notifications for mobile only
    await Workmanager().initialize(
      callbackDispatcher,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  final prefs = await SharedPreferences.getInstance();
  final themeState = ThemeState(prefs);
  // Pass the real NotificationService to MedicationState
  final medicationState = MedicationState(notificationService: NotificationService()); 
  await medicationState.init(); // Explicitly initialize MedicationState
  final characterState = CharacterState();

  final healthState = HealthState();
  await healthState.checkPermissionsAndFetchData();

  final chatState = ChatState(healthState);

  runApp(MyApp(
    themeState: themeState,
    healthState: healthState,
    chatState: chatState,
    medicationState: medicationState,
    characterState: characterState,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeState themeState;
  final HealthState healthState;
  final ChatState chatState;
  final MedicationState medicationState;
  final CharacterState characterState;

  const MyApp({
    super.key,
    required this.themeState,
    required this.healthState,
    required this.chatState,
    required this.medicationState,
    required this.characterState,
  });

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeState),
        ChangeNotifierProvider.value(value: healthState),
        ChangeNotifierProvider.value(value: chatState),
        ChangeNotifierProvider.value(value: medicationState),
        ChangeNotifierProvider.value(value: characterState),
      ],
      child: Consumer<ThemeState>(
        builder: (context, theme, child) {
          return MaterialApp.router(
            title: '健康管理アプリ',
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: theme.themeMode,
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
