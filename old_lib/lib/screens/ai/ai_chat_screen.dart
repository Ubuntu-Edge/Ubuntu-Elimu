import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../providers/chat_provider.dart';
import '../../providers/offline_model_provider.dart';
import '../../models/chat_message.dart';
import '../../l10n/app_localizations.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/markdown_text.dart';
import 'offline_model_download_screen.dart';
import 'chat_history_screen.dart';

class AIChatScreen extends StatefulWidget {
  final Patient patient;

  const AIChatScreen({super.key, required this.patient});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load the chat history when the screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final modelProvider = Provider.of<OfflineModelProvider>(
        context,
        listen: false,
      );

      chatProvider.loadChatHistory(
        widget.patient.id,
        patientName: widget.patient.displayId,
      );

      // Wait a moment for OfflineModelProvider to finish loading model
      // before checking mode
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if offline model is loaded and update mode accordingly
      await chatProvider.checkAndUpdateModeFromModelState(modelProvider);
    });
  }

  void _sendPrompt(ChatProvider provider) {
    provider.sendMessage(_promptController.text, widget.patient.id);
    _promptController.clear();
  }

  void _showDeleteConfirmation(ChatProvider provider) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('deleteHistory') ?? 'Delete History'),
        content: Text(
          l10n.translate('deleteHistoryConfirm') ??
              'Are you sure you want to permanently delete all chat history for this patient?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAllHistory(widget.patient.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.translate('chatHistoryDeleted') ??
                        'Chat history deleted.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.translate('aiChatFor') ?? 'AI Chat for'} ${widget.patient.displayId}',
        ),
        actions: [
          // Network Status + AI Mode Indicator Badge
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              // Listen to connectivity changes
              return ListenableBuilder(
                listenable: ConnectivityService.instance,
                builder: (context, _) {
                  final isOnline = ConnectivityService.instance.isOnline;
                  final isUsingOfflineMode =
                      chatProvider.aiMode == AIMode.offline;

                  // Determine badge color based on actual connectivity
                  Color badgeColor;
                  String statusText;
                  IconData statusIcon;

                  if (isUsingOfflineMode) {
                    // User selected offline mode
                    badgeColor = Colors.orange;
                    statusText = l10n.offlineMode;
                    statusIcon = Icons.offline_bolt;
                  } else if (isOnline) {
                    // Online mode and connected
                    badgeColor = Colors.green;
                    statusText = l10n.onlineMode;
                    statusIcon = Icons.cloud_done;
                  } else {
                    // Online mode selected but no connectivity
                    badgeColor = Colors.red;
                    statusText =
                        l10n.translate('noConnection') ?? 'No Connection';
                    statusIcon = Icons.cloud_off;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // New Chat Session Button
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).startNewSession(
                widget.patient.id,
                patientName: widget.patient.displayId,
              );
            },
            tooltip: l10n.translate('newChatSession') ?? 'New Chat Session',
          ),
          // Menu with mode toggle, download models, and delete
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'delete') {
                    _showDeleteConfirmation(chatProvider);
                  } else if (value == 'toggle_mode') {
                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.translate('switchingMode') ??
                              'Switching mode...',
                        ),
                        duration: Duration(milliseconds: 500),
                      ),
                    );

                    // Await the toggle
                    await chatProvider.toggleAIMode();

                    // Show confirmation with new mode
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            chatProvider.aiMode == AIMode.online
                                ? l10n.translate('switchedToOnline') ??
                                    'Switched to Online Mode'
                                : l10n.translate('switchedToOffline') ??
                                    'Switched to Offline Mode',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else if (value == 'download_models') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const OfflineModelDownloadScreen(),
                      ),
                    );
                  } else if (value == 'view_history') {
                    // Navigate to chat history screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatHistoryScreen(patient: widget.patient),
                      ),
                    );
                  }
                },
                itemBuilder: (context) {
                  final offlineProvider = Provider.of<OfflineModelProvider>(
                    context,
                    listen: false,
                  );

                  return [
                    PopupMenuItem(
                      value: 'toggle_mode',
                      child: Row(
                        children: [
                          Icon(
                            chatProvider.aiMode == AIMode.online
                                ? Icons.cloud_off
                                : Icons.cloud,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chatProvider.aiMode == AIMode.online
                                ? l10n.translate('switchToOffline') ??
                                    'Switch to Offline'
                                : l10n.translate('switchToOnline') ??
                                    'Switch to Online',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'download_models',
                      child: Row(
                        children: [
                          Icon(
                            offlineProvider.hasActiveModel
                                ? Icons.check_circle
                                : Icons.download,
                            color: offlineProvider.hasActiveModel
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            offlineProvider.hasActiveModel
                                ? l10n.translate('manageModels') ??
                                    'Manage Models'
                                : l10n.translate('downloadModels') ??
                                    'Download Models',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_history',
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            l10n.translate('viewChatHistory') ??
                                'View Chat History',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            l10n.translate('deleteAllHistory') ??
                                'Delete All History',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              if (provider.isLoading) const LinearProgressIndicator(),
              _buildInputArea(provider, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == 'You';
    return Padding(
      padding: EdgeInsets.fromLTRB(isUser ? 52 : 8, 4, isUser ? 8 : 52, 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: isUser
            ? _buildUserBubble(message.message)
            : _buildAiResponseWidget(message.message),
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00838F),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 15, color: Colors.white, height: 1.4)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: text)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_outlined, size: 12, color: Colors.white60),
                SizedBox(width: 4),
                Text('Copy',
                    style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResponseWidget(String message) {
    final sections = _parseAiSections(message);

    if (sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ManualMarkdownText(message,
                baseStyle: const TextStyle(
                    fontSize: 15, color: Colors.black87, height: 1.4)),
            const SizedBox(height: 6),
            _buildCopyButton(message, dark: false),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sections.containsKey('assessment'))
          _buildSectionCard(
            icon: Icons.troubleshoot_outlined,
            title: 'Possible Conditions',
            content: sections['assessment']!,
            bgColor: const Color(0xFFFFF8E1),
            borderColor: const Color(0xFFF57F17),
            iconColor: const Color(0xFFE65100),
          ),
        if (sections.containsKey('action'))
          _buildSectionCard(
            icon: Icons.healing_outlined,
            title: 'First Aid & Actions',
            content: sections['action']!,
            bgColor: const Color(0xFFE8F5E9),
            borderColor: const Color(0xFF388E3C),
            iconColor: const Color(0xFF2E7D32),
          ),
        if (sections.containsKey('important'))
          _buildSectionCard(
            icon: Icons.warning_amber_rounded,
            title: 'Next Steps',
            content: sections['important']!,
            bgColor: const Color(0xFFFFEBEE),
            borderColor: const Color(0xFFE53935),
            iconColor: const Color(0xFFC62828),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, top: 2),
            child: _buildCopyButton(
              sections.values.join('\n'),
              dark: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyButton(String text, {bool dark = false}) {
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: text)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.copy_outlined,
              size: 12, color: dark ? Colors.white60 : Colors.black38),
          const SizedBox(width: 4),
          Text('Copy',
              style: TextStyle(
                  fontSize: 11, color: dark ? Colors.white60 : Colors.black38)),
        ],
      ),
    );
  }

  Map<String, String> _parseAiSections(String message) {
    final result = <String, String>{};
    final lines = message.split('\n');
    String currentSection = '';
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();

      if (lower.startsWith('assessment:') || lower.startsWith('tathmini:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = buffer.toString().trim();
        }
        currentSection = 'assessment';
        buffer.clear();
        final content = trimmed.replaceFirst(
            RegExp(r'^(assessment|tathmini):\s*', caseSensitive: false), '');
        if (content.isNotEmpty) buffer.writeln(content);
      } else if (lower.startsWith('action:') || lower.startsWith('hatua:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = buffer.toString().trim();
        }
        currentSection = 'action';
        buffer.clear();
        final content = trimmed.replaceFirst(
            RegExp(r'^(action|hatua):\s*', caseSensitive: false), '');
        if (content.isNotEmpty) buffer.writeln(content);
      } else if (lower.startsWith('important:') ||
          lower.startsWith('muhimu:')) {
        if (currentSection.isNotEmpty) {
          result[currentSection] = buffer.toString().trim();
        }
        currentSection = 'important';
        buffer.clear();
        final content = trimmed.replaceFirst(
            RegExp(r'^(important|muhimu):\s*', caseSensitive: false), '');
        if (content.isNotEmpty) buffer.writeln(content);
      } else if (currentSection.isNotEmpty && trimmed.isNotEmpty) {
        buffer.writeln(trimmed);
      }
    }

    if (currentSection.isNotEmpty && buffer.isNotEmpty) {
      result[currentSection] = buffer.toString().trim();
    }

    return result;
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    final lines =
        content.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.13),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 17),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: iconColor)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((line) {
                final isBullet = line.startsWith('-') || line.startsWith('•');
                final text = isBullet
                    ? line.replaceFirst(RegExp(r'^[-•]\s*'), '')
                    : line;
                if (isBullet) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 7, right: 8),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: borderColor, shape: BoxShape.circle),
                        ),
                        Expanded(
                          child: ManualMarkdownText(
                            text,
                            baseStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ManualMarkdownText(
                    text,
                    baseStyle: const TextStyle(
                        fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider provider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText:
                    l10n.translate('typeYourMessage') ?? 'Type your message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendPrompt(provider),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: provider.isLoading ? null : () => _sendPrompt(provider),
          ),
        ],
      ),
    );
  }
}
