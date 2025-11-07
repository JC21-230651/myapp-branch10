
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CharacterState with ChangeNotifier {
  // --- State Properties ---
  String _characterName = '';
  String _characterPrompt = '';
  Uint8List? _currentImage;
  List<Uint8List> _imageHistory = [];
  String? _backgroundImagePath; // For user-selectable background
  bool _isGenerating = false;
  String? _error;

  // --- Getters for UI binding ---
  String get characterName => _characterName;
  String get characterPrompt => _characterPrompt;
  Uint8List? get currentImage => _currentImage;
  List<Uint8List> get imageHistory => _imageHistory;
  String? get backgroundImagePath => _backgroundImagePath;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  // --- Constructor ---
  CharacterState() {
    loadState();
  }

  // --- Public Methods for UI Interaction ---

  void setCharacterName(String name) {
    if (name != _characterName) {
      _characterName = name;
      _saveState();
      notifyListeners();
    }
  }

  void setCurrentImage(Uint8List imageBytes) {
    _currentImage = imageBytes;
    _saveState();
    notifyListeners();
  }
  
  Future<void> updateBackgroundImage(String? path) async {
    _backgroundImagePath = path;
    await _saveState();
    notifyListeners();
  }

  Future<void> generateImage(String prompt) async {
    if (prompt.trim().isEmpty) {
      throw Exception('Prompt cannot be empty.');
    }
    _isGenerating = true;
    _error = null;
    _characterPrompt = prompt;
    notifyListeners();

    try {
      final apiKey = dotenv.env['CHAT_GPT_API_KEY'];
      if (apiKey == null) {
        throw Exception('CHAT_GPT_API_KEY not found in .env file.');
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'n': 1,
          'size': '512x512',
          'response_format': 'url',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data'][0]['url'];
        final imageResponse = await http.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          final newImage = imageResponse.bodyBytes;
          _currentImage = newImage;
          _imageHistory.insert(0, newImage);
        } else {
          throw Exception('Failed to download image from URL.');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error from API';
        throw Exception('Failed to generate image: $errorMessage');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isGenerating = false;
      await _saveState();
      notifyListeners();
    }
  }

  Future<void> resetAll() async {
    _characterName = '';
    _characterPrompt = '';
    _currentImage = null;
    _imageHistory = [];
    _backgroundImagePath = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('char_name');
    await prefs.remove('char_prompt');
    await prefs.remove('char_current_image');
    await prefs.remove('char_image_history');
    await prefs.remove('char_background_image'); // Also remove background
    
    notifyListeners();
  }

  // --- Persistence Logic ---

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _characterName = prefs.getString('char_name') ?? '';
    _characterPrompt = prefs.getString('char_prompt') ?? '';
    _backgroundImagePath = prefs.getString('char_background_image');

    final imageHistoryStrings = prefs.getStringList('char_image_history') ?? [];
    _imageHistory = imageHistoryStrings.map((s) => base64Decode(s)).toList();

    final currentImageString = prefs.getString('char_current_image');
    if (currentImageString != null) {
      _currentImage = base64Decode(currentImageString);
    } else if (_imageHistory.isNotEmpty) {
      _currentImage = _imageHistory.first;
    }

    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('char_name', _characterName);
    await prefs.setString('char_prompt', _characterPrompt);

    final imageHistoryStrings = _imageHistory.map((bytes) => base64Encode(bytes)).toList();
    await prefs.setStringList('char_image_history', imageHistoryStrings);

    if (_currentImage != null) {
      await prefs.setString('char_current_image', base64Encode(_currentImage!));
    } else {
      await prefs.remove('char_current_image');
    }

    if (_backgroundImagePath != null) {
        await prefs.setString('char_background_image', _backgroundImagePath!);
    } else {
        await prefs.remove('char_background_image');
    }
  }
}
