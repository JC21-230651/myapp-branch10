import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/health_state.dart';

class ChatState with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final HealthState _healthState;

  ChatState(this._healthState);

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    _addMessage(text, isUser: true);
    _isLoading = true;
    notifyListeners();

    try {
      final apiKey = dotenv.env['CHAT_GPT_API_KEY'];
      final healthContext = _createHealthContext();

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant. $healthContext'
            },
            {'role': 'user', 'content': text},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        _addMessage(content, isUser: false);
      } else {
        _addMessage('Error: ${response.body}', isUser: false);
      }
    } catch (e) {
      _addMessage('Error: $e', isUser: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _createHealthContext() {
    final steps = _healthState.latestSteps?.value ?? 0;
    final sleepHours = _healthState.latestSleep?.value ?? 0;
    final stepGoal = _healthState.stepGoal;
    final sleepGoal = _healthState.sleepGoal;
    return '''
Health data context:
- Today's steps: ${steps.toStringAsFixed(0)} (Goal: ${stepGoal.toStringAsFixed(0)})
- Last night's sleep: ${sleepHours.toStringAsFixed(1)} hours (Goal: ${sleepGoal.toStringAsFixed(1)} hours)
''';
  }

  void _addMessage(String text, {required bool isUser}) {
    _messages.add(ChatMessage(text: text, isUser: isUser));
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
