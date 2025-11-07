import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/health_state.dart';

class ChatState with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final HealthState _healthState;

  // IMPORTANT: Replace with your actual API key and project ID.
  final String _apiKey = 'YOUR_API_KEY';
  final String _projectID = 'YOUR_PROJECT_ID';

  ChatState(this._healthState);

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    _addMessage(text, isUser: true);
    _isLoading = true;
    notifyListeners();

    final url = Uri.parse('https://us-central1-aiplatform.googleapis.com/v1/projects/$_projectID/locations/us-central1/publishers/google/models/gemini-1.5-flash:streamGenerateContent');

    final healthContext = _createHealthContext();
    final fullPrompt = '$healthContext\n\nUser: $text';

    final body = jsonEncode({
      'contents': [{
        'parts': [{
          'text': fullPrompt
        }]
      }]
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final generatedText = decodedResponse[0]['candidates'][0]['content']['parts'][0]['text'];
        _addMessage(generatedText, isUser: false);
      } else {
        _addMessage('Sorry, I couldn\'t get a response. ${response.body}', isUser: false);
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
System: You are a helpful and friendly health assistant.
Here's the user's current health data:
- Today's steps: ${steps.toStringAsFixed(0)} (Goal: ${stepGoal.toStringAsFixed(0)})
- Last night's sleep: ${sleepHours.toStringAsFixed(1)} hours (Goal: ${sleepGoal.toStringAsFixed(1)} hours)
Please respond to the user's message in a supportive and encouraging tone.
''';
  }

  void _addMessage(String text, {required bool isUser}) {
    _messages.insert(0, ChatMessage(text: text, isUser: isUser));
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
