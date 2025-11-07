import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CharacterState with ChangeNotifier {
  // --- State Properties ---
  String _characterName = '';
  String _characterPrompt = '';
  Uint8List? _currentImage;
  List<Uint8List> _imageHistory = [];
  String? _backgroundImagePath;
  bool _isGenerating = false;
  String? _error;

  // --- Getters ---
  String get characterName => _characterName;
  String get characterPrompt => _characterPrompt;
  Uint8List? get currentImage => _currentImage;
  List<Uint8List> get imageHistory => _imageHistory;
  String? get backgroundImagePath => _backgroundImagePath;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  // --- API Configuration ---
  // IMPORTANT: Replace with your actual API key and project ID.
  final String _apiKey = 'YOUR_API_KEY';
  final String _projectID = 'YOUR_PROJECT_ID';


  CharacterState() {
    loadState();
  }

  // --- Public Methods ---

  void setCharacterName(String name) {
    if (name != _characterName) {
      _characterName = name;
      _saveState();
      notifyListeners();
    }
  }

  void setCurrentImage(Uint8List imageBytes) {
    _currentImage = imageBytes;
    if (!_imageHistory.contains(imageBytes)) {
      _imageHistory.insert(0, imageBytes);
    }
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
      _error = 'Prompt cannot be empty.';
      notifyListeners();
      return;
    }
    _isGenerating = true;
    _error = null;
    _characterPrompt = prompt;
    notifyListeners();

    final url = Uri.parse('https://us-central1-aiplatform.googleapis.com/v1/projects/$_projectID/locations/us-central1/publishers/google/models/imagegeneration:predict');

    final body = jsonEncode({
      'instances': [
        {'prompt': prompt}
      ],
      'parameters': {
        'sampleCount': 1
      }
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
        final imageBytesString = decodedResponse['predictions'][0]['bytesBase64Encoded'];
        final newImage = base64Decode(imageBytesString);
        
        _currentImage = newImage;
        _imageHistory.insert(0, newImage);

      } else {
        throw Exception('Image generation failed: ${response.body}');
      }
    } catch (e) {
      _error = 'Error generating image: $e';
      rethrow; // Or handle it more gracefully
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
    await prefs.clear(); // A more thorough way to reset
    
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
