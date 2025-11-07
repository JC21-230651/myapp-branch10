
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/medication_state.dart';
import 'package:myapp/models/medication.dart';

class MedicationForm extends StatefulWidget {
  const MedicationForm({super.key});

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  TimeOfDay _time = TimeOfDay.now();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final medicationState = context.read<MedicationState>();

      // Create a new Medication object with a unique ID.
      // A simple timestamp can be used for uniqueness.
      final newMedication = Medication(
        id: DateTime.now().millisecondsSinceEpoch,
        name: _name,
        time: _time,
      );

      medicationState.addMedication(newMedication);
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(labelText: '薬の名前'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '薬の名前を入力してください';
                }
                return null;
              },
              onSaved: (value) {
                _name = value!;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('服用時間: ${_time.format(context)}'),
                TextButton(
                  onPressed: () => _selectTime(context),
                  child: const Text('時間を選択'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}
