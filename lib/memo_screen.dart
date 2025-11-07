import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MemoScreen extends StatelessWidget {
  final DateTime? selectedDate;

  const MemoScreen({super.key, this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final date = selectedDate ?? DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy/MM/dd').format(date)),
      ),
      body: const Center(
        child: Text('メモ画面'),
      ),
    );
  }
}
