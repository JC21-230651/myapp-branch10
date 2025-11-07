import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('その他'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('通知設定'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/other/notification_setting');
            },
          ),
          ListTile( // この項目を復活
            leading: const Icon(Icons.person_outline),
            title: const Text('AIアシスタント設定'),
            onTap: () => context.go('/other/character_setting'),
          ),
          // 他の項目をここに追加できます
        ],
      ),
    );
  }
}
