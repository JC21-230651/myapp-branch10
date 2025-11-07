
import 'dart:convert';
import 'package:flutter/material.dart';

class Medication {
  final int id; // Unique id for the medication, used for notifications.
  final String name;
  final TimeOfDay time; // The time of day to take the medication.

  Medication({required this.id, required this.name, required this.time});

  // Convert a Medication object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // TimeOfDay is not directly serializable, so store hour and minute.
      'hour': time.hour,
      'minute': time.minute,
    };
  }

  // Create a Medication object from a Map.
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
    );
  }

  // For saving to shared_preferences, we convert to a JSON string.
  String toJson() => json.encode(toMap());

  // For loading from shared_preferences, we decode the JSON string.
  factory Medication.fromJson(String source) => Medication.fromMap(json.decode(source));
}
