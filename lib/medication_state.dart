
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/medication.dart';
import 'package:myapp/services/notification_service.dart';

DateTime normalizeDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

class MedicationState with ChangeNotifier {
  final INotificationService _notificationService;
  List<Medication> _medications = [];
  final Map<DateTime, List<Medication>> _events = {};

  MedicationState({INotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  Future<void> init() async {
    await _notificationService.init();
    await _loadMedicationsFromPrefs();
  }

  UnmodifiableListView<Medication> get medications => UnmodifiableListView(_medications);
  UnmodifiableMapView<DateTime, List<Medication>> get events => UnmodifiableMapView(_events);

  Future<void> addMedication(Medication medication) async {
    _medications.add(medication);
    await _scheduleNotificationForMedication(medication);
    await _saveMedicationsToPrefs();
    _updateEvents();
    notifyListeners();
  }

  Future<void> removeMedication(Medication medication) async {
    _medications.removeWhere((m) => m.id == medication.id);
    await _notificationService.cancelNotification(medication.id);
    await _saveMedicationsToPrefs();
    _updateEvents();
    notifyListeners();
  }

  Future<void> _scheduleNotificationForMedication(Medication medication) async {
    await _notificationService.scheduleDailyNotification(
      id: medication.id,
      title: 'お薬の時間です',
      body: '${medication.name}を服用してください。',
      time: medication.time,
    );
  }

  Future<void> _saveMedicationsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> medicationJsonList = _medications.map((m) => m.toJson()).toList();
    await prefs.setStringList('medications', medicationJsonList);
  }

  Future<void> _loadMedicationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic storedValue = prefs.get('medications');
    
    List<String> medicationJsonList = [];

    if (storedValue is List<String>) {
      medicationJsonList = storedValue;
    } else if (storedValue != null) {
      // If the data is not null but not a List<String>, it's malformed.
      // Remove it to prevent future errors.
      await prefs.remove('medications');
    }
    
    _medications = medicationJsonList.map((json) => Medication.fromJson(json)).toList();
    
    await _rescheduleAllNotifications();
    _updateEvents();
    notifyListeners();
  }

  Future<void> _rescheduleAllNotifications() async {
    for (final med in _medications) {
      await _scheduleNotificationForMedication(med);
    }
  }

  void _updateEvents() {
    _events.clear();
    final today = normalizeDate(DateTime.now());
    for (var med in _medications) {
      for (int i = 0; i < 365; i++) {
        DateTime currentDay = today.add(Duration(days: i));
        if (_events[currentDay] == null) _events[currentDay] = [];
        _events[currentDay]!.add(med);
      }
    }
  }

  List<Medication> getEventsForDay(DateTime day) {
    return _events[normalizeDate(day)] ?? [];
  }
}
