import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthData {
  final DateTime date;
  final double value;
  final String unit;

  HealthData({required this.date, required this.value, required this.unit});
}

class HealthState with ChangeNotifier {
  bool _healthDataNotGranted = false;
  List<HealthData> _sleepData = [];
  List<HealthData> _stepsData = [];
  double _stepGoal = 10000;
  double _sleepGoal = 8;

  bool get healthDataNotGranted => _healthDataNotGranted;
  List<HealthData> get sleepData => _sleepData;
  List<HealthData> get stepsData => _stepsData;
  double get stepGoal => _stepGoal;
  double get sleepGoal => _sleepGoal;

  HealthData? get latestSleep {
    return _sleepData.isNotEmpty ? _sleepData.last : null;
  }

  HealthData? get latestSteps {
    return _stepsData.isNotEmpty ? _stepsData.last : null;
  }

  void updateStepGoal(double goal) {
    _stepGoal = goal;
    notifyListeners();
  }

  void updateSleepGoal(double goal) {
    _sleepGoal = goal;
    notifyListeners();
  }

  Future<void> checkPermissionsAndFetchData() async {
    if (kIsWeb) return;

    final permissionStatus = await Permission.activityRecognition.request();
    if (permissionStatus != PermissionStatus.granted) {
      _healthDataNotGranted = true;
      notifyListeners();
      return;
    }

    final types = [HealthDataType.STEPS, HealthDataType.SLEEP_ASLEEP];
    final health = Health();
    final granted = await health.requestAuthorization(types);

    if (!granted) {
      _healthDataNotGranted = true;
      notifyListeners();
      return;
    }

    _healthDataNotGranted = false;
    await _fetchHealthData(health);
    notifyListeners();
  }

  Future<void> _fetchHealthData(Health health) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    try {
      final steps = await health.getHealthDataFromTypes(
          startTime: sevenDaysAgo, endTime: now, types: [HealthDataType.STEPS]);
      final sleep = await health.getHealthDataFromTypes(
          startTime: sevenDaysAgo, endTime: now, types: [HealthDataType.SLEEP_ASLEEP]);

      _stepsData = _processData(steps, '歩');
      _sleepData = _processData(sleep, '時間', isSleep: true);
    } catch (e) {
      debugPrint("Error fetching health data: $e");
      _healthDataNotGranted = true;
    }
  }

  List<HealthData> _processData(List<HealthDataPoint> data, String unit, {bool isSleep = false}) {
    if (data.isEmpty) return [];

    final aggregatedData = <DateTime, double>{};

    for (var d in data) {
      final day = DateTime(d.dateFrom.year, d.dateFrom.month, d.dateFrom.day);
      final value = (d.value as NumericHealthValue).numericValue.toDouble();
      aggregatedData.update(day, (existing) => existing + value, ifAbsent: () => value);
    }

    return aggregatedData.entries.map((entry) {
      final value = isSleep ? entry.value / 60.0 : entry.value;
      return HealthData(date: entry.key, value: value, unit: unit);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}
