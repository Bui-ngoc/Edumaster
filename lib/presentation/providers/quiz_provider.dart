import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/interfaces.dart';

enum QuizMode { practice, exam, wrongReview }
enum QuizUiState { initial, loading, success, error, empty }

class QuizProvider extends ChangeNotifier {
  final IQuizRepository _quizRepo;
  final IAiTutorRepository _aiRepo;

  QuizProvider({
    required IQuizRepository quizRepo,
    required IAiTutorRepository aiRepo,
  })  : _quizRepo = quizRepo,
        _aiRepo = aiRepo;

  QuizUiState _state = QuizUiState.initial;
  QuizUiState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  List<QuizQuestion> _allQuestions = [];
  List<QuizQuestion> get allQuestions => _allQuestions;
  List<QuizQuestion> _activeQuestions = [];
  List<QuizQuestion> get activeQuestions => _activeQuestions;

  int _selectedGrade = 0;
  int get selectedGrade => _selectedGrade;

  String _selectedDifficulty = 'all';
  String get selectedDifficulty => _selectedDifficulty;

  int _examDurationMinutes = 60;
  int get examDurationMinutes => _examDurationMinutes;

  int _examQuestionCount = 50;
  int get examQuestionCount => _examQuestionCount;

  QuizMode _currentMode = QuizMode.practice;
  QuizMode get currentMode => _currentMode;

  bool _isEnglish = false;
  bool get isEnglish => _isEnglish;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final Map<int, int> _userAnswers = {};
  Map<int, int> get userAnswers => _userAnswers;

  int _score = 0;
  int get score => _score;

  int _timeSpentSeconds = 0;
  int get timeSpentSeconds => _timeSpentSeconds;

  // ── Timer: ValueNotifier so ONLY the timer widget rebuilds each tick ──────
  Timer? _countdownTimer;
  final ValueNotifier<int> timerNotifier = ValueNotifier(0);
  bool _isTimeUp = false;
  bool get isTimeUp => _isTimeUp;

  // Keep secondsRemaining as a getter from timerNotifier for backward compat
  int get secondsRemaining => timerNotifier.value;

  // AI explanation state
  bool _isExplaining = false;
  bool get isExplaining => _isExplaining;
  String _aiExplanation = '';
  String get aiExplanation => _aiExplanation;

  /// Reset toàn bộ trạng thái quiz khi đổi user, để wrong-questions không bị lẫn
  void resetState() {
    _state = QuizUiState.initial;
    _allQuestions = [];
    _activeQuestions = [];
    _userAnswers.clear();
    _score = 0;
    _currentIndex = 0;
    _errorMessage = '';
    _aiExplanation = '';
    notifyListeners();
  }

  Future<void> loadQuestions({
    int grade = 0,
    QuizMode mode = QuizMode.practice,
    bool force = false,
  }) async {
    if (!force &&
        mode == QuizMode.practice &&
        grade == 0 &&
        _allQuestions.isNotEmpty &&
        _state == QuizUiState.success) {
      return;
    }
    _state = QuizUiState.loading;
    _errorMessage = '';
    _selectedGrade = grade;
    _currentMode = mode;
    _currentIndex = 0;
    _userAnswers.clear();
    _score = 0;
    _isTimeUp = false;
    _aiExplanation = '';
    _timeSpentSeconds = 0;
    notifyListeners();

    try {
      if (mode == QuizMode.wrongReview) {
        _activeQuestions = await _quizRepo.getWrongQuestions();
      } else if (grade > 0) {
        _activeQuestions = await _quizRepo.getQuestionsByGrade(grade);
      } else {
        _allQuestions = await _quizRepo.getAllQuestions();
        _activeQuestions = List.from(_allQuestions);
      }

      if (_activeQuestions.isEmpty) {
        _state = QuizUiState.empty;
      } else {
        if (mode == QuizMode.exam) {
          await startTimedExam(
            grade: grade,
            difficulty: 'all',
            questionCount: 50,
            durationMinutes: 60,
          );
          return;
        }
        _state = QuizUiState.success;
      }
    } catch (e) {
      _state = QuizUiState.error;
      _errorMessage = 'Không thể nạp danh sách câu hỏi: ${e.toString()}';
    }
    notifyListeners();
  }

  Future<void> startTimedExam({
    int grade = 0,
    String difficulty = 'all',
    int questionCount = 50,
    int durationMinutes = 60,
  }) async {
    _state = QuizUiState.loading;
    _errorMessage = '';
    _selectedGrade = grade;
    _selectedDifficulty = difficulty;
    _examQuestionCount = questionCount;
    _examDurationMinutes = durationMinutes;
    _currentMode = QuizMode.exam;
    _currentIndex = 0;
    _userAnswers.clear();
    _score = 0;
    _isTimeUp = false;
    _aiExplanation = '';
    _timeSpentSeconds = 0;
    notifyListeners();

    try {
      _allQuestions = await _quizRepo.getAllQuestions();
      List<QuizQuestion> pool = List.from(_allQuestions);

      if (grade > 0) {
        pool = pool.where((q) => q.grade == grade).toList();
      }
      if (difficulty == 'easy') {
        pool = pool.where(_isEasyQuestion).toList();
      } else if (difficulty == 'medium') {
        pool = pool.where(_isMediumQuestion).toList();
      } else if (difficulty == 'hard') {
        pool = pool.where(_isHardQuestion).toList();
      }

      if (pool.isEmpty) pool = List.from(_allQuestions);
      pool.shuffle();

      final actualCount = pool.length < questionCount ? pool.length : questionCount;
      _activeQuestions = pool.sublist(0, actualCount);

      if (_activeQuestions.isEmpty) {
        _state = QuizUiState.empty;
      } else {
        _startTimer(durationMinutes * 60);
        _state = QuizUiState.success;
      }
    } catch (e) {
      _state = QuizUiState.error;
      _errorMessage = 'Lỗi tạo đề thi thử: ${e.toString()}';
    }
    notifyListeners();
  }

