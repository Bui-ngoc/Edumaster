import 'package:edumaster/data/datasources/gemini_ai_datasource.dart';
import 'package:edumaster/data/datasources/local_ai_engine.dart';
import 'package:edumaster/domain/entities/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kiểm thử AI Tutor: Chế độ Ngoại tuyến vs Trực tuyến & Chống lỗi tính toán', () {
    test('1. Chế độ Ngoại tuyến: Giải đáp chi tiết các câu hỏi MÔN HỌC', () {
      final dartRes = LocalAiEngine.processQuery('dart là gì');
      expect(dartRes.contains('Dart'), isTrue);
      expect(dartRes.contains('60.0 - 120.0'), isFalse);

      final cleanRes = LocalAiEngine.processQuery(
        'Clean Architecture trong Flutter',
      );
      expect(cleanRes.contains('Clean Architecture'), isTrue);
      expect(cleanRes.contains('Presentation'), isTrue);
      expect(cleanRes.contains('60.0 - 120.0'), isFalse);

      final compareRes = LocalAiEngine.processQuery('Phân biệt List và Tuple');
      expect(compareRes.contains('List'), isTrue);
      expect(compareRes.contains('Tuple'), isTrue);
      expect(compareRes.contains('60.0 - 120.0'), isFalse);

      final constRes = LocalAiEngine.processQuery('So sánh final và const');
      expect(constRes.contains('final'), isTrue);
      expect(constRes.contains('const'), isTrue);
      expect(constRes.contains('60.0 - 120.0'), isFalse);

      final sm2Res = LocalAiEngine.processQuery('Thuật toán SM-2 là gì?');
      expect(sm2Res.contains('SuperMemo SM-2'), isTrue);
      expect(sm2Res.contains('Ease Factor'), isTrue);
    });

    test('2. Ngăn chặn triệt để lỗi Regex toán học khi lịch sử có chứa số (60 - 120 FPS)', () {
      const historyPrompt = '''
Dưới đây là lịch sử hội thoại giữa người học và EduMaster AI:
Người học: Flutter là gì?
EduMaster AI: Flutter đạt hiệu năng siêu mượt (60 - 120 FPS) nhờ bộ dựng Skia / Impeller.

CÂU HỎI MỚI NHẤT:
Clean Architecture trong Flutter
Hãy trả lời trực tiếp câu hỏi mới nhất.
''';

      final res = LocalAiEngine.processQuery(historyPrompt);
      expect(res.contains('Clean Architecture'), isTrue);
      expect(res.contains('Kết quả tính toán'), isFalse);
      expect(res.contains('60.0 - 120.0 = -60'), isFalse);
    });

    test('3. Chỉ tính toán số học khi câu hỏi thực sự là phép tính toán', () {
      final mathRes1 = LocalAiEngine.processQuery('2 + 2');
      expect(mathRes1.contains('2 + 2 = 4'), isTrue);

      final mathRes2 = LocalAiEngine.processQuery('tính 15 * 4');
      expect(mathRes2.contains('15 * 4 = 60'), isTrue);

      final scoreRes = LocalAiEngine.processQuery(
        'Tính điểm thi đúng 16/20 câu',
      );
      expect(scoreRes.contains('8.0 điểm'), isTrue);
      expect(
        LocalAiEngine.processQuery('Tính điểm thi đúng 7 trên 10 câu'),
        contains('7.0 điểm'),
      );
      expect(
        LocalAiEngine.processQuery('Tính điểm thi đúng 2/0 câu'),
        contains('Tổng số câu phải lớn hơn 0'),
      );
    });

    test('4. Chế độ Ngoại tuyến: TỪ CHỐI các câu hỏi NGOÀI môn học & hướng dẫn bật Online', () {
      final cookingRes = LocalAiEngine.processQuery(
        'Công thức nấu món phở bò truyền thống?',
      );
      expect(
        cookingRes.contains(
          'Chế độ Ngoại tuyến (Offline Mode) — Giới hạn phạm vi Môn học',
        ),
        isTrue,
      );
      expect(cookingRes.contains('Chế độ Trực tuyến (Online)'), isTrue);

      final weatherRes = LocalAiEngine.processQuery(
        'Dự báo thời tiết Hà Nội ngày mai thế nào?',
      );
      expect(
        weatherRes.contains(
          'Chế độ Ngoại tuyến (Offline Mode) — Giới hạn phạm vi Môn học',
        ),
        isTrue,
      );

      final singerRes = LocalAiEngine.processQuery(
        'Ca sĩ Taylor Swift sinh năm bao nhiêu?',
      );
      expect(
        singerRes.contains(
          'Chế độ Ngoại tuyến (Offline Mode) — Giới hạn phạm vi Môn học',
        ),
        isTrue,
      );
    });

    test(
      'Chế độ ngoại tuyến được lưu và hoạt động khi chưa khởi tạo Firebase',
          () async {
        SharedPreferences.setMockInitialValues({});
        final dataSource = GeminiAiDataSource();

        expect(await dataSource.isDemoMode(), isFalse);
        await dataSource.setDemoMode(true);

        final newDataSource = GeminiAiDataSource();
        expect(await newDataSource.isDemoMode(), isTrue);
        expect(await newDataSource.askAi('  Dart là gì?  '), contains('Dart'));
        await expectLater(newDataSource.askAi('  '), throwsArgumentError);
      },
    );

    test(
      'Lời giải dùng đáp án và ngôn ngữ của câu hỏi khi Gemini không khả dụng',
          () async {
        SharedPreferences.setMockInitialValues({});
        final dataSource = GeminiAiDataSource();
        const question = QuizQuestion(
          id: 1,
          grade: 12,
          category: 'Dart',
          questionVi: 'Kiểu nào biểu diễn số nguyên?',
          questionEn: 'Which type represents an integer?',
          optionsVi: ['int', 'Chuỗi'],
          optionsEn: ['int', 'String'],
          correctIndex: 0,
          explanationVi: 'int biểu diễn số nguyên.',
          explanationEn: 'int represents an integer.',
        );

        await dataSource.setDemoMode(true);
        expect(
          await dataSource.explainWrongAnswer(
            question: question,
            selectedIndex: 1,
            isEnglish: false,
          ),
          'Đáp án đúng: **int**\nint biểu diễn số nguyên.',
        );

        await dataSource.setDemoMode(false);
        expect(
          await dataSource.explainWrongAnswer(
            question: question,
            selectedIndex: 1,
            isEnglish: true,
          ),
          'Correct answer: **int**\nint represents an integer.',
        );
      },
    );
  });
}