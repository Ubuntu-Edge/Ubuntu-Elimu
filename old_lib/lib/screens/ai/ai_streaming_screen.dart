import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/patient.dart';
import '../../providers/chat_provider.dart';
import '../../providers/offline_model_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/chat_message.dart';
import '../../widgets/formatted_ai_message.dart';
import 'offline_model_download_screen.dart';
import 'chat_history_screen.dart';

class AIStreamingScreen extends StatefulWidget {
  final Patient patient;

  const AIStreamingScreen({super.key, required this.patient});

  @override
  State<AIStreamingScreen> createState() => _AIStreamingScreenState();
}

class _AIStreamingScreenState extends State<AIStreamingScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    
    // Use the provider to load the chat history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadChatHistory(
        widget.patient.id,
        patientName: widget.patient.displayId,
      );
    });
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      print("TTS Error: $msg");
    });
  }

  void _initSpeech() async {
    if (await Permission.microphone.request().isGranted) {
      _speechEnabled = await _speechToText.initialize();
    }
    setState(() {});
  }

  Future<void> _startListening() async {
    if (_isSpeaking) await _flutterTts.stop();
    if (_speechEnabled) {
      await _speechToText.listen(onResult: (result) {
        setState(() {
          _promptController.text = result.recognizedWords;
        });
        if (result.finalResult) {
          _sendMessage();
        }
      });
      setState(() => _isListening = true);
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  // TODO: Unused method - kept for potential text-to-speech feature
  // Future<void> _speak(String text) async {
  //   if (text.isNotEmpty) {
  //     if (_isListening) await _stopListening();
  //     await _flutterTts.speak(text);
  //   }
  // }

  void _sendMessage() {
    final provider = context.read<ChatProvider>();
    final text = _promptController.text.trim();
    if (text.isNotEmpty) {
      provider.sendMessage(text, widget.patient.id);
      _promptController.clear();
      _scrollToBottom();
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

  void _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History'),
        content: const Text('Are you sure you want to delete all chat history for this patient?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ChatProvider>().deleteAllHistory(widget.patient.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history deleted.'), backgroundColor: Colors.green),
      );
    }
  }

  void _shareConversation() async {
    final provider = context.read<ChatProvider>();
    if (provider.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conversation to share')),
      );
      return;
    }

    final conversationText = StringBuffer();
    conversationText.writeln('AI Chat Conversation');
    conversationText.writeln('Patient: ${widget.patient.displayId}');
    conversationText.writeln('Date: ${DateTime.now().toString().split('.')[0]}');
    conversationText.writeln('\n${'=' * 50}\n');

    for (final message in provider.messages) {
      conversationText.writeln('${message.sender}:');
      conversationText.writeln(message.message);
      conversationText.writeln();
    }

    await Share.share(
      conversationText.toString(),
      subject: 'AI Chat Conversation - Patient ${widget.patient.displayId}',
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chat for ${widget.patient.displayId}'),
        actions: [
          // AI Mode Indicator Badge
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: chatProvider.aiMode == AIMode.online 
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: chatProvider.aiMode == AIMode.online 
                          ? Colors.blue
                          : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          chatProvider.aiMode == AIMode.online 
                            ? Icons.cloud 
                            : Icons.cloud_off,
                          size: 16,
                          color: chatProvider.aiMode == AIMode.online 
                            ? Colors.blue
                            : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chatProvider.aiMode == AIMode.online ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: chatProvider.aiMode == AIMode.online 
                              ? Colors.blue
                              : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // New Chat Session Button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<ChatProvider>().startNewSession(
                widget.patient.id,
                patientName: widget.patient.displayId,
              );
            },
            tooltip: 'New Chat',
          ),
          // Menu with download models and delete (no manual toggle - automatic now)
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation();
                  } else if (value == 'download_models') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OfflineModelDownloadScreen(),
                      ),
                    );
                  } else if (value == 'view_history') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatHistoryScreen(patient: widget.patient),
                      ),
                    );
                  } else if (value == 'share') {
                    _shareConversation();
                  }
                },
                itemBuilder: (context) {
                  final offlineProvider = Provider.of<OfflineModelProvider>(context, listen: false);
                  
                  return [
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
                              ? 'Manage Models' 
                              : 'Download Models',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view_history',
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('View Chat History'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Share Conversation'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete All History'),
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
          _scrollToBottom();
          final offlineProvider = Provider.of<OfflineModelProvider>(context, listen: false);
          final showDownloadSuggestion = provider.isOnline && !offlineProvider.hasActiveModel;
          
          return Column(
            children: [
              // Download suggestion banner when online without model
              if (showDownloadSuggestion)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Download an offline model to use the AI when internet is unavailable',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OfflineModelDownloadScreen(),
                            ),
                          );
                        },
                        child: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: provider.isLoading && provider.messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          final message = provider.messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
              if (provider.isLoading && provider.messages.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              _buildInputArea(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == 'You';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? Colors.blue[200]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              SelectableText(
                message.message,
                style: const TextStyle(fontSize: 15, height: 1.4),
              )
            else
              FormattedAIMessage(message: message.message),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
            color: _isListening ? Colors.red : Theme.of(context).primaryColor,
            onPressed: _speechEnabled ? (_isListening ? _stopListening : _startListening) : null,
          ),
          IconButton(
            icon: const Icon(Icons.content_paste),
            color: Theme.of(context).primaryColor,
            onPressed: () async {
              final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
              if (clipboardData?.text != null) {
                setState(() {
                  _promptController.text = clipboardData!.text!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Text pasted from clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            tooltip: 'Paste from clipboard',
          ),
          Expanded(
            child: TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              autocorrect: true,
              enableSuggestions: true,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: context.watch<ChatProvider>().isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
