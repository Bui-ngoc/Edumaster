import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/profile_provider.dart';
import '../ai_tutor/ai_chat_screen.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _showReviewDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProv = context.read<QuizProvider>();
      final profileProv = context.read<ProfileProvider>();
      final earnedXp = (quizProv.score * 15) + 30;
      context.read<LeaderboardProvider>();
      profileProv.loadProfile();
      profileProv.updateNameAndGroup(
        profileProv.profile.name,
        profileProv.profile.currentGroup,
      );
      if (earnedXp > 0) {
        profileProv.addActivityXp(earnedXp);
      }
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m phút ${s.toString().padLeft(2, '0')} giây';
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<QuizProvider>();
    final total = prov.activeQuestions.length;
    final score = prov.score;
    final percentage = total > 0 ? (score / total) * 100 : 0.0;
    final isPassed = percentage >= 50.0;
    final isExam = prov.currentMode == QuizMode.exam;

    return Scaffold(
      appBar: AppBar(
        title: Text(isExam ? 'Kết quả Kỳ thi thử' : 'Kết quả luyện tập'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Score badge
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: isPassed ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPassed ? AppColors.success : AppColors.error,
                    width: 3.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score/$total',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isPassed ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isPassed ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isPassed ? '🎉 Chúc mừng bạn đã vượt qua bài thi!' : '💪 Đừng nản lòng, hãy tiếp tục cố gắng nhé!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn nhận được +${(score * 15) + 30} XP vào Bảng xếp hạng học tập!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              // Summary Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatRow('Chế độ', isExam ? 'Thi thử tính giờ' : 'Luyện tập tự do'),
                      const Divider(),
                      _buildStatRow('Số câu đúng', '$score / $total câu', color: AppColors.success),
                      const Divider(),
                      _buildStatRow('Số câu sai / bỏ qua', '${total - score} câu', color: AppColors.error),
                      const Divider(),
                      _buildStatRow('Tỉ lệ chính xác', '${percentage.toStringAsFixed(1)}%'),
                      if (isExam) ...[
                        const Divider(),
                        _buildStatRow(
                          'Thời gian làm bài',
                          '${_formatDuration(prov.timeSpentSeconds)} / ${prov.examDurationMinutes} phút',
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Toggle Detailed Review
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(_showReviewDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                  label: Text(
                    _showReviewDetails ? 'Thu gọn đáp án chi tiết' : 'Xem lại đáp án chi tiết từng câu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    setState(() => _showReviewDetails = !_showReviewDetails);
                  },
                ),
              ),

              // Question-by-question review section
              if (_showReviewDetails) ...[
                const SizedBox(height: 14),
                ...List.generate(prov.activeQuestions.length, (idx) {
                  final q = prov.activeQuestions[idx];
                  final chosen = prov.userAnswers[idx];
                  final isCorrect = chosen == q.correctIndex;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isCorrect ? AppColors.success : AppColors.error,
                                child: Icon(
                                  isCorrect ? Icons.check : Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Câu ${idx + 1}: ${q.category}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prov.isEnglish ? q.questionEn : q.questionVi,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bạn chọn: ${chosen != null ? "${String.fromCharCode(65 + chosen)}. ${(prov.isEnglish ? q.optionsEn : q.optionsVi)[chosen]}" : "(Chưa chọn)"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCorrect ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!isCorrect) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Đáp án đúng: ${String.fromCharCode(65 + q.correctIndex)}. ${(prov.isEnglish ? q.optionsEn : q.optionsVi)[q.correctIndex]}',
                              style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💡 Lời giải: ${prov.isEnglish ? q.explanationEn : q.explanationVi}',
                                  style: const TextStyle(fontSize: 12, height: 1.4),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                    icon: const Icon(Icons.smart_toy_rounded, size: 16),
                                    label: const Text('Hỏi AI Tutor', style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      final prompt = prov.isEnglish
                                          ? 'Question: ${q.questionEn}\n'
                                          'Correct answer: ${q.optionsEn[q.correctIndex]}\n'
                                          'Reference: ${q.explanationEn}\n'
                                          'Please explain the correct answer in English.'
                                          : 'Câu hỏi: ${q.questionVi}\n'
                                          'Đáp án đúng: ${q.optionsVi[q.correctIndex]}\n'
                                          'Tham khảo: ${q.explanationVi}\n'
                                          'Hãy giải thích đáp án đúng bằng tiếng Việt.';
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AiChatScreen(
                                            initialPrompt: prompt,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 18),

              // Action Buttons
              if (total - score > 0) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () {
                      prov.loadQuestions(mode: QuizMode.wrongReview);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.replay_circle_filled_rounded),
                    label: const Text('Luyện lại ngay các câu làm sai'),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Quay về Menu Ôn tập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}