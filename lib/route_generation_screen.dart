import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'services/directions_service.dart';
import 'services/weather_service.dart';

class RouteGenerationScreen extends StatefulWidget {
  const RouteGenerationScreen({super.key});

  @override
  State<RouteGenerationScreen> createState() => _RouteGenerationScreenState();
}

class _RouteGenerationScreenState extends State<RouteGenerationScreen> {
  bool _isFeatureSupported = false;

  String _weatherInfo = '天気情報を取得中...';

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  List<Event> _calendarEvents = [];

  GoogleMapController? _mapController;
  final LatLng _defaultCenter =
      const LatLng(35.681236, 139.767125); // Tokyo Station
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String _selectedTransportation = 'driving';

  final loc.Location _locationService = loc.Location();

  final DirectionsService _directionsService =
      DirectionsService(apiKey: 'YOUR_GOOGLE_MAPS_API_KEY');
  final WeatherService _weatherService =
      WeatherService(apiKey: 'YOUR_OPENWEATHERMAP_API_KEY');

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    if (!kIsWeb && Platform.isIOS) {
      _isFeatureSupported = true;
      _initPlatformState();
    }
  }

  Future<void> _initPlatformState() async {
    await _requestPermissions();
    await _getCurrentLocation();
    await _retrieveCalendarEvents();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await _deviceCalendarPlugin.requestPermissions();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _locationService.getLocation();
      if (mounted) {
        setState(() {
          _currentLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: _currentLocation!,
              infoWindow: const InfoWindow(title: '現在地'),
            ),
          );
        });
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 13));
        _getWeather();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherInfo = '現在地の取得に失敗しました。';
        });
      }
    }
  }

  Future<void> _getWeather() async {
    if (_currentLocation != null) {
      final weather = await _weatherService.getWeather(
          _currentLocation!.latitude, _currentLocation!.longitude);
      if (mounted) {
        setState(() {
          _weatherInfo = weather;
        });
      }
    }
  }

  Future<void> _retrieveCalendarEvents() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data!.isNotEmpty) {
        final calendar = calendarsResult.data!.first;
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
            calendar.id,
            RetrieveEventsParams(
              startDate: startOfDay,
              endDate: endOfDay,
            ));
        if (eventsResult.isSuccess && mounted) {
          setState(() {
            _calendarEvents = eventsResult.data ?? [];
          });
        }
      }
    } catch (e) {
      // Handle calendar errors
    }
  }

  void _generateRoute() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!_isFeatureSupported ||
        _currentLocation == null ||
        _calendarEvents.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('経路生成機能は現在利用できません。現在地または予定がありません。')),
      );
      return;
    }

    final destinationEvent = _calendarEvents.firstWhere(
        (e) => e.location != null,
        orElse: () => _calendarEvents.first);
    if (destinationEvent.location == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('予定に目的地が設定されていません。')),
      );
      return;
    }

    LatLng destination;
    try {
      final locations = await locationFromAddress(destinationEvent.location!);
      if (locations.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('目的地のジオコーディングに失敗しました。')),
        );
        return;
      }
      destination = LatLng(locations.first.latitude, locations.first.longitude);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('ジオコーディングエラー: $e')),
      );
      return;
    }

    final polylinePoints =
        await _directionsService.getDirections(_currentLocation!, destination);

    if (mounted) {
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            infoWindow: InfoWindow(title: destinationEvent.title),
          ),
        );
      });
    }
  }

  void _registerRouteToCalendar() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!_isFeatureSupported) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('カレンダー登録機能は現在利用できません。')),
      );
      return;
    }

    if (_polylines.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('まず経路を生成してください。')),
      );
      return;
    }

    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data!.isNotEmpty) {
        final calendar = calendarsResult.data!.first;
        final location = tz.getLocation('Asia/Tokyo');
        final now = tz.TZDateTime.now(location);
        final event = Event(
          calendar.id,
          title: '今日の経路',
          description: '生成された移動経路です。',
          start: now,
          end: now.add(const Duration(hours: 1)),
        );
        await _deviceCalendarPlugin.createOrUpdateEvent(event);

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('経路をカレンダーに登録しました。')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('カレンダーへの登録に失敗しました: $e')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      controller
          .animateCamera(CameraUpdate.newLatLngZoom(_currentLocation!, 13));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isFeatureSupported ? _buildSupportedUI() : _buildUnsupportedUI();
  }

  Widget _buildUnsupportedUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('経路生成'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('経路生成',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('この機能は現在お使いのプラットフォームではサポートされていません。'),
            SizedBox(height: 20),
            Text('天気予報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('天気情報の取得は現在サポートされていません。'),
            SizedBox(height: 20),
            Text('カレンダーの予定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('カレンダー連携は現在サポートされていません。'),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('経路生成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('天気予報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_weatherInfo),
            const SizedBox(height: 20),
            const Text('カレンダーの予定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _calendarEvents.isEmpty
                ? const Text('今日の予定はありません。')
                : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      itemCount: _calendarEvents.length,
                      itemBuilder: (context, index) {
                        final event = _calendarEvents[index];
                        return ListTile(
                          title: Text(event.title ?? ''),
                          subtitle: Text(event.location ?? ''),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<DateTime>(
                  value: _selectedDate,
                  items: List.generate(
                    14,
                    (index) => DateUtils.dateOnly(DateTime.now())
                        .add(Duration(days: index)),
                  ).map((date) {
                    return DropdownMenuItem(
                      value: date,
                      child: Text(DateFormat('MM/dd(E)', 'ja').format(date)),
                    );
                  }).toList(),
                  onChanged: (date) {
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
                DropdownButton<String>(
                  value: _selectedTransportation,
                  items: const [
                    DropdownMenuItem(value: 'driving', child: Text('車')),
                    DropdownMenuItem(value: 'transit', child: Text('公共交通機関')),
                    DropdownMenuItem(value: 'walking', child: Text('徒歩')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTransportation = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation ?? _defaultCenter,
                  zoom: 13.0,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _generateRoute,
                child: const Text('経路を生成'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _registerRouteToCalendar,
                child: const Text('今日の経路情報として登録'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
