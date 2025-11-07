
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:myapp/chat_state.dart';
import 'package:myapp/character_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatState chatState) {
    if (_textController.text.isNotEmpty) {
      chatState.sendMessage(_textController.text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final characterState = context.read<CharacterState>();
    // Capture ScaffoldMessenger before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await characterState.updateBackgroundImage(image.path);
      }
    } catch (e) {
      // Use the captured ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterState = context.watch<CharacterState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI健康相談'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _pickImage,
            tooltip: '背景画像を選択',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image with a dark overlay for better text readability
          if (characterState.backgroundImagePath != null && 
              File(characterState.backgroundImagePath!).existsSync())
            Positioned.fill(
              child: Image.file(
                File(characterState.backgroundImagePath!),
                fit: BoxFit.cover,
                color: Colors.black.withAlpha(77), // 30% opacity
                colorBlendMode: BlendMode.darken,
              ),
            )
          else if (characterState.currentImage != null)
            // Fallback to the character image
            Positioned.fill(
              child: Image.memory(
                characterState.currentImage!,
                fit: BoxFit.cover,
                color: Colors.black.withAlpha(77), // 30% opacity
                colorBlendMode: BlendMode.darken,
              ),
            ),

          // Chat UI
          Column(
            children: [
              Expanded(
                child: Consumer<ChatState>(
                  builder: (context, chatState, child) {
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatState.messages[index];
                        return ChatMessageWidget(
                          message: message.text,
                          isUser: message.isUser,
                        );
                      },
                    );
                  },
                ),
              ),
              Consumer<ChatState>(
                builder: (context, chatState, child) {
                  return chatState.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        )
                      : const SizedBox.shrink();
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'メッセージを入力',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white.withAlpha(204), // 80% opacity
                        ),
                        onSubmitted: (text) =>
                            _sendMessage(context.read<ChatState>()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () =>
                          _sendMessage(context.read<ChatState>()),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatMessageWidget({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
            color: isUser
                ? Theme.of(context).primaryColor.withAlpha(230) // 90% opacity
                : Colors.white.withAlpha(230), // 90% opacity
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(26), // 10% opacity
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
