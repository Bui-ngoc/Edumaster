import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../../domain/entities/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  final int initialTabIndex;
  const LeaderboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProv = context.read<AuthProvider>();
      final lProv = context.read<LeaderboardProvider>();
      final pProv = context.read<ProfileProvider>();
      await authProv.refreshUser();
      await pProv.loadProfile(email: authProv.currentUser?.email);
      final effectiveGroup = (authProv.currentUser?.group.isNotEmpty ?? false)
          ? authProv.currentUser!.group
          : pProv.profile.currentGroup;
      if (effectiveGroup.isNotEmpty) {
        lProv.selectGroup(effectiveGroup);
      }
      final teacherId = (authProv.currentUser?.isTeacher ?? false)
          ? (authProv.currentUser?.id ?? authProv.currentUser?.email ?? '')
          : null;
      lProv.loadLeaderboard(teacherId: teacherId);
    });
  }

  // ── Dialog: Giáo viên tạo nhóm mới ────────────────────────────────────────
  void _showCreateGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.group_add_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Tạo nhóm học mới'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập tên nhóm học mới để sinh viên cùng tham gia và thi đua điểm EXP:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm học',
                hintText: 'Ví dụ: Nhóm 4 - Đồ án Tốt nghiệp',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final teacherId = context.read<AuthProvider>().currentUser?.id ??
                    context.read<AuthProvider>().currentUser?.email ?? '';
                await context.read<LeaderboardProvider>().createGroup(name, teacherId: teacherId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã tạo nhóm "$name" thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Tạo nhóm'),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Giáo viên đổi tên nhóm ────────────────────────────────────────
  void _showRenameGroupDialog(BuildContext context, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi tên nhóm học'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên nhóm mới',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                final teacherId = context.read<AuthProvider>().currentUser?.id ??
                    context.read<AuthProvider>().currentUser?.email ?? '';
                await context.read<LeaderboardProvider>().renameGroup(oldName, newName, teacherId: teacherId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã đổi tên nhóm thành "$newName"')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Giáo viên xóa nhóm ───────────────────────────────────────────
  void _showDeleteGroupDialog(BuildContext context, String groupName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa nhóm'),
        content: Text('Bạn có chắc muốn xóa nhóm "$groupName"? Các sinh viên trong nhóm sẽ được chuyển về nhóm còn lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final teacherId = context.read<AuthProvider>().currentUser?.id ??
                  context.read<AuthProvider>().currentUser?.email ?? '';
              await context.read<LeaderboardProvider>().deleteGroup(groupName, teacherId: teacherId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa nhóm "$groupName"')),
                );
              }
            },
            child: const Text('Xóa nhóm'),
          ),
        ],
      ),
    );
  }



  // ── Dialog: Giáo viên thêm sinh viên vào nhóm BẰNG MÃ ID / EMAIL ───────
  void _showAddStudentToGroupDialog(BuildContext context, String targetGroup) {
    final lProv = context.read<LeaderboardProvider>();
    final studentIdController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person_add_rounded, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thêm SV vào $targetGroup',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập mã ID hoặc Email của sinh viên cần thêm:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: studentIdController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Mã ID hoặc Email Sinh viên',
                    hintText: 'Ví dụ: SV1001 hoặc email sinh viên...',
                    prefixIcon: Icon(Icons.badge_rounded),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (errorMessage != null) {
                      setDialogState(() => errorMessage = null);
                    }
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(fontSize: 12, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  '💡 Lưu ý: Chỉ chấp nhận mã ID hoặc Email của tài khoản sinh viên đã đăng ký trong hệ thống.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final studentId = studentIdController.text.trim();
                      if (studentId.isEmpty) {
                        setDialogState(() => errorMessage = 'Vui lòng nhập mã ID hoặc tên sinh viên.');
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });

                      try {
                        final res = await lProv.addStudentToGroupById(
                          studentId: studentId,
                          targetGroup: targetGroup,
                        );

                        if (res.success) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ ${res.message}'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } else {
                          if (ctx.mounted) {
                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = res.message;
                            });
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
                          });
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Thêm vào nhóm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = context.select<AuthProvider, bool>((a) => a.currentUser?.isTeacher ?? false);

    final maxTabLength = isTeacher ? 2 : 2;
    final activeTabIdx = widget.initialTabIndex < maxTabLength ? widget.initialTabIndex : 0;

    return DefaultTabController(
      initialIndex: activeTabIdx,
      length: maxTabLength,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isTeacher ? 'Quản Lý Nhóm & BXH' : 'Bảng Xếp Hạng & Chuỗi Ngày'),
          bottom: TabBar(
            indicatorColor: isTeacher ? AppColors.secondary : AppColors.primary,
            indicatorWeight: 3,
            labelColor: isTeacher ? AppColors.secondary : AppColors.primary,
            unselectedLabelColor: AppColors.textSecondaryLight,
            tabs: isTeacher
                ? const [
                    Tab(icon: Icon(Icons.groups_rounded, size: 20), text: 'Quản Lý Nhóm'),
                    Tab(icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'BXH Theo Nhóm'),
                  ]
                : const [
                    Tab(icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'BXH Nhóm Học (EXP)'),
                    Tab(icon: Icon(Icons.local_fire_department_rounded, size: 20), text: 'Chuỗi & Huy Hiệu'),
                  ],
          ),
        ),
        body: TabBarView(
          children: isTeacher
              ? [
                  _buildTeacherGroupManagementTab(context),
                  _buildGroupRankingTab(context, isTeacher: true),
                ]
              : [
                  _buildGroupRankingTab(context, isTeacher: false),
                  _buildStreakAndBadgesTab(context),
                ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB DÀNH RIÊNG CHO GIÁO VIÊN: QUẢN LÝ CÁC NHÓM HỌC TẬP
  // ==========================================================================
  Widget _buildTeacherGroupManagementTab(BuildContext context) {
    final lProv = context.watch<LeaderboardProvider>();
    final authProv = context.watch<AuthProvider>();
    final teacherId = authProv.currentUser?.id ?? authProv.currentUser?.email ?? '';
    final groups = lProv.getGroupsForTeacher(teacherId);

    return RefreshIndicator(
      onRefresh: () => lProv.loadLeaderboard(force: true, teacherId: teacherId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFF00B4D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bảng Điều Khiển Nhóm Học',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tạo nhóm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.secondary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showCreateGroupDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hiện có ${groups.length} nhóm học đang thi đua theo điểm tích lũy EXP.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Danh sách các Nhóm do bạn quản lý',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (groups.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.groups_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có nhóm học nào được tạo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hãy nhấn nút "Tạo nhóm" phía trên để khởi tạo nhóm đầu tiên và thêm sinh viên vào theo Mã ID.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tạo nhóm mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showCreateGroupDialog(context),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (context, idx) {
                  final grp = groups[idx];
                  final studentCount = lProv.getGroupStudentCount(grp);
                  final avgXp = lProv.getGroupAverageXp(grp);
                  final topStudent = lProv.getGroupTopStudent(grp);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.groups_rounded, color: AppColors.secondary, size: 22),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(grp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text('$studentCount sinh viên • Trung bình: $avgXp EXP',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                onSelected: (action) {
                                  if (action == 'rename') {
                                    _showRenameGroupDialog(context, grp);
                                  } else if (action == 'delete') {
                                    _showDeleteGroupDialog(context, grp);
                                  } else if (action == 'add_student') {
                                    _showAddStudentToGroupDialog(context, grp);
                                  } else if (action == 'view_bxh') {
                                    lProv.selectGroup(grp);
                                    DefaultTabController.of(context).animateTo(1);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'view_bxh',
                                    child: Row(
                                      children: [
                                        Icon(Icons.emoji_events_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Xem BXH Nhóm này'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'add_student',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_add_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Thêm SV vào nhóm'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Đổi tên nhóm'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                        SizedBox(width: 8),
                                        Text('Xóa nhóm này', style: TextStyle(color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 16, color: Colors.amber.shade700),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  topStudent != null
                                      ? 'Thủ khoa nhóm: ${topStudent.userName} (${topStudent.xp} EXP)'
                                      : 'Chưa có sinh viên trong nhóm này',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                icon: const Icon(Icons.person_add_rounded, size: 14),
                                label: const Text('Thêm SV', style: TextStyle(fontSize: 11)),
                                onPressed: () => _showAddStudentToGroupDialog(context, grp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB XẾP HẠNG THI ĐƯA THEO NHÓM HỌC (EXP)
  // ==========================================================================
  Widget _buildGroupRankingTab(BuildContext context, {required bool isTeacher}) {
    final lProv = context.watch<LeaderboardProvider>();
    final pProv = context.watch<ProfileProvider>();
    final authProv = context.watch<AuthProvider>();
    final authUser = authProv.currentUser;
    final userProfile = pProv.profile;

    final effectiveGroup = (authUser != null && authUser.group.trim().isNotEmpty)
        ? authUser.group.trim()
        : userProfile.currentGroup.trim();

    if (!isTeacher && effectiveGroup.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_outlined, size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              const Text(
                'Bạn chưa có nhóm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vui lòng chờ Giáo viên thêm bạn vào nhóm học tập.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    final teacherId = isTeacher ? (authUser?.id ?? authUser?.email ?? '') : '';
    final availableGroups = isTeacher ? lProv.getGroupsForTeacher(teacherId) : lProv.availableGroups;
    final selectedGroup = isTeacher
        ? (lProv.selectedGroup.isNotEmpty && availableGroups.contains(lProv.selectedGroup)
            ? lProv.selectedGroup
            : (availableGroups.isNotEmpty ? availableGroups.first : ''))
        : effectiveGroup;
    final filteredList = lProv.entries.where((e) => e.groupName == selectedGroup && selectedGroup.isNotEmpty).toList()
      ..sort((a, b) => b.xp.compareTo(a.xp));

    int myRank = 0;
    LeaderboardEntry? myEntry;
    final currentUserId = authUser?.id.trim().toLowerCase() ?? '';
    final currentUserName = authUser?.name.trim().toLowerCase() ?? userProfile.name.trim().toLowerCase();
    for (int i = 0; i < filteredList.length; i++) {
      final e = filteredList[i];
      if ((currentUserId.isNotEmpty && e.id.toLowerCase() == currentUserId) ||
          e.id == userProfile.uid ||
          e.id == 'user_current' ||
          (currentUserName.isNotEmpty && e.userName.toLowerCase().contains(currentUserName))) {
        myRank = i + 1;
        myEntry = e;
        break;
      }
    }

    String diffExpMessage = '';
    if (myRank > 1 && myRank <= filteredList.length) {
      final personAbove = filteredList[myRank - 2];
      final expDiff = personAbove.xp - (myEntry?.xp ?? userProfile.totalXp);
      diffExpMessage = '⚡ Bạn chỉ còn cách hạng #${myRank - 1} (${personAbove.userName}) +$expDiff EXP!';
    } else if (myRank == 1 && filteredList.isNotEmpty) {
      diffExpMessage = '👑 Chúc mừng! Bạn đang dẫn đầu nhóm về điểm tích lũy EXP!';
    }

    return RefreshIndicator(
      onRefresh: () async {
        await authProv.refreshUser();
        await pProv.loadProfile(email: authUser?.email);
        await lProv.loadLeaderboard(force: true);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isTeacher ? AppColors.secondary.withOpacity(0.08) : AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isTeacher ? AppColors.secondary.withOpacity(0.25) : AppColors.primary.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: isTeacher ? AppColors.secondary : AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTeacher ? 'Đang xem BXH nhóm học:' : 'Nhóm học của bạn (1 SV chỉ thuộc 1 nhóm):',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedGroup.isNotEmpty ? selectedGroup : (isTeacher ? 'Chưa có nhóm nào' : 'Chưa có nhóm'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isTeacher ? AppColors.secondary : AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isTeacher)
                          const Text(
                            '🔒 Nhóm học do Giáo viên phân công cố định. Sinh viên không được phép tự chuyển nhóm.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                  if (!isTeacher)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 14, color: Colors.black54),
                          SizedBox(width: 4),
                          Text(
                            'Cố định',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (isTeacher) ...[
              if (availableGroups.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text(
                            'Chưa có dữ liệu bảng xếp hạng',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Bạn chưa tạo nhóm học nào. Hãy qua tab "Quản Lý Nhóm" để tạo nhóm đầu tiên.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableGroups.map((grp) {
                      final isSelected = selectedGroup == grp;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(grp),
                          selectedColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) => lProv.selectGroup(grp),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            if (!isTeacher)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '👥 $selectedGroup',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 28),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Thứ hạng hiện tại', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              myRank > 0 ? '#$myRank / ${filteredList.length}' : 'Chưa xếp hạng',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Tổng EXP tích lũy', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              '${userProfile.totalXp} EXP',
                              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (diffExpMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          diffExpMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 18),

            Text(
              'Bảng Dẫn Đầu EXP (${filteredList.length} Sinh viên)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (filteredList.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    selectedGroup.isNotEmpty
                        ? 'Chưa có sinh viên nào trong nhóm "$selectedGroup"'
                        : 'Chưa có dữ liệu sinh viên trong nhóm',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final entry = filteredList[index];
                  final rank = index + 1;
                  final isMe = entry.id == userProfile.uid || entry.id == 'user_current' || entry.userName.contains(userProfile.name);

                  Color? medalColor;
                  if (rank == 1) medalColor = const Color(0xFFFFD700);
                  if (rank == 2) medalColor = const Color(0xFFC0C0C0);
                  if (rank == 3) medalColor = const Color(0xFFCD7F32);

                  return Card(
                    color: isMe ? AppColors.primary.withOpacity(0.08) : null,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isMe ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                        width: 32,
                        child: medalColor != null
                            ? Icon(Icons.emoji_events_rounded, color: medalColor, size: 24)
                            : Text(
                                '$rank',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.userName,
                              style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                              child: const Text('BẠN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('🔥 ${entry.streakDays} ngày chuỗi', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${entry.xp} EXP',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB DÀNH RIÊNG CHO SINH VIÊN: CHUỖI NGÀY HỌC TẬP & HUY HIỆU CÁ NHÂN
  // ==========================================================================
  Widget _buildStreakAndBadgesTab(BuildContext context) {
    final pProv = context.watch<ProfileProvider>();
    final profile = pProv.profile;
    final streakDays = profile.streakDays;
    final totalXp = profile.totalXp;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ Hero Streak
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5722).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 12),
                Text(
                  '$streakDays Ngày Chuỗi',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Duy trì thói quen học tập hằng ngày để giữ vững chuỗi Streak!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDayDot('T2', streakDays >= 1),
                    _buildDayDot('T3', streakDays >= 2),
                    _buildDayDot('T4', streakDays >= 3),
                    _buildDayDot('T5', streakDays >= 4),
                    _buildDayDot('T6', streakDays >= 5),
                    _buildDayDot('T7', streakDays >= 6),
                    _buildDayDot('CN', streakDays >= 7),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bộ sưu tập huy hiệu
          Text('Bộ sưu tập Huy hiệu thành tích', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadgeCard('🎖️ Tân binh EduMaster', 'Hoàn thành bài đầu tiên', totalXp > 0 || profile.badges.contains('Tân binh EduMaster')),
              _buildBadgeCard('🔥 7 Ngày Chăm chỉ', 'Duy trì chuỗi 7 ngày', streakDays >= 7 || profile.badges.contains('7 Ngày Chăm chỉ')),
              _buildBadgeCard('🧠 Bậc thầy SM-2', 'Ôn tập xuất sắc Flashcards', totalXp >= 1000 || profile.badges.contains('Bậc thầy SM-2')),
              _buildBadgeCard('⚡ Thợ săn Điểm 10', 'Đạt điểm tuyệt đối bài thi', totalXp >= 1500 || profile.badges.contains('Thợ săn Điểm 10')),
              _buildBadgeCard('🌐 Chuyên gia Song ngữ', 'Hoàn thành ôn tập 2 ngôn ngữ', profile.badges.contains('Chuyên gia Song ngữ')),
              _buildBadgeCard('🏆 Chiến binh Bền bỉ', 'Duy trì chuỗi 30 ngày', streakDays >= 30 || profile.badges.contains('Chiến binh Bền bỉ')),
            ],
          ),
          const SizedBox(height: 24),

          // Các mốc thử thách
          Text('Thử thách Mốc chuỗi Streak', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMilestoneTile(title: 'Mốc 3 Ngày — Khởi động Chăm chỉ', subtitle: 'Duy trì học 3 ngày liên tục', targetDays: 3, currentDays: streakDays, color: const Color(0xFF4CAF50)),
          const SizedBox(height: 10),
          _buildMilestoneTile(title: 'Mốc 7 Ngày — Tuần lễ Bứt phá', subtitle: 'Duy trì học 7 ngày liên tục', targetDays: 7, currentDays: streakDays, color: const Color(0xFFFF9800)),
          const SizedBox(height: 10),
          _buildMilestoneTile(title: 'Mốc 14 Ngày — Chiến binh Kiên trì', subtitle: 'Duy trì học 14 ngày liên tục', targetDays: 14, currentDays: streakDays, color: const Color(0xFF2196F3)),
          const SizedBox(height: 10),
          _buildMilestoneTile(title: 'Mốc 30 Ngày — Bậc thầy Học thuật', subtitle: 'Duy trì học 30 ngày liên tục', targetDays: 30, currentDays: streakDays, color: const Color(0xFF9C27B0)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDayDot(String dayLabel, bool isDone) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: isDone ? Colors.white : Colors.white.withOpacity(0.25), shape: BoxShape.circle),
          child: Icon(isDone ? Icons.local_fire_department_rounded : Icons.check, size: 20, color: isDone ? const Color(0xFFFF5722) : Colors.white54),
        ),
        const SizedBox(height: 6),
        Text(dayLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBadgeCard(String name, String desc, bool isUnlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.secondary.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnlocked ? AppColors.secondary.withOpacity(0.4) : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: isUnlocked ? 1.0 : 0.4, child: Text(name.split(' ')[0], style: const TextStyle(fontSize: 18))),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name.substring(name.indexOf(' ') + 1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUnlocked ? AppColors.secondary : Colors.grey.shade600)),
              Text(desc, style: TextStyle(fontSize: 10, color: isUnlocked ? AppColors.textSecondaryLight : Colors.grey)),
            ],
          ),
          const SizedBox(width: 4),
          if (isUnlocked) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
        ],
      ),
    );
  }

  Widget _buildMilestoneTile({required String title, required String subtitle, required int targetDays, required int currentDays, required Color color}) {
    final isAchieved = currentDays >= targetDays;
    final progress = (currentDays / targetDays).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isAchieved ? Icons.verified_rounded : Icons.lock_clock_rounded, color: isAchieved ? color : Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isAchieved ? color : Colors.black87))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: (isAchieved ? color : Colors.grey).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(isAchieved ? '✅ Đã đạt' : '$currentDays/$targetDays ngày', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAchieved ? color : Colors.grey.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey.shade200, color: isAchieved ? color : AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
