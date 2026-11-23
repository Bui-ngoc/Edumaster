import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/ai_tutor_provider.dart';
import '../../providers/profile_provider.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialPrompt;
  const AiChatScreen({super.key, this.initialPrompt});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _textController.text = widget.initialPrompt!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final aiProv = context.read<AiTutorProvider>();
    if (aiProv.isGenerating || context.read<ProfileProvider>().isUpdatingAiMode) {
      return;
    }

    final text = quickText ?? _textController.text;

    if (text.trim().isEmpty) return;

    if (quickText == null) _textController.clear();

    final response = aiProv.sendMessage(text);
    _scrollToBottom();
    await response;
    if (mounted) _scrollToBottom();
  }

  Future<void> _toggleAiMode() async {
    final prof = context.read<ProfileProvider>();
    final newDemoMode = !prof.isDemoMode;
    final saved = await prof.setDemoMode(newDemoMode);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          switch ((saved, newDemoMode)) {
            (false, _) => 'Không thể lưu chế độ AI Tutor. Hãy thử lại.',
            (true, true) => '📴 Ngoại tuyến: Giải đáp môn học trên thiết bị.',
            (true, false) => '🌐 Trực tuyến: Kết nối Gemini qua máy chủ Edumaster.',
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProv = context.watch<AiTutorProvider>();
    final prof = context.watch<ProfileProvider>();
    final isOnline = !prof.isDemoMode;
    final isBusy = aiProv.isGenerating || prof.isUpdatingAiMode;
    final messages = aiProv.messages;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 20),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : const Color(0xFFFF9800),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('AI Tutor 24/7', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(
                    isOnline
                        ? 'Trực tuyến • Gemini AI (Đa lĩnh vực)'
                        : 'Ngoại tuyến • AI Cục bộ (Giới hạn môn học)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOnline ? AppColors.success : const Color(0xFFFF9800),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isOnline ? Icons.cloud_done_rounded : Icons.offline_bolt_rounded,
              color: isOnline ? AppColors.success : AppColors.primary,
            ),
            tooltip: isOnline ? 'Đang ở chế độ Online (Bấm để đổi)' : 'Đang ở chế độ Offline (Bấm để đổi)',
            onPressed: isBusy ? null : _toggleAiMode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới hội thoại',
            onPressed: aiProv.isGenerating
                ? null
                : () => aiProv.clearHistory(),
          )
        ],
      ),
      body: Column(
        children: [
          // Dynamic Quick suggestions chips (Shows all available offline topics when Offline)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: isOnline
                  ? [
                      _buildQuickChip('📱 Flutter là gì?'),
                      _buildQuickChip('🎯 Ngôn ngữ Dart là gì?'),
                      _buildQuickChip('⚡ Phân biệt List và Tuple'),
                      _buildQuickChip('🧠 Thuật toán SM-2 là gì?'),
                      _buildQuickChip('🔍 So sánh final và const'),
                      _buildQuickChip('🏛️ Clean Architecture trong Flutter'),
                      _buildQuickChip('📊 Tính điểm thi: đúng 16/20 câu'),
                    ]
                  : [
                      _buildQuickChip('📱 Flutter là gì?'),
                      _buildQuickChip('🎯 Ngôn ngữ Dart là gì?'),
                      _buildQuickChip('🏛️ Clean Architecture trong Flutter'),
                      _buildQuickChip('⚡ Phân biệt List và Tuple'),
                      _buildQuickChip('🧠 Thuật toán SM-2 là gì?'),
                      _buildQuickChip('🔒 So sánh final và const'),
                      _buildQuickChip('⚖️ StatelessWidget vs StatefulWidget'),
                      _buildQuickChip('💾 SQLite FTS là gì?'),
                      _buildQuickChip('🔄 SQL vs NoSQL'),
                      _buildQuickChip('📡 Future vs Stream'),
                      _buildQuickChip('⚡ Async Await trong Dart'),
                      _buildQuickChip('📊 Tính điểm thi: đúng 16/20 câu'),
                    ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0x1F000000)),

          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),

          // Generating Indicator
          if (aiProv.isGenerating)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI Tutor đang soạn phản hồi...',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Modern Floating Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              enabled: !isBusy,
                              controller: _textController,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              decoration: const InputDecoration(
                                hintText: 'Nhập tin nhắn cho AI Tutor...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: isBusy ? null : () => _sendMessage(),
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: isBusy ? Colors.grey : AppColors.primary,
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        backgroundColor: AppColors.primary.withOpacity(0.08),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        onPressed: context.read<AiTutorProvider>().isGenerating ||
                context.read<ProfileProvider>().isUpdatingAiMode
            ? null
            : () => _sendMessage(
          label.replaceAll(RegExp(r'^[^\w\s]+\s*'), ''),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.smart_toy_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text(
                      'AI Tutor',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msg.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép câu trả lời!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            _buildFormattedMessageText(msg.text, isMe),
          ],
        ),
      ),
    );
  }

  /// Hiển thị câu trả lời AI đẹp mắt, phân giải **thành chữ in đậm** và KHÔNG BAO GIỜ hiển thị ký tự **
  Widget _buildFormattedMessageText(String rawText, bool isMe) {
    if (isMe) {
      return SelectableText(
        rawText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    final baseStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 14,
      height: 1.45,
    );
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: const Color(0xFF111827),
    );

    // Làm sạch và chuyển đổi **thành phần in đậm**
    final cleanedText = rawText.replaceAll(RegExp(r'^\s*\*\*\s*$', multiLine: true), '');
    final List<TextSpan> spans = [];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(cleanedText)) {
      if (match.start > lastMatchEnd) {
        final regularPart = cleanedText.substring(lastMatchEnd, match.start).replaceAll('**', '');
        if (regularPart.isNotEmpty) {
          spans.add(TextSpan(text: regularPart, style: baseStyle));
        }
      }
      final boldContent = (match.group(1) ?? '').replaceAll('**', '');
      if (boldContent.isNotEmpty) {
        spans.add(TextSpan(text: boldContent, style: boldStyle));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < cleanedText.length) {
      final trailing = cleanedText.substring(lastMatchEnd).replaceAll('**', '');
      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing, style: baseStyle));
      }
    }

    return SelectableText.rich(
      TextSpan(
        children: spans.isEmpty
            ? [TextSpan(text: cleanedText.replaceAll('**', ''), style: baseStyle)]
            : spans,
      ),
    );
  }
}
