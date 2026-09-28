import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/chat_message.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/ai_nutritionist_chat_dialog.dart';

class AiChatHistoryScreen extends StatefulWidget {
  const AiChatHistoryScreen({super.key});

  @override
  State<AiChatHistoryScreen> createState() => _AiChatHistoryScreenState();
}

class _AiChatHistoryScreenState extends State<AiChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatMessage> _allMessages = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all' | 'user' | 'model'

  @override
  void initState() {
    super.initState();
    _loadMessages();
    StorageService.chatUpdateNotifier.addListener(_loadMessages);
  }

  @override
  void dispose() {
    StorageService.chatUpdateNotifier.removeListener(_loadMessages);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final list = await StorageService.getLocalChatHistory(limit: 300);
    if (mounted) {
      setState(() {
        _allMessages = list;
        _isLoading = false;
      });
    }
  }

  List<ChatMessage> get _filteredMessages {
    final query = _searchController.text.trim().toLowerCase();
    return _allMessages.where((msg) {
      if (_selectedFilter == 'user' && !msg.isUser) return false;
      if (_selectedFilter == 'model' && !msg.isModel) return false;
      if (query.isNotEmpty && !msg.text.toLowerCase().contains(query)) return false;
      return true;
    }).toList();
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  LocaleService.tr('copied_to_clipboard'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.primary, width: 0.5),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2029),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: Colors.white12),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                LocaleService.tr('clear_chat_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          LocaleService.tr('clear_chat_confirm_msg'),
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              LocaleService.tr('cancel_btn'),
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              LocaleService.tr('confirm_btn'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllChatHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('clear_chat_success')),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatMessageDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    final timePart = '$hourStr:$minStr';

    if (isToday) {
      return '${LocaleService.tr('water_day_today')} • $timePart';
    } else if (isYesterday) {
      return '${LocaleService.tr('water_day_yesterday')} • $timePart';
    } else {
      final dayStr = dt.day.toString().padLeft(2, '0');
      final monthStr = dt.month.toString().padLeft(2, '0');
      return '$dayStr/$monthStr/${dt.year} • $timePart';
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _filteredMessages;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleService.tr('chat_history_title'),
              style: AppTheme.font(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              LocaleService.tr('chat_history_sub'),
              style: AppTheme.font(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_allMessages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: LocaleService.tr('clear_chat_title'),
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // Top Sync status bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white.withValues(alpha: 0.02),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              LocaleService.tr('ai_history_badge'),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${_allMessages.length} tin nhắn • Cloud Firestore Sync',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: LocaleService.tr('chat_search_hint'),
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                      ),
                    ),
                  ),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip('all', LocaleService.tr('filter_all'), _allMessages.length),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'user',
                        LocaleService.tr('filter_user'),
                        _allMessages.where((m) => m.isUser).length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'model',
                        LocaleService.tr('filter_ai'),
                        _allMessages.where((m) => m.isModel).length,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 16, color: Colors.white10),

                // Message List or Empty State
                Expanded(
                  child: messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: messages.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return _buildMessageItem(msg);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white12,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.white70,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.black : Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    final isUser = msg.isUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF1A2234) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUser
              ? const Color(0xFF0072FF).withValues(alpha: 0.4)
              : const Color(0xFF00F0FF).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of bubble
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0072FF).withValues(alpha: 0.2)
                          : const Color(0xFF00F0FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                      color: isUser ? const Color(0xFF00B4DB) : const Color(0xFF00F0FF),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUser ? LocaleService.tr('chat_you') : LocaleService.tr('chat_gemini'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isUser ? const Color(0xFF00B4DB) : const Color(0xFF00F0FF),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    _formatMessageDate(msg.timestamp),
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white54, size: 15),
                    tooltip: LocaleService.tr('copy_advice_tooltip'),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () => _copyText(msg.text),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Message Body
          SelectableText(
            msg.text,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.92),
              fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAiSparkles,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              LocaleService.tr('chat_history_empty'),
              style: AppTheme.font(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleService.tr('chat_history_empty_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(
                LocaleService.tr('ask_ai_btn'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                Navigator.pop(context);
                AiNutritionistChatDialog.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
