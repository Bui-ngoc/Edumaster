import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import 'quiz/quiz_hub_screen.dart';
import 'online_exam/exam_hub_screen.dart';
import 'dictionary/dictionary_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'ai_tutor/ai_chat_screen.dart';
import 'profile/profile_screen.dart';
import 'teacher/teacher_exam_history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().currentUser;
      final profProv = context.read<ProfileProvider>();
      await profProv.loadProfile(email: user?.email);
      if (!mounted || user?.isTeacher != false) return;  // vừa thêm
      final isNewStreak = await profProv.checkDailyStreak(email: user?.email);
      if (isNewStreak && mounted) {
        final streak = profProv.profile.streakDays;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🔥 Khởi động học tập: Bạn đã đạt Chuỗi Ngày $streak hôm nay!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Select ONLY isTeacher to prevent rebuilds on other auth state changes
    final isTeacher = context.select<AuthProvider, bool>(
      (a) => a.currentUser?.isTeacher ?? false,
    );
    final profile = context.watch<ProfileProvider>().profile;

    final hasAvatar = profile.localAvatarPath != null &&
        profile.localAvatarPath!.isNotEmpty &&
        File(profile.localAvatarPath!).existsSync();

    final List<Widget> screens = isTeacher
        ? const [
            ExamHubScreen(),
            TeacherExamHistoryScreen(),
            LeaderboardScreen(),
          ]
        : const [
            QuizHubScreen(),
            ExamHubScreen(),
            DictionaryScreen(),
            LeaderboardScreen(),
          ];

    final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

    final List<NavigationDestination> destinations = isTeacher
        ? const [
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.secondary),
              label: 'Tạo phòng thi',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_edu_outlined),
              selectedIcon: Icon(Icons.history_edu_rounded, color: AppColors.secondary),
              label: 'Lịch sử phòng thi',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded, color: AppColors.secondary),
              label: 'Quản lý Nhóm',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded, color: AppColors.primary),
              label: 'Trắc nghiệm',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer_rounded, color: AppColors.primary),
              label: 'Phòng thi',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book_rounded, color: AppColors.primary),
              label: 'Từ điển IT',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded, color: AppColors.primary),
              label: 'BXH Nhóm',
            ),
          ];

    return Scaffold(
      backgroundColor: isTeacher ? const Color(0xFFFBFBFB) : Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isTeacher ? AppColors.secondary : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTeacher ? Icons.supervisor_account_rounded : Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EduMaster',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  isTeacher ? 'Chế độ Giảng viên' : 'Chế độ Sinh viên',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isTeacher ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // AI Tutor shortcut
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.accent),
            tooltip: 'Gia sư AI 24/7',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiChatScreen()),
              );
            },
          ),
          // Profile & Avatar shortcut
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: (isTeacher ? AppColors.secondary : AppColors.primary).withOpacity(0.15),
                backgroundImage: hasAvatar ? FileImage(File(profile.localAvatarPath!)) : null,
                child: !hasAvatar
                    ? Icon(
                        isTeacher ? Icons.supervisor_account_rounded : Icons.person,
                        size: 18,
                        color: isTeacher ? AppColors.secondary : AppColors.primary,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: destinations,
      ),
    );
  }
}
