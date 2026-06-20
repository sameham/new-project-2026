// lib/features/ai/screens/ai_assistant_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../database/app_database.dart';
import '../../../shared/widgets/ai_prompt_card.dart';

class _AiMessage {
  final String role;
  final String content;
  const _AiMessage({required this.role, required this.content});
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_AiMessage> _messages = [];
  bool _loading = false;

  static const _presets = [
    'من يسافر خلال 72 ساعة؟',
    'ما هي أرباح هذا الشهر؟',
    'من هم العملاء المدينون؟',
    'أفضل العملاء هذا الشهر',
    'ملخص إيرادات اليوم',
    'اقتراحات لزيادة المبيعات',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getApiKey() async {
    final db = ref.read(databaseProvider);
    return db.settingsDao.get('claude_api_key');
  }

  Future<String> _buildContext(String prompt) async {
    final db = ref.read(databaseProvider);
    final sb = StringBuffer();

    if (prompt.contains('72 ساعة') || prompt.contains('يسافر')) {
      final upcoming = await db.bookingsDao.getUpcoming();
      sb.writeln('رحلات قادمة (48-72 ساعة): ${upcoming.length}');
      for (final b in upcoming.take(5)) {
        sb.writeln('- ${b.origin ?? ''} → ${b.destination ?? ''}, ${b.departureDate}');
      }
    }

    if (prompt.contains('ربح') || prompt.contains('إيراد') || prompt.contains('شهر')) {
      final monthRev = await db.paymentsDao.getMonthTotal();
      sb.writeln('إيرادات هذا الشهر: $monthRev ج.م');
    }

    if (prompt.contains('مدين') || prompt.contains('ديون')) {
      final debtors = await db.customersDao.getDebtors();
      sb.writeln('العملاء المدينون: ${debtors.length}');
      for (final c in debtors.take(5)) {
        sb.writeln('- ${c.firstName} ${c.lastName}: ${c.balance} ج.م');
      }
    }

    if (prompt.contains('أفضل عميل') || prompt.contains('عملاء')) {
      final topC = await db.bookingsDao.getTopCustomers(5);
      sb.writeln('أفضل العملاء حسب الإيرادات:');
      for (final c in topC) {
        sb.writeln('- ${c.customerId}: ${c.totalRevenue} ج.م (${c.bookingCount} حجز)');
      }
    }

    if (sb.isEmpty) {
      final monthRev = await db.paymentsDao.getTodayTotal();
      sb.writeln('إيرادات اليوم: $monthRev ج.م');
    }

    return sb.toString();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _loading) return;

    setState(() {
      _messages.add(_AiMessage(role: 'user', content: text));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _messages.add(const _AiMessage(
          role: 'assistant',
          content: 'لم يتم إعداد مفتاح API الخاص بـ Claude. يرجى إضافته في الإعدادات > إعدادات المزامنة.',
        ));
        _loading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final context = await _buildContext(text);
      final systemPrompt = 'أنت مساعد وكالة سفر محترف. لديك البيانات التالية:\n$context\nأجب دائماً باللغة العربية بشكل موجز ومفيد.';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': [
            ..._messages.where((m) => m.role == 'user' || m.role == 'assistant').map((m) => {'role': m.role, 'content': m.content}),
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['content'][0]['text'] as String;
        setState(() {
          _messages.add(_AiMessage(role: 'assistant', content: reply));
          _loading = false;
        });
      } else {
        setState(() {
          _messages.add(_AiMessage(role: 'assistant', content: 'حدث خطأ: ${response.statusCode}'));
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_AiMessage(role: 'assistant', content: 'تعذر الاتصال بالخادم. تأكد من اتصال الإنترنت.'));
        _loading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.psychology_outlined, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('مساعد الذكاء الاصطناعي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Claude Haiku', style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'محادثة جديدة',
            onPressed: () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preset prompt chips
          if (_messages.isEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  child: Text('اقتراحات', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _presets.map((p) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AiPromptCard(prompt: p, onTap: () => _sendMessage(p)),
                    )).toList(),
                  ),
                ),
              ]),
            )
          else
            Container(
              height: 52,
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: _presets.map((p) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AiPromptCard(prompt: p, onTap: () => _sendMessage(p)),
                )).toList(),
              ),
            ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.psychology_outlined, size: 64, color: AppColors.primaryLight),
                      const SizedBox(height: 16),
                      Text('مساعدك الذكي جاهز', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('اسألني عن بياناتك أو اختر من الاقتراحات',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                    ]),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
                  ),
          ),

          // Loading
          if (_loading)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('يفكر...', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ]),
            ),

          // Input
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 12, right: 12, top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'اسأل عن أي شيء...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.primary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: _sendMessage,
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendMessage(_controller.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _AiMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          message.content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
