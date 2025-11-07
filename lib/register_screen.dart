import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepGoalController = TextEditingController();
  final _sleepGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    final healthState = Provider.of<HealthState>(context, listen: false);
    _stepGoalController.text = healthState.stepGoal.toStringAsFixed(0);
    _sleepGoalController.text = healthState.sleepGoal.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _stepGoalController.dispose();
    _sleepGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    if (_formKey.currentState!.validate()) {
      final healthState = Provider.of<HealthState>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();

      final stepGoal = double.tryParse(_stepGoalController.text) ?? 10000.0;
      final sleepGoal = double.tryParse(_sleepGoalController.text) ?? 8.0;

      healthState.updateStepGoal(stepGoal);
      healthState.updateSleepGoal(sleepGoal);
      
      await prefs.setDouble('stepGoal', stepGoal);
      await prefs.setDouble('sleepGoal', sleepGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目標を保存しました')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目標設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _stepGoalController,
                decoration: const InputDecoration(labelText: '歩数の目標', suffixText: '歩'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '値を入力してください';
                  if (double.tryParse(value) == null) return '数値を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _sleepGoalController,
                decoration: const InputDecoration(labelText: '睡眠時間の目標', suffixText: '時間'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 validator: (value) {
                  if (value == null || value.isEmpty) return '値を入力してください';
                  if (double.tryParse(value) == null) return '数値を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveGoals,
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
