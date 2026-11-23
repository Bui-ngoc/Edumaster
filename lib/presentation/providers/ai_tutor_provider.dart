import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/repositories/interfaces.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiTutorProvider extends ChangeNotifier {
  final IAiTutorRepository _aiRepo;

  AiTutorProvider({required IAiTutorRepository aiRepo})
      : _aiRepo = aiRepo {
    _messages.add(
      ChatMessage(
        text: '👋 Xin chào bạn! Mình là Trợ lý Gia sư AI EduMaster. '
            'Bạn có thắc mắc gì về thuật ngữ CNTT, thuật toán SM-2, '
            'toán học hay trắc nghiệm tiếng Anh không? Hãy hỏi mình nhé!',
        isUser: false,
      ),
    );
  }

  // Lịch sử hiển thị trên giao diện
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Lịch sử hội thoại gửi cho Gemini
  // Chỉ lưu các lượt trao đổi thành công.
  final List<ChatMessage> _conversationHistory = [];

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // Giới hạn 6 lượt hỏi - đáp gần nhất.
  static const int _maxHistoryMessages = 12;

  String _buildContextPrompt(String currentQuestion) {
    if (_conversationHistory.isEmpty) {
      return currentQuestion;
    }

    final history = _conversationHistory
        .map((message) {
      final role = message.isUser ? 'Người học' : 'EduMaster AI';
      return '$role: ${message.text}';
    })
        .join('\n\n');

    return '''
Dưới đây là lịch sử hội thoại giữa người học và EduMaster AI.

Hãy sử dụng lịch sử này để hiểu ngữ cảnh câu hỏi mới.
Nếu người học hỏi tiếp hoặc nhắc đến nội dung trước đó,
hãy dựa vào lịch sử để trả lời nhất quán.

LỊCH SỬ HỘI THOẠI:
$history

CÂU HỎI MỚI NHẤT:
$currentQuestion

Hãy trả lời trực tiếp câu hỏi mới nhất.
''';
  }

  Future<void> sendMessage(String text) async {
    final clean = text.trim();

    if (clean.isEmpty || _isGenerating) return;

    // Hiển thị câu hỏi của người dùng
    _messages.add(
      ChatMessage(
        text: clean,
        isUser: true,
      ),
    );

    _isGenerating = true;
    notifyListeners();

    try {
      // Tạo prompt bao gồm lịch sử hội thoại
      final prompt = _buildContextPrompt(clean);

      // Gọi AI
      final answer = await _aiRepo.askAi(prompt);

      // Chỉ lưu lịch sử khi API trả lời thành công
      _conversationHistory.add(
        ChatMessage(
          text: clean,
          isUser: true,
        ),
      );

      _conversationHistory.add(
        ChatMessage(
          text: answer,
          isUser: false,
        ),
      );

      // Giới hạn số tin nhắn lưu trong ngữ cảnh
      if (_conversationHistory.length > _maxHistoryMessages) {
        _conversationHistory.removeRange(
          0,
          _conversationHistory.length - _maxHistoryMessages,
        );
      }

      // Hiển thị câu trả lời
      _messages.add(
        ChatMessage(
          text: answer,
          isUser: false,
        ),
      );
    } catch (error) {
      debugPrint('AI Tutor không thể trả lời: ${error.runtimeType}');
      final message = error is TimeoutException
          ? 'Gemini phản hồi quá lâu.'
          : 'AI Tutor chưa trả lời được.';
      _messages.add(
        ChatMessage(
          text: '⚠️ $message Hãy thử lại hoặc chuyển sang chế độ ngoại tuyến.',
          isUser: false,
        ),
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    if (_isGenerating) return;

    _messages.clear();
    _conversationHistory.clear();

    _messages.add(
      ChatMessage(
        text: 'Cuộc trò chuyện đã được làm mới. '
            'Hãy đặt câu hỏi cho AI Tutor nhé!',
        isUser: false,
      ),
    );

    notifyListeners();
  }
}