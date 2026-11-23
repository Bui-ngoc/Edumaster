
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Core
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';

// DataSources
import 'data/datasources/quiz_local_datasource.dart';
import 'data/datasources/exam_storage_datasource.dart';
import 'data/datasources/dictionary_sqlite_datasource.dart';
import 'data/datasources/leaderboard_datasource.dart';
import 'data/datasources/gemini_ai_datasource.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/app_database.dart';

// Repositories
import 'data/repositories/quiz_repository_impl.dart';
import 'data/repositories/exam_repository_impl.dart';
import 'data/repositories/dictionary_repository_impl.dart';
import 'data/repositories/leaderboard_repository_impl.dart';
import 'data/repositories/ai_tutor_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';

// Providers
import 'presentation/providers/quiz_provider.dart';
import 'presentation/providers/exam_provider.dart';
import 'presentation/providers/dictionary_provider.dart';
import 'presentation/providers/leaderboard_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/ai_tutor_provider.dart';
import 'presentation/providers/auth_provider.dart';

// Screens
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';


// ==========================================
// XÓA DỮ LIỆU CŨ TRONG LẦN CHẠY ĐẦU TIÊN
// ==========================================

Future<void> _clearAllDataOnFirstRun() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    const cleanFlagKey = 'edumaster_fresh_clean_v12';

    if (!(prefs.getBool(cleanFlagKey) ?? false)) {
      final keys = prefs.getKeys().toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      await prefs.setBool(cleanFlagKey, true);

      try {
        await AppDatabase.instance.clearAllTables();
      } catch (e) {
        debugPrint('Clear database error: $e');
      }
    }
  } catch (e) {
    debugPrint('Clear preferences error: $e');
  }
}


// ==========================================
// MAIN
// ==========================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Khởi tạo SQLite
  try {
    await AppDatabase.instance.database;
    debugPrint('SQLite initialized successfully');
  } catch (e) {
    debugPrint('SQLite initialization error: $e');
  }

  // 4. Xóa dữ liệu cũ trong lần chạy đầu tiên
  await _clearAllDataOnFirstRun();

  // ==========================================
  // 5. KHỞI TẠO DATASOURCES
  // ==========================================

  final quizLocalDataSource = QuizLocalDataSource();

  final examStorageDataSource = ExamStorageDataSource();

  final dictionarySqliteDataSource =
  DictionarySqliteDataSource();

  final leaderboardDataSource = LeaderboardDataSource();

  final geminiAiDataSource = GeminiAiDataSource();

  final authLocalDataSource = AuthLocalDataSource(
    leaderboardDataSource: leaderboardDataSource,
  );

  // ==========================================
  // 6. KHỞI TẠO REPOSITORIES
  // ==========================================

  final quizRepository = QuizRepositoryImpl(
    dataSource: quizLocalDataSource,
  );

  final examRepository = ExamRepositoryImpl(
    dataSource: examStorageDataSource,
  );

  final dictionaryRepository = DictionaryRepositoryImpl(
    dataSource: dictionarySqliteDataSource,
  );

  final leaderboardRepository = LeaderboardRepositoryImpl(
    dataSource: leaderboardDataSource,
  );

  final aiTutorRepository = AiTutorRepositoryImpl(
    dataSource: geminiAiDataSource,
  );

  final authRepository = AuthRepositoryImpl(
    dataSource: authLocalDataSource,
  );

  // ==========================================
  // 7. KHỞI CHẠY ỨNG DỤNG
  // ==========================================


  runApp(
    MultiProvider(
      providers: [
        // AUTH PROVIDER
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepo: authRepository,
            quizDataSource: quizLocalDataSource,
            examDataSource: examStorageDataSource,
          ),
        ),

        // QUIZ PROVIDER
        ChangeNotifierProvider(
          create: (_) => QuizProvider(
            aiRepo: aiTutorRepository,
            quizRepo: quizRepository,
          ),
        ),

        // EXAM PROVIDER
        ChangeNotifierProvider(
          create: (_) => ExamProvider(
            examRepo: examRepository,
            leaderboardRepo: leaderboardRepository,
          ),
        ),

        // DICTIONARY PROVIDER
        ChangeNotifierProvider(
          create: (_) => DictionaryProvider(
            repo: dictionaryRepository,
          ),
        ),

        // LEADERBOARD PROVIDER
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider(
            repo: leaderboardRepository,
          ),
        ),

        // PROFILE PROVIDER
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            repo: leaderboardRepository,
            aiDataSource: geminiAiDataSource,
          ),
        ),

        // AI TUTOR PROVIDER
        ChangeNotifierProvider(
          create: (_) => AiTutorProvider(
            aiRepo: aiTutorRepository,
          ),
        ),
      ],
      child: const EduMasterApp(),
    ),
  );

}


// ==========================================
// EDUMASTER APP
// ==========================================

class EduMasterApp extends StatelessWidget {
  const EduMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<ProfileProvider, bool>(
          (provider) => provider.isDarkMode,
    );

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      builder: (context, child) {
        final mq = MediaQuery.of(context);

        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },

      home: const AuthWrapper(),
    );
  }
}


// ==========================================
// AUTH WRAPPER
// ==========================================

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();

    if (authProv.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (authProv.isLoggedIn) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
