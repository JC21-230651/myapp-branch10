
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/character_state.dart'; // Import CharacterState
import 'health_state.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      final healthState = Provider.of<HealthState>(context, listen: false);
      healthState.checkPermissionsAndFetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthState = Provider.of<HealthState>(context);
    final characterState = Provider.of<CharacterState>(context); // Access CharacterState

    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルスケア'),
      ),
      drawer: _buildDrawer(),
      body: _buildBody(healthState, characterState),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Text('メニュー', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('週間レポート'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              context.go('/health/weekly_report');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(HealthState healthState, CharacterState characterState) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (kIsWeb)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      "歩数や睡眠などのヘルスケアデータ連携はモバイルアプリ版でのみご利用いただけます。",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (healthState.healthDataNotGranted)
              const Center(child: Text('権限が付与されていません'))
            else if (healthState.sleepData.isEmpty && healthState.stepsData.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildLatestDataCard(context, '睡眠', healthState.latestSleep, Icons.bedtime),
              const SizedBox(height: 20),
              _buildLatestDataCard(context, '歩数', healthState.latestSteps, Icons.directions_walk),
            ],
            const SizedBox(height: 250), // Make sure there is enough space for the character image
          ],
        ),
        // Display the character image dynamically
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: characterState.currentImage != null
                ? Image.memory(
                    characterState.currentImage!,
                    fit: BoxFit.contain,
                  )
                : Container(
                    height: 200, // Placeholder height
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_outline,
                      size: 100,
                      color: Colors.grey.shade400,
                    ),
                  ), 
          ),
        ),
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: _buildChatBubble(context),
        ),
      ],
    );
  }

  Widget _buildLatestDataCard(BuildContext context, String title, HealthData? data, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (data != null)
                  Text('${data.value.toStringAsFixed(1)} ${data.unit}', style: Theme.of(context).textTheme.titleLarge)
                else
                  const Text('データなし', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => context.go('/health/chat'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.teal),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'AIアシスタントに健康について相談する',
                  style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
