import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey;

  WeatherService({required this.apiKey});

  Future<String> getWeather(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ja';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = data['weather'][0]['description'];
        final temp = data['main']['temp'];
        return '現在の天気: $weather, 気温: ${temp.toStringAsFixed(1)}°C';
      } else {
        return '天気情報の取得に失敗しました。';
      }
    } catch (e) {
      return '天気情報の取得中にエラーが発生しました。';
    }
  }
}
