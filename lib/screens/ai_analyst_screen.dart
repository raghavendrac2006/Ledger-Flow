import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/ai_analyst_controller.dart';
import '../widgets/bento_card.dart';
import '../widgets/skeleton_card.dart';

class AIAnalystScreen extends StatefulWidget {
  const AIAnalystScreen({super.key});

  @override
  State<AIAnalystScreen> createState() => _AIAnalystScreenState();
}

class _AIAnalystScreenState extends State<AIAnalystScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _submitQuery(AIAnalystController controller) {
    final text = _queryController.text.trim();
    if (text.isNotEmpty) {
      _queryController.clear();
      controller.askAnalyst(text).then((_) {
        _scrollToBottom();
      });
      _scrollToBottom();
    }
  }

  Widget _buildConfigErrorScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          backgroundColor: Colors.white,
          borderRadius: AppTheme.radiusLg,
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3), width: 1.5),
          shadowStyle: ShadowStyle.light,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.error,
                    size: 36.0,
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  "Configuration Error",
                  style: AppTheme.headlineMd.copyWith(color: AppTheme.error, fontSize: 20.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Text(
                  "Please compile the application using your local key configuration file.",
                  style: AppTheme.bodyMd.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                const Divider(color: AppTheme.outlineVariant),
                const SizedBox(height: 16.0),
                Text(
                  "Ensure 'api_keys.json' is configured in the project root and start the application using the compilation define flag:\n\nflutter run --dart-define-from-file=api_keys.json",
                  style: AppTheme.labelSm.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AIAnalystController>(context);

    // Auto-scroll when messages or loading state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  bottom: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 26.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI FINANCIAL ANALYST",
                          style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          "Powered by Gemini 2.5 Flash • Real-Time Database Insights",
                          style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (controller.isConfigured && controller.messages.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: AppTheme.error),
                      tooltip: "Clear Chat",
                      onPressed: () => controller.clearChat(),
                    ),
                ],
              ),
            ),

            if (!controller.isConfigured)
              Expanded(child: _buildConfigErrorScreen())
            else ...[
              // Message Stream Area
              Expanded(
                child: controller.messages.isEmpty
                    ? _buildEmptyState(controller)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24.0),
                        itemCount: controller.messages.length + (controller.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == controller.messages.length) {
                            return _buildLoadingBubble();
                          }
                          return _buildChatBubble(controller.messages[index]);
                        },
                      ),
              ),

              // Sticky Bottom Input area
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: const Border(
                    top: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                  ),
                  boxShadow: AppTheme.hardShadowLight,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: AppTheme.bodyMd,
                        onSubmitted: (_) => _submitQuery(controller),
                        decoration: InputDecoration(
                          hintText: "Ask about profits, outstanding balances, expenses...",
                          hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7)),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    InkWell(
                      onTap: controller.isLoading ? null : () => _submitQuery(controller),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: controller.isLoading ? AppTheme.outline : AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: controller.isLoading ? null : AppTheme.hardShadowButton,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                margin: const EdgeInsets.only(right: 8.0, top: 4.0),
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF0F172A) : AppTheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppTheme.radiusLg),
                    topRight: const Radius.circular(AppTheme.radiusLg),
                    bottomLeft: Radius.circular(isUser ? AppTheme.radiusLg : 4.0),
                    bottomRight: Radius.circular(isUser ? 4.0 : AppTheme.radiusLg),
                  ),
                  border: isUser ? null : AppTheme.cardBorder,
                  boxShadow: isUser ? null : AppTheme.hardShadowLight,
                ),
                child: Text(
                  msg.text,
                  style: AppTheme.bodyMd.copyWith(
                    color: isUser ? Colors.white : AppTheme.onSurface,
                    fontSize: 15.0,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              Container(
                margin: const EdgeInsets.only(left: 8.0, top: 4.0),
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF475569),
                  size: 16.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8.0, top: 4.0),
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 16.0,
              ),
            ),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                child: const SkeletonCard(
                  height: 64.0,
                  borderRadius: AppTheme.radiusLg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AIAnalystController controller) {
    final suggestions = [
      "Summarize my net profit and expenses this month.",
      "List the top 3 customers with the largest outstanding balance.",
      "Analyze the efficiency of our active Rice Flour bags.",
      "What is our remaining owner capital loan balance?"
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16.0),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primary,
                    size: 40.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  "Intelligent Business Insights",
                  style: AppTheme.headlineMd.copyWith(fontSize: 20.0),
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Ask questions about your sales log, expenditures,\nrice flour usage, and owner loan state.",
                  style: AppTheme.labelSm.copyWith(fontSize: 13.0, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40.0),
          Text(
            "TRY ASKING",
            style: AppTheme.labelBold.copyWith(
              fontSize: 11.0,
              letterSpacing: 1.5,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12.0),
          ...suggestions.map((prompt) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: BentoCard(
                  padding: const EdgeInsets.all(16.0),
                  backgroundColor: AppTheme.surface,
                  borderRadius: AppTheme.radiusLg,
                  shadowStyle: ShadowStyle.light,
                  onTap: () {
                    _queryController.text = prompt;
                    _submitQuery(controller);
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primary, size: 18.0),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Text(
                          prompt,
                          style: AppTheme.bodyMd.copyWith(fontSize: 14.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.onSurfaceVariant, size: 12.0),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
