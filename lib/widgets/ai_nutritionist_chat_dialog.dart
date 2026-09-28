import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../screens/ai_chat_history_screen.dart';
import '../theme.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import 'app_ui_components.dart';

class AiNutritionistChatDialog extends StatefulWidget {
  const AiNutritionistChatDialog({super.key});

  static void show(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => const AiNutritionistChatDialog(),
    );
  }

  @override
  State<AiNutritionistChatDialog> createState() =>
      _AiNutritionistChatDialogState();
}

class _AiNutritionistChatDialogState extends State<AiNutritionistChatDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];

  bool _isSending = false;
  Map<String, dynamic> _todayStats = {};
  UserProfile? _userProfile;

  List<String> get _quickSuggestions => LocaleService.isVietnamese
      ? [
          '🍗 Gợi ý bữa phụ giàu protein',
          '🏃 Nên ăn gì sau buổi tập?',
          '🥗 Đánh giá dinh dưỡng hôm nay',
          '💧 Kiểm tra lượng nước đã uống',
        ]
      : [
          '🍗 High protein snack ideas',
          '🏃 What to eat post-workout?',
          '🥗 Review today nutrition',
          '💧 Check water intake',
        ];

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'role': 'model',
        'text': LocaleService.isVietnamese
            ? 'Xin chào! Tôi là Gemini Nutritionist 🥗. Tôi có thể phân tích thực đơn hôm nay, đối chiếu với chỉ số cơ thể và mục tiêu của bạn để đưa ra lời khuyên dinh dưỡng chuẩn khoa học. Hãy hỏi tôi bất cứ điều gì!'
            : 'Hello! I am Gemini Nutritionist 🥗. I can analyze your meals against your biometric goals and advise on personalized nutrition. Ask me anything!',
      },
    ];
    _loadStats();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final history = await StorageService.getLocalChatHistory(limit: 50);
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages = history.map((m) => {'role': m.role, 'text': m.text}).toList();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final profile = await StorageService.getUserProfile();
    final calIn = await StorageService.getTodayTotalCaloriesIn();
    final macros = await StorageService.getTodayTotalMacros();
    final water = await StorageService.getTodayWaterVolume();
    final goal = await StorageService.getNutritionGoal();
    final foods = await StorageService.getTodayFoodLogs();
    final calBurned = await StorageService.calculateRealTimeCaloriesBurned(currentSteps: 0);

    final foodNames = foods.map((f) => '${f.name} (${f.calories} kcal)').join(', ');

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _todayStats = {
          'caloriesIn': calIn,
          'caloriesBurned': calBurned,
          'protein': macros['protein'] ?? 0,
          'carbs': macros['carbs'] ?? 0,
          'fat': macros['fat'] ?? 0,
          'waterMl': water,
          'goal': goal,
          'foodsSummary': foodNames.isEmpty ? 'Chưa ghi nhận món ăn' : foodNames,
        };
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isSending) return;

    final userMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_u',
      role: 'user',
      text: query,
      timestamp: DateTime.now(),
    );
    unawaited(StorageService.saveChatMessage(userMsg));

    _messageController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _messages.add({'role': 'model', 'text': ''});
      _isSending = true;
    });

    _scrollToBottom();

    final modelIndex = _messages.length - 1;
    String accumulatedText = '';

    try {
      final historyForAi = _messages.sublist(0, modelIndex);
      await for (final chunk in GeminiService.chatWithNutritionistStream(
        message: query,
        todayStats: _todayStats,
        history: historyForAi,
        userProfile: _userProfile,
      )) {
        accumulatedText += chunk;
        if (mounted) {
          setState(() {
            _messages[modelIndex]['text'] = accumulatedText;
          });
          _scrollToBottom();
        }
      }

      if (accumulatedText.isNotEmpty) {
        final modelMsg = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_m',
          role: 'model',
          text: accumulatedText,
          timestamp: DateTime.now(),
        );
        unawaited(StorageService.saveChatMessage(modelMsg));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[modelIndex]['text'] = 'Lỗi kết nối với AI: $e. Vui lòng thử lại!';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF141418),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const BottomSheetDragHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Color(0xFF00F0FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini Nutritionist',
                          style: AppTheme.font(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          LocaleService.tr('ai_chat_advisor_title'),
                          style: AppTheme.font(
                            fontSize: 11,
                            color: const Color(0xFF00F0FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: Color(0xFF00F0FF)),
                      tooltip: LocaleService.tr('chat_history_title'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiChatHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: Colors.white10),

          // Quick Suggestion Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickSuggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = _quickSuggestions[index];
                return BouncingTap(
                  hapticType: AppHapticFeedbackType.light,
                  onTap: _isSending ? null : () => _sendMessage(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      suggestion,
                      style: AppTheme.font(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                          : const Color(0xFF1F1F26),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isUser
                            ? const Color(0xFF00F0FF).withValues(alpha: 0.4)
                            : Colors.white12,
                      ),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: AppTheme.font(
                        fontSize: 13,
                        height: 1.4,
                        color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Thinking Indicator
          if (_isSending && (_messages.isEmpty || (_messages.last['text']?.isEmpty ?? true)))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00F0FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    LocaleService.tr('gemini_thinking_stats'),
                    style: AppTheme.font(
                      fontSize: 12,
                      color: const Color(0xFF00F0FF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Input Row
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A22),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: LocaleService.tr('ask_gemini_hint'),
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF24242E),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _sendMessage(val),
                  ),
                ),
                const SizedBox(width: 10),
                BouncingTap(
                  hapticType: AppHapticFeedbackType.medium,
                  onTap: _isSending
                      ? null
                      : () => _sendMessage(_messageController.text),
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
