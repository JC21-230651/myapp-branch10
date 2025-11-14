class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;
  final int priority;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 1,
  });
}