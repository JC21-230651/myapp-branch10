
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:myapp/medication_state.dart';
import 'package:myapp/models/medication.dart';
import 'package:myapp/medication_form.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<Medication>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(
      context.read<MedicationState>().getEventsForDay(_selectedDay!),
    );
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value =
          context.read<MedicationState>().getEventsForDay(selectedDay);
    }
  }

  void _showMedicationDetailsDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Capture the MedicationState before the async gap
        final medicationState = Provider.of<MedicationState>(context, listen: false);
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
              child: const Text('削除'),
              onPressed: () {
                medicationState.removeMedication(medication);
                Navigator.of(dialogContext).pop();
                _selectedEvents.value =
                    medicationState.getEventsForDay(_selectedDay!);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicationState = Provider.of<MedicationState>(context);

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
              _selectedEvents.value =
                  context.read<MedicationState>().getEventsForDay(_selectedDay!);
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make column height fit its children
          children: [
            TableCalendar<Medication>(
              locale: 'ja_JP',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: medicationState.getEventsForDay,
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
            ValueListenableBuilder<List<Medication>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  shrinkWrap: true, // Let the ListView determine its own height
                  physics: const NeverScrollableScrollPhysics(), // Disable nested scrolling
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final medication = value[index];
                    final timeFormatted = medication.time.format(context);
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
                            _showMedicationDetailsDialog(context, medication),
                        title: Text('${medication.name} - $timeFormatted'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => const MedicationForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
