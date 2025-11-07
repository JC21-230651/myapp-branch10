
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/character_state.dart';

class CharacterSettingScreen extends StatefulWidget {
  const CharacterSettingScreen({super.key});

  @override
  State<CharacterSettingScreen> createState() => _CharacterSettingScreenState();
}

class _CharacterSettingScreenState extends State<CharacterSettingScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    final characterState = context.read<CharacterState>();
    _nameController = TextEditingController(text: characterState.characterName);
    _promptController = TextEditingController(text: characterState.characterPrompt);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    final characterState = context.read<CharacterState>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final prompt = _promptController.text;

    if (prompt.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('プロンプトを入力してください。')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await characterState.generateImage(prompt);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('画像の生成に失敗しました: $e')),
      );
    } finally {
      // Use the captured navigator to pop the dialog
      if (navigator.mounted) {
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterState = Provider.of<CharacterState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('キャラクター設定'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (characterState.currentImage != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51), // 20% opacity
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      characterState.currentImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[400]!)
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                      size: 64,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              Text('キャラクター名', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例: 健康サポーター'
                ),
                onChanged: (value) {
                  characterState.setCharacterName(value);
                },
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              Text('画像生成プロンプト', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例: 青い鳥、幸せそうに飛んでいる、アニメスタイル'
                ),
                maxLines: 4, // Allow multiple lines for longer prompts
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: characterState.isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(characterState.isGenerating ? '生成中...' : '新しい画像を生成'),
                onPressed: characterState.isGenerating ? null : _generateImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              Text('画像ギャラリー', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildImageHistory(characterState),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                icon: const Icon(Icons.delete_sweep),
                label: const Text('設定と画像をリセット'),
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('確認'),
                      content: const Text('本当にすべての設定と生成した画像をリセットしますか？この操作は元に戻せません。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('リセット'),
                        ),
                      ],
                    ),
                  ) ?? false;

                  if (confirm) {
                    await characterState.resetAll();
                    _nameController.text = '';
                    _promptController.text = '';
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('設定をリセットしました。')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHistory(CharacterState characterState) {
    if (characterState.imageHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'まだ生成された画像がありません。',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Important when inside a SingleChildScrollView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: characterState.imageHistory.length,
      itemBuilder: (context, index) {
        final imageBytes = characterState.imageHistory[index];
        return GestureDetector(
          onTap: () {
            characterState.setCurrentImage(imageBytes);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(imageBytes, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
