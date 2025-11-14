import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今後2週間のスケジュール'),
      ),
      body: const Center(
        child: Text('スケジュール生成機能は現在開発中です。'),
      ),
    );
  }
}
