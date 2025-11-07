import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

class ChatProvider with ChangeNotifier {
  final OpenAI openAI;
  String? _errorMessage;

  ChatProvider() : openAI = OpenAI.instance.build(token: dotenv.env['CHATGPT_API_KEY']);

  String? get errorMessage => _errorMessage;

  Future<bool> containsProperNouns(String prompt) async {
    _errorMessage = null;

    try {
      final request = ChatCompleteText(
        messages: [
          {"role": "user", "content": '$promptに固有名詞は含まれますか？「はい」か「いいえ」で答えてください。'}
        ],
        maxToken: 10,
        model: GptTurboChatModel(),
      );
      final response = await openAI.onChatCompletion(request: request);
      final answer = response?.choices.first.message?.content.trim();

      if (answer == 'はい') {
        final request2 = ChatCompleteText(
          messages: [
            {"role": "user", "content": '含まれている固有名詞は著作権、商標権、特許権、企業秘密、プライバシー権、パブリシティ権及びその他の知的財産権で保護されていますか？「はい」か「いいえ」で答えてください。'}
          ],
          maxToken: 10,
          model: GptTurboChatModel(),
        );
        final response2 = await openAI.onChatCompletion(request: request2);
        final answer2 = response2?.choices.first.message?.content.trim();

        if (answer2 == 'いいえ') {
          return true;
        } else if (answer2 == 'はい') {
          _errorMessage = '含まれている固有名詞は知的財産権で保護されている可能性があります。';
          notifyListeners();
          return false;
        } else {
          _errorMessage = '2つ目の質問に対する予期しない回答です。';
          notifyListeners();
          return false;
        }
      } else if (answer == 'いいえ') {
        return true;
      } else {
        _errorMessage = '1つ目の質問に対する予期しない回答です。';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'ChatGPT APIとの通信中にエラーが発生しました: $e';
      notifyListeners();
      return false;
    }
  }
}
