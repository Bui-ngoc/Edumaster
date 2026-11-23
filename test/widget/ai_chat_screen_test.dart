
import 'package:edumaster/data/datasources/gemini_ai_datasource.dart';
import 'package:edumaster/data/repositories/ai_tutor_repository_impl.dart';
import 'package:edumaster/domain/entities/leaderboard_entry.dart';
import 'package:edumaster/domain/repositories/interfaces.dart';
import 'package:edumaster/presentation/providers/ai_tutor_provider.dart';
import 'package:edumaster/presentation/providers/profile_provider.dart';
import 'package:edumaster/presentation/screens/ai_tutor/ai_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ProfileRepository extends Fake implements ILeaderboardRepository {
  @override
  Future<UserProfile> getUserProfile({String? email}) async {
    return const UserProfile(
      uid: 'student',
      name: 'Sinh viên',
      email: 'student@example.com',
    );
  }
}

void main() {
  testWidgets('AI Tutor đọc chế độ đã lưu, trả lời offline và đổi chế độ', (
      tester,
      ) async {
    SharedPreferences.setMockInitialValues({'edumaster_demo_mode': true});
    final dataSource = GeminiAiDataSource();
    final aiRepo = AiTutorRepositoryImpl(dataSource: dataSource);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AiTutorProvider(aiRepo: aiRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => ProfileProvider(
              repo: _ProfileRepository(),
              aiDataSource: dataSource,
            ),
          ),
        ],
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ngoại tuyến • AI Cục bộ'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2 + 2');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('2 + 2 = 4', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Đang ở chế độ Offline (Bấm để đổi)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Trực tuyến • Gemini AI'), findsOneWidget);
    expect(await dataSource.isDemoMode(), isFalse);
  });
}