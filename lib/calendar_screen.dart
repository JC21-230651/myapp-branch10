import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/medication_state.dart';
import 'package:myapp/models/medication.dart';
import 'package:myapp/task_state.dart';
import 'package:myapp/models/task.dart';
import 'package:myapp/task_add_screen.dart'; // Import TaskAddScreen

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final medicationState = context.read<MedicationState>();
    final taskState = context.read<TaskState>();
    final medications = medicationState.getEventsForDay(day);
    final tasks = taskState.getEventsForDay(day);
    return [...medications, ...tasks];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _showMedicationDetailsDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final medicationState =
            Provider.of<MedicationState>(context, listen: false);
        return AlertDialog(
          title: Text(medication.name),
          content: Text('服用時間: ${medication.time.format(context)}'),
          actions: <Widget>[
            TextButton(
              child: const Text('閉じる'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                medicationState.removeMedication(medication);
                Navigator.of(dialogContext).pop();
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDetailsDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final taskState = Provider.of<TaskState>(context, listen: false);
        return AlertDialog(
          title: Text(task.title),
          content: Text(task.description),
          actions: <Widget>[
            TextButton(
              child: const Text('閉じる'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              onPressed: () {
                taskState.toggleTaskCompletion(task.id);
                Navigator.of(dialogContext).pop();
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              },
              child: Text(task.isCompleted ? '未完了に戻す' : '完了にする'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                taskState.removeTask(task);
                Navigator.of(dialogContext).pop();
                _selectedEvents.value = _getEventsForDay(_selectedDay!);
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '今日に戻る',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TableCalendar<dynamic>(
              locale: 'ja_JP',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
            const SizedBox(height: 8.0),
            ValueListenableBuilder<List<dynamic>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    if (event is Medication) {
                      final timeFormatted = event.time.format(context);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          onTap: () =>
                              _showMedicationDetailsDialog(context, event),
                          title: Text('${event.name} - $timeFormatted'),
                        ),
                      );
                    } else if (event is Task) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                          color: event.isCompleted ? Colors.grey[300] : null,
                        ),
                        child: ListTile(
                          onTap: () => _showTaskDetailsDialog(context, event),
                          title: Text(
                            event.title,
                            style: TextStyle(
                              decoration: event.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: Icon(
                            event.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskAddScreen()),
          );
        },
        tooltip: 'タスクを追加',
        child: const Icon(Icons.add_task),
      ),
    );
  }
}
