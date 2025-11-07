import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class EventEditScreen extends StatefulWidget {
  final Event? event;
  final Calendar? calendar;
  final DateTime? selectedDate;

  const EventEditScreen({
    super.key,
    this.event,
    this.calendar,
    this.selectedDate,
  });

  @override
  EventEditScreenState createState() => EventEditScreenState();
}

class EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
    _startDate =
        widget.event?.start?.toLocal() ?? widget.selectedDate ?? DateTime.now();
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _endDate = widget.event?.end?.toLocal() ??
        _startDate.add(const Duration(hours: 1));
    _endTime = TimeOfDay.fromDateTime(_endDate);
    _isAllDay = widget.event?.allDay ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? '予定の追加' : '予定の編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '詳細'),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('終日'),
                value: _isAllDay,
                onChanged: (value) {
                  setState(() {
                    _isAllDay = value;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title:
                    Text('開始: ${DateFormat('yyyy/MM/dd').format(_startDate)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
              if (!_isAllDay)
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('開始時間: ${_startTime.format(context)}'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() {
                        _startTime = time;
                      });
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('終了: ${DateFormat('yyyy/MM/dd').format(_endDate)}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
              ),
              if (!_isAllDay)
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('終了時間: ${_endTime.format(context)}'),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() {
                        _endTime = time;
                      });
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (widget.calendar == null || widget.calendar!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カレンダーが見つかりません')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final start = _isAllDay
          ? DateTime(_startDate.year, _startDate.month, _startDate.day)
          : DateTime(_startDate.year, _startDate.month, _startDate.day,
              _startTime.hour, _startTime.minute);

      final end = _isAllDay
          ? DateTime(_endDate.year, _endDate.month, _endDate.day)
          : DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour,
              _endTime.minute);

      final eventToSave = Event(
        widget.calendar!.id!,
        eventId: widget.event?.eventId,
        title: _titleController.text,
        description: _descriptionController.text,
        start: tz.TZDateTime.from(start, tz.local),
        end: tz.TZDateTime.from(end, tz.local),
        allDay: _isAllDay,
      );

      final plugin = DeviceCalendarPlugin();
      final result = await plugin.createOrUpdateEvent(eventToSave);

      if (result?.isSuccess == true) {
        if (mounted) {
          context.pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '予定の保存に失敗しました: ${result?.errors.map((e) => e.errorMessage).join(', ')}')),
          );
        }
      }
    }
  }
}
