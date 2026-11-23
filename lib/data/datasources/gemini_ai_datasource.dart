import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quiz_question.dart';
import 'local_ai_engine.dart';

class GeminiAiDataSource {
  static const String _demoModePref = 'edumaster_demo_mode';
  final String _chatUrl;

  GeminiAiDataSource({
    String chatUrl = const String.fromEnvironment('AI_TUTOR_CHAT_URL'),
  }) : _chatUrl = chatUrl;

  Future<bool> isDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoModePref) ?? false;
  }

  Future<void> setDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(_demoModePref, value)) {
      await prefs.reload();
      throw StateError('Không thể lưu chế độ AI Tutor.');
    }
  }

  Future<String> askAi(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw ArgumentError('Vui lòng nhập nội dung câu hỏi.');
    }
    if (await isDemoMode()) {
      return LocalAiEngine.processQuery(cleanPrompt);
    }
    return _callBackend(cleanPrompt);
  }

  Future<String> _callBackend(String prompt) async {
    final endpoint = Uri.tryParse(_chatUrl);
    if (endpoint == null ||
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty) {
      throw StateError('Chưa cấu hình URL HTTPS cho AI Tutor.');
    }

    final response = await http
        .post(
          endpoint,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt}),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      debugPrint('AI Tutor backend: HTTP ${response.statusCode}');
      throw StateError('Máy chủ AI Tutor không trả lời được yêu cầu.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final answer = data is Map<String, dynamic> ? data['answer'] : null;
    if (answer is! String || answer.trim().isEmpty) {
      throw StateError('Gemini không trả về nội dung.');
    }
    return answer.trim();
  }

  Future<String> explainWrongAnswer({
    required QuizQuestion question,
    required int selectedIndex,
    required bool isEnglish,
  }) async {
    final options = isEnglish ? question.optionsEn : question.optionsVi;
    final correctIndex = question.correctIndex;
    if (correctIndex < 0 || correctIndex >= options.length) {
      return isEnglish
          ? 'The correct answer is unavailable for this question.'
          : 'Câu hỏi này chưa có đáp án đúng.';
    }

    final correctOption = options[correctIndex];
    final explanation = isEnglish
        ? question.explanationEn
        : question.explanationVi;
    final answerLabel = isEnglish ? 'Correct answer' : 'Đáp án đúng';
    final reference = '$answerLabel: **$correctOption**\n$explanation'.trim();
    if (selectedIndex < 0 ||
        selectedIndex >= options.length ||
        selectedIndex == correctIndex) {
      return reference;
    }

    try {
      if (await isDemoMode()) return reference;

      final selectedOption = options[selectedIndex];
      final prompt = isEnglish
          ? '''
Question: ${question.questionEn}
Selected answer: $selectedOption
Correct answer: $correctOption
Reference explanation: $explanation

Explain in English why the selected answer is incorrect and why the correct answer is right.
'''
          : '''
Câu hỏi: ${question.questionVi}
Học viên chọn: $selectedOption
Đáp án đúng: $correctOption
Giải thích tham khảo: $explanation

Hãy giải thích bằng tiếng Việt vì sao đáp án đã chọn sai và đáp án đúng chính xác.
''';

      return await _callBackend(prompt);
    } catch (error) {
      debugPrint('AI Tutor không thể giải thích câu hỏi: ${error.runtimeType}');
      return reference;
    }
  }
}
