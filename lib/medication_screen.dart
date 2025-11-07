
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/medication_state.dart';
import 'package:myapp/medication_form.dart'; // Corrected import path

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  void _showAddMedicationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        // This Padding cannot be const because it depends on MediaQuery.
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const MedicationForm(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お薬管理'),
      ),
      body: Consumer<MedicationState>(
        builder: (context, state, child) {
          if (state.medications.isEmpty) {
            return const Center(
              child: Text('登録されているお薬はありません。'),
            );
          }
          return ListView.builder(
            itemCount: state.medications.length,
            itemBuilder: (context, index) {
              final medication = state.medications[index];
              return ListTile(
                title: Text(medication.name),
                subtitle: Text('服用時間: ${medication.time.format(context)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    context.read<MedicationState>().removeMedication(medication);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(context),
        tooltip: 'お薬を追加', // Tooltip before child
        child: const Icon(Icons.add),
      ),
    );
  }
}