  bool _isEasyQuestion(QuizQuestion q) {
    if (q.grade <= 5) return true;
    final text = q.questionVi.toLowerCase();
    return text.contains('là gì') ||
        text.contains('khái niệm') ||
        text.contains('đặc điểm') ||
        text.contains('cú pháp') ||
        text.contains('kiểu dữ liệu');
  }

  bool _isMediumQuestion(QuizQuestion q) {
    if (q.grade >= 6 && q.grade <= 12) return true;
    final text = q.questionVi.toLowerCase();
    return text.contains('sử dụng') ||
        text.contains('hoạt ảnh') ||
        text.contains('điều hướng') ||
        text.contains('trạng thái') ||
        text.contains('form');
  }

  bool _isHardQuestion(QuizQuestion q) {
    if (q.grade >= 13) return true;
    final text = q.questionVi.toLowerCase();
    return text.contains('kiến trúc') ||
        text.contains('clean') ||
        text.contains('hiệu năng') ||
        text.contains('tối ưu') ||
        text.contains('kiểm thử') ||
        text.contains('thuật toán') ||
        text.contains('sqlite') ||
        text.contains('stream') ||
        text.contains('ai');
  }

  // ── Timer: tick only updates ValueNotifier, NOT notifyListeners ──────────
  void _startTimer(int totalSeconds) {
    _countdownTimer?.cancel();
    timerNotifier.value = totalSeconds;
    _isTimeUp = false;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerNotifier.value > 0) {
        timerNotifier.value--;
        // Do NOT call notifyListeners() here — only timer widget rebuilds
      } else {
        _isTimeUp = true;
        timer.cancel();
        calculateScore();
        notifyListeners(); // Only on timeout — triggers isTimeUp UI
      }
    });
  }

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    _aiExplanation = '';
    notifyListeners();
  }

  void selectAnswer(int optionIndex) {
    if (_isTimeUp) return;
    _userAnswers[_currentIndex] = optionIndex;
    _aiExplanation = '';

    if (_currentMode != QuizMode.exam) {
      final question = _activeQuestions[_currentIndex];
      if (optionIndex == question.correctIndex) {
        _quizRepo.removeWrongQuestionId(question.id);
      } else {
        _quizRepo.saveWrongQuestionId(question.id);
      }
    }
    notifyListeners();
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < _activeQuestions.length) {
      _currentIndex = index;
      _aiExplanation = '';
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentIndex < _activeQuestions.length - 1) {
      _currentIndex++;
      _aiExplanation = '';
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _aiExplanation = '';
      notifyListeners();
    }
  }

  void calculateScore() {
    _countdownTimer?.cancel();
    int count = 0;
    for (int i = 0; i < _activeQuestions.length; i++) {
      final question = _activeQuestions[i];
      if (_userAnswers[i] == question.correctIndex) {
        count++;
        _quizRepo.removeWrongQuestionId(question.id);
      } else {
        _quizRepo.saveWrongQuestionId(question.id);
      }
    }
    _score = count;
    _timeSpentSeconds = (_examDurationMinutes * 60) - timerNotifier.value;
    if (_timeSpentSeconds < 0) _timeSpentSeconds = 0;
    notifyListeners();
  }

  Future<void> requestAiExplanation() async {
    final index = _currentIndex;
    final chosen = _userAnswers[index];
    if (_isExplaining || chosen == null || index >= _activeQuestions.length) {
      return;
    }
    final question = _activeQuestions[index];
    final isEnglish = _isEnglish;

    _isExplaining = true;
    _aiExplanation = '';
    notifyListeners();

    String explanation;
    try {
      explanation = await _aiRepo.explainWrongAnswer(
        question: question,
        selectedIndex: chosen,
        isEnglish: isEnglish,
      );
    } catch (_) {
      explanation = isEnglish
          ? '💡 Reference explanation: ${question.explanationEn}'
          : '💡 Lời giải tham khảo: ${question.explanationVi}';
    }

    if (_currentIndex == index &&
        index < _activeQuestions.length &&
        identical(_activeQuestions[index], question) &&
        _userAnswers[index] == chosen &&
        _isEnglish == isEnglish) {
      _aiExplanation = explanation;
    }
    _isExplaining = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    timerNotifier.dispose();
    super.dispose();
  }
}