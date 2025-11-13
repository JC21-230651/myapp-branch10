import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:myapp/models/task.dart';

class TaskState with ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  List<Task> getEventsForDay(DateTime day) {
    return _tasks
        .where((task) =>
            task.dueDate.year == day.year &&
            task.dueDate.month == day.month &&
            task.dueDate.day == day.day)
        .toList();
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final task = _tasks.firstWhereOrNull((t) => t.id == taskId);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      notifyListeners();
    }
  }
}
