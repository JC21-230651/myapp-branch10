import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _weeklyReportEnabled = false;
  int _selectedDay = DateTime.monday;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weeklyReportEnabled =
          prefs.getBool('weeklyReportEnabled') ?? false;
      _selectedDay = prefs.getInt('weeklyReportDay') ?? DateTime.monday;
      final timeString = prefs.getString('weeklyReportTime') ?? '20:00';
      final parts = timeString.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weeklyReportEnabled', _weeklyReportEnabled);
    await prefs.setInt('weeklyReportDay', _selectedDay);
    await prefs.setString('weeklyReportTime', '${_selectedTime.hour}:${_selectedTime.minute}');
  }

  void _scheduleWeeklyReport() {
    if (kIsWeb) return; // Don't run on web

    if (_weeklyReportEnabled) {
      // Calculate the next run time
      final now = DateTime.now();
      DateTime nextRun = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      // If the scheduled time is in the past for today, move to the next scheduled day
      while (nextRun.isBefore(now) || nextRun.weekday != _selectedDay) {
        nextRun = nextRun.add(const Duration(days: 1));
        if (nextRun.weekday == _selectedDay && nextRun.isBefore(now)) {
          nextRun = nextRun.add(const Duration(days: 7));
          break;
        }
         while (nextRun.weekday != _selectedDay) {
            nextRun = nextRun.add(const Duration(days: 1));
        }
      }

      final initialDelay = nextRun.difference(now);

      Workmanager().cancelByUniqueName("weeklyReport");
      Workmanager().registerPeriodicTask(
        "weeklyReport",
        "weeklyReport",
        frequency: const Duration(days: 7),
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } else {
      Workmanager().cancelByUniqueName("weeklyReport");
    }
  }


  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _saveSettings();
      _scheduleWeeklyReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('服薬管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/medication');
            },
          ),
          const Divider(),
          if (!kIsWeb) ...[
            SwitchListTile(
              title: const Text('週次レポート通知'),
              value: _weeklyReportEnabled,
              onChanged: (bool value) {
                setState(() {
                  _weeklyReportEnabled = value;
                });
                _saveSettings();
                _scheduleWeeklyReport();
              },
            ),
            ListTile(
              title: const Text('曜日'),
              trailing: DropdownButton<int>(
                value: _selectedDay,
                items: const [
                  DropdownMenuItem(value: DateTime.monday, child: Text('月曜日')),
                  DropdownMenuItem(value: DateTime.tuesday, child: Text('火曜日')),
                  DropdownMenuItem(value: DateTime.wednesday, child: Text('水曜日')),
                  DropdownMenuItem(value: DateTime.thursday, child: Text('木曜日')),
                  DropdownMenuItem(value: DateTime.friday, child: Text('金曜日')),
                  DropdownMenuItem(value: DateTime.saturday, child: Text('土曜日')),
                  DropdownMenuItem(value: DateTime.sunday, child: Text('日曜日')),
                ],
                onChanged: _weeklyReportEnabled
                    ? (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDay = newValue;
                          });
                          _saveSettings();
                          _scheduleWeeklyReport();
                        }
                      }
                    : null,
              ),
              enabled: _weeklyReportEnabled,
            ),
            ListTile(
              title: const Text('時間'),
              trailing: InkWell(
                onTap: _weeklyReportEnabled ? () => _selectTime(context) : null,
                child: Text(
                  _selectedTime.format(context),
                  style: TextStyle(
                    color: _weeklyReportEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                  ),
                ),
              ),
              enabled: _weeklyReportEnabled,
            ),
          ],
        ],
      ),
    );
  }
}
