import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/interfaces.dart';
import '../../data/datasources/gemini_ai_datasource.dart';

class ProfileProvider extends ChangeNotifier {
  final ILeaderboardRepository _repo;
  final GeminiAiDataSource _aiDataSource;
  final ImagePicker _picker = ImagePicker();

  UserProfile _profile = const UserProfile(
    uid: 'user_current',
    name: 'Sinh viên CNTT',
    email: 'student@edumaster.edu.vn',
  );

  UserProfile get profile => _profile;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool _isUpdatingAiMode = true;
  bool get isUpdatingAiMode => _isUpdatingAiMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Constructor
  ProfileProvider({
    required ILeaderboardRepository repo,
    required GeminiAiDataSource aiDataSource,
  })  : _repo = repo,
        _aiDataSource = aiDataSource {
    loadProfile();
    _loadAiMode();
  }

  Future<void> loadProfile({String? email}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _repo.getUserProfile(email: email);
    } catch (e) {
      debugPrint('Load profile error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Record daily streak
  Future<bool> checkDailyStreak({String? email}) async {
    try {
      final res = await _repo.checkAndRecordDailyStreak(email: email);
      _profile = res.profile;
      notifyListeners();
      return res.isNewStreak;
    } catch (e) {
      debugPrint('Check daily streak error: $e');
      return false;
    }
  }

  // Toggle theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Update avatar
  Future<bool> updateAvatar(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (photo != null) {
        _profile = _profile.copyWith(localAvatarPath: photo.path);
        await _repo.saveUserProfile(_profile);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Update avatar error: $e');
    }

    return false;
  }

  // Update name and group
  Future<void> updateNameAndGroup(String name, String group) async {
    _profile = _profile.copyWith(
      name: name.trim(),
      currentGroup: group.trim(),
    );

    await _repo.saveUserProfile(_profile);

    await _repo.updateUserLeaderboard(
      userId: _profile.uid,
      userName: _profile.name,
      groupName: _profile.currentGroup,
      xp: _profile.totalXp,
    );

    notifyListeners();
  }

  // Add activity XP
  Future<void> addActivityXp(int xpAmount) async {
    if (xpAmount <= 0) return;

    final newXp = _profile.totalXp + xpAmount;
    _profile = _profile.copyWith(totalXp: newXp);

    await _repo.saveUserProfile(_profile);

    await _repo.updateUserLeaderboard(
      userId: _profile.uid,
      userName: _profile.name,
      groupName: _profile.currentGroup,
      xp: _profile.totalXp,
    );

    notifyListeners();
  }

  Future<void> _loadAiMode() async {
    try {
      _isDemoMode = await _aiDataSource.isDemoMode();
    } catch (error) {
      debugPrint('Không thể đọc chế độ AI Tutor: $error');
    } finally {
      _isUpdatingAiMode = false;
      notifyListeners();
    }
  }

  Future<bool> setDemoMode(bool value) async {
    if (_isUpdatingAiMode) return false;
    _isUpdatingAiMode = true;
    notifyListeners();
    try {
      await _aiDataSource.setDemoMode(value);
      _isDemoMode = value;
      return true;
    } catch (error) {
      debugPrint('Không thể lưu chế độ AI Tutor: $error');
      return false;
    } finally {
      _isUpdatingAiMode = false;
      notifyListeners();
    }
  }
}