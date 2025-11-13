import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/task_state.dart';
import 'package:myapp/task_add_screen.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskState = Provider.of<TaskState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク一覧'),
      ),
      body: ListView.builder(
        itemCount: taskState.tasks.length,
        itemBuilder: (context, index) {
          final task = taskState.tasks[index];
          return ListTile(
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(task.description),
            trailing: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                taskState.toggleTaskCompletion(task.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskAddScreen()),
          );
        },
        tooltip: 'タスクを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
