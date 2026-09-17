import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/text_sanitizer.dart';
import '../../../providers/offline_model_provider.dart';
import '../../widgets/ue_markdown_text.dart';
import 'package:denizen_ai/denizen_ai.dart';

class ResearchMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? sources;
  final bool isStreaming;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? latency;

  ResearchMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.isStreaming = false,
    this.imageBytes,
    this.imageName,
    this.latency,
  });

  ResearchMessage copyWith({
    String? text,
    bool? isStreaming,
    List<String>? sources,
    Uint8List? imageBytes,
    String? imageName,
    String? latency,
  }) {
    return ResearchMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      sources: sources ?? this.sources,
      isStreaming: isStreaming ?? this.isStreaming,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      latency: latency ?? this.latency,
    );
  }
}

class ResearchSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ResearchMessage> messages;

  ResearchSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  String get previewText {
    for (int i = messages.length - 1; i >= 0; i--) {
      final text = messages[i].text.trim();
      if (text.isNotEmpty) return text;
    }
    return 'Empty research';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => {
        'id': m.id,
        'text': m.text,
        'isUser': m.isUser,
        'timestamp': m.timestamp.toIso8601String(),
        'sources': m.sources,
        'imageName': m.imageName,
        'latency': m.latency,
      }).toList(),
    };
  }

  factory ResearchSession.fromMap(Map<dynamic, dynamic> map) {
    final rawMessages = map['messages'] as List? ?? [];
    return ResearchSession(
      id: map['id']?.toString() ?? 'res_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? 'Academic Research',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messages: rawMessages.map((e) {
        final m = Map<dynamic, dynamic>.from(e as Map);
        return ResearchMessage(
          id: m['id']?.toString() ?? '',
          text: m['text']?.toString() ?? '',
          isUser: m['isUser'] == true,
          timestamp: m['timestamp'] != null
              ? DateTime.tryParse(m['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now(),
          sources: (m['sources'] as List?)?.map((s) => s.toString()).toList(),
          imageName: m['imageName']?.toString(),
          latency: m['latency']?.toString(),
        );
      }).toList(),
    );
  }
}

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ResearchMessage> _messages = [];
  DenizenSession? _textSession;
  final DenizenVoiceSession _voiceSession = DenizenVoiceSession();
  late final DenizenVisionSession _visionSession =
      DenizenVisionSession(aiService: DenizenAI().engine);

  Uint8List? _attachedImageBytes;
  String? _attachedImageName;
  Uint8List? _activeConversationImage;

  bool _isGenerating = false;
  bool _isListening = false;
  bool _isVoiceStudyMode = false;
  String? _error;
  StreamSubscription<String>? _streamSub;

  final List<String> _suggestedQueries = const [
    'Child fever and cough clinical treatment',
    'Explain Newton\'s laws of motion with examples',
    'Severe dehydration ORS & zinc guidelines',
    'Photosynthesis light-dependent reaction steps',
  ];

  Box? _researchBox;
  final List<ResearchSession> _researchSessions = [];
  String _currentSessionId = 'res_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await _initResearchStorage();
      } catch (_) {}
    });
  }

  Future<void> _initResearchStorage() async {
    try {
      if (!Hive.isBoxOpen('tutor_sessions') && !Hive.isBoxOpen('research_sessions')) {
        return;
      }
      _researchBox = await Hive.openBox('research_sessions');
      final stored = _researchBox?.get('sessions');
      if (stored != null && mounted) {
        final list = List<Map>.from(stored);
        setState(() {
          _researchSessions.clear();
          for (final item in list) {
            try {
              _researchSessions.add(ResearchSession.fromMap(item));
            } catch (_) {}
          }
          _researchSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _voiceSession.stopListening();
    _voiceSession.stopSpeaking();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        Uint8List? bytes = picked.bytes;
        if (bytes == null && picked.path != null) {
          final file = File(picked.path!);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          final safeBytes = await DenizenVisionSession.optimizeImage(bytes);
          setState(() {
            _attachedImageBytes = safeBytes;
            _attachedImageName = picked.name;
            _error = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not select image: $e');
      }
    }
  }

  void _clearAttachedImage() {
    setState(() {
      _attachedImageBytes = null;
      _attachedImageName = null;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceSession.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) setState(() => _isListening = true);
      try {
        await _voiceSession.startListening(
          initialText: _textController.text,
          onListeningChanged: (listening) {
            if (mounted) setState(() => _isListening = listening);
          },
          onResult: (text) {
            if (mounted && text.isNotEmpty) {
              setState(() {
                _textController.text = text;
                _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length),
                );
              });
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _error = 'Microphone notice: $e';
          });
        }
      }
    }
  }

  Future<void> _speakText(String text) async {
    await _voiceSession.speak(TextSanitizer.cleanOutput(text));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _saveActiveResearchSession() {
    if (_messages.isEmpty) return;
    final userMessages = _messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) return;

    final firstPrompt = userMessages.first.text.trim();
    final title = firstPrompt.length > 38 ? '${firstPrompt.substring(0, 38)}…' : firstPrompt;

    final idx = _researchSessions.indexWhere((s) => s.id == _currentSessionId);
    final session = ResearchSession(
      id: _currentSessionId,
      title: title.isNotEmpty ? title : 'Academic Research',
      createdAt: idx != -1 ? _researchSessions[idx].createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      messages: List.from(_messages),
    );

    if (idx != -1) {
      _researchSessions[idx] = session;
    } else {
      _researchSessions.insert(0, session);
    }
    _researchSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    _researchBox?.put('sessions', _researchSessions.map((s) => s.toMap()).toList());
  }

  void _clearChat() {
    _streamSub?.cancel();
    _visionSession.clearHistory();
    _textSession = null;
    _saveActiveResearchSession();

    setState(() {
      _currentSessionId = 'res_${DateTime.now().millisecondsSinceEpoch}';
      _messages.clear();
      _attachedImageBytes = null;
      _attachedImageName = null;
      _activeConversationImage = null;
      _isGenerating = false;
      _error = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Started new research chat. Previous chat saved.'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'History',
          textColor: UEColors.accent,
          onPressed: _showResearchHistory,
        ),
      ),
    );
  }

  void _loadResearchSession(ResearchSession session) {
    _streamSub?.cancel();
    _visionSession.clearHistory();
    _textSession = null;
    _saveActiveResearchSession();

    setState(() {
      _currentSessionId = session.id;
      _messages.clear();
      _messages.addAll(session.messages);
      _attachedImageBytes = null;
      _attachedImageName = null;
      _activeConversationImage = null;
      _isGenerating = false;
      _error = null;
    });
    _scrollToBottom();
  }

  void _deleteResearchSession(String id) {
    setState(() {
      _researchSessions.removeWhere((s) => s.id == id);
      _researchBox?.put('sessions', _researchSessions.map((s) => s.toMap()).toList());
    });
  }

  void _showResearchHistory() {
    _saveActiveResearchSession();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UEColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomSheetContext, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return SafeArea(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: UEColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: UEColors.indigo.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(TablerIcons.history, color: UEColors.indigo, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Research History',
                                  style: UETypography.spaceGrotesk(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: UEColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_researchSessions.length} previous ${_researchSessions.length == 1 ? "session" : "sessions"}',
                                  style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
                                ),
                              ],
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: UEColors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _clearChat();
                              },
                              icon: const Icon(TablerIcons.plus, size: 16),
                              label: Text('New Chat', style: UETypography.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: UEColors.border, height: 16),
                      Expanded(
                        child: _researchSessions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(TablerIcons.message_circle_off, size: 44, color: UEColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text('No previous research chats', style: UETypography.spaceGrotesk(fontSize: 15, color: UEColors.textPrimary, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text('Your research queries will appear here automatically.', style: UETypography.inter(fontSize: 12, color: UEColors.textMuted)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                itemCount: _researchSessions.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final s = _researchSessions[index];
                                  final isActive = s.id == _currentSessionId;
                                  return InkWell(
                                    onTap: () {
                                      _loadResearchSession(s);
                                      Navigator.pop(ctx);
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isActive ? UEColors.indigo.withValues(alpha: 0.1) : UEColors.surface,
                                        border: Border.all(
                                          color: isActive ? UEColors.indigo.withValues(alpha: 0.4) : UEColors.border,
                                          width: isActive ? 1.2 : 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isActive ? UEColors.indigo.withValues(alpha: 0.2) : UEColors.bgPrimary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(isActive ? TablerIcons.message_dots : TablerIcons.message_2, size: 16, color: isActive ? UEColors.indigo : UEColors.textMuted),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        s.title,
                                                        style: UETypography.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: UEColors.textPrimary),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isActive) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(color: UEColors.indigo, borderRadius: BorderRadius.circular(6)),
                                                        child: const Text('ACTIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(s.previewText, style: UETypography.inter(fontSize: 12, color: UEColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(TablerIcons.clock, size: 12, color: UEColors.textMuted),
                                                    const SizedBox(width: 4),
                                                    Text('${s.messages.length} msgs', style: UETypography.inter(fontSize: 10, color: UEColors.textMuted)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(TablerIcons.trash, size: 16, color: UEColors.textMuted),
                                            tooltip: 'Delete Chat',
                                            onPressed: () {
                                              _deleteResearchSession(s.id);
                                              setModalState(() {});
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final rawText = overrideText ?? _textController.text;
    final hasImage = _attachedImageBytes != null;

    String prompt = rawText.trim();
    if (prompt.isEmpty && !hasImage) return;

    if (prompt.isEmpty && hasImage) {
      prompt =
          "Analyze and research this image in detail. Explain all visible diagrams, equations, specimens, text, or objects clearly.";
    }

    if (_isGenerating) return;

    final modelProvider = context.read<OfflineModelProvider>();
    if (!modelProvider.hasActiveModel) {
      setState(() => _error = 'No AI model loaded — activate one in Settings > Model Registry.');
      return;
    }

    final Uint8List? imageToSend = _attachedImageBytes ?? _activeConversationImage;
    final isMultimodalQuery = imageToSend != null;

    if (isMultimodalQuery && !modelProvider.hasVisionLoaded) {
      setState(() => _error =
          'Image analysis requires a Vision model. Please load LFM2.5-VL in Settings > Model Registry.');
      return;
    }

    _textController.clear();

    final userMsg = ResearchMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: prompt,
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: _attachedImageBytes,
      imageName: _attachedImageName,
    );

    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMsg = ResearchMessage(
      id: aiMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _error = null;
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _isGenerating = true;
      if (_attachedImageBytes != null) {
        _activeConversationImage = _attachedImageBytes;
        _attachedImageBytes = null;
        _attachedImageName = null;
      }
    });
    _scrollToBottom();

    final sw = Stopwatch()..start();

    try {
      if (isMultimodalQuery) {
        // ── Multimodal Neural Vision Inference ─────────────────────────
        String accumulated = '';
        try {
          final stream = _visionSession.streamChat(
            imageBytes: imageToSend,
            message: prompt,
            maxTokens: 1000,
            temperature: 0.2,
          );

          await for (final chunk in stream) {
            accumulated += chunk;
            if (mounted) {
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == aiMsgId);
                if (idx != -1) {
                  _messages[idx] = _messages[idx].copyWith(text: accumulated);
                }
              });
              _scrollToBottom();
            }
          }
        } catch (streamErr) {
          debugPrint('⚠️ Multimodal streaming error: $streamErr');
          if (accumulated.isEmpty) {
            accumulated = 'Sorry, an error occurred during image analysis: $streamErr';
          } else {
            accumulated += '\n\n*(Notice: $streamErr)*';
          }
        } finally {
          sw.stop();
          final sec = (sw.elapsedMilliseconds / 1000.0).toStringAsFixed(1);
          if (mounted) {
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == aiMsgId);
              if (idx != -1) {
                _messages[idx] = _messages[idx].copyWith(
                  text: accumulated.isNotEmpty ? accumulated : _messages[idx].text,
                  isStreaming: false,
                  latency: "${sec}s (${sw.elapsedMilliseconds} ms)",
                );
              }
              _isGenerating = false;
            });
          }
        }
      } else {
        // ── Standard Text Neural Inference ────────────────────────────
        const systemPrompt =
            'You are a brilliant academic research and clinical guidelines assistant. Provide thorough, well-structured, '
            'accurate, and engaging answers formatted in clear markdown. Always match and respond fluently in the exact language of the user prompt.';

        String accumulated = '';
        try {
          _textSession ??= DenizenAI().createSession(
            systemPrompt: systemPrompt,
            maxTokens: 1000,
          );

          final tokenStream = _textSession!.streamChat(prompt);
          await for (final token in tokenStream) {
            accumulated += token;
            if (mounted) {
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == aiMsgId);
                if (idx != -1) {
                  _messages[idx] = _messages[idx].copyWith(text: accumulated);
                }
              });
              _scrollToBottom();
            }
          }
        } catch (streamErr) {
          debugPrint('⚠️ Text inference error: $streamErr');
          if (accumulated.isEmpty) {
            accumulated = 'Sorry, an error occurred during inference: $streamErr';
          } else {
            accumulated += '\n\n*(Notice: $streamErr)*';
          }
        } finally {
          sw.stop();
          final sec = (sw.elapsedMilliseconds / 1000.0).toStringAsFixed(1);
          if (mounted) {
            setState(() {
              final idx = _messages.indexWhere((m) => m.id == aiMsgId);
              if (idx != -1) {
                _messages[idx] = _messages[idx].copyWith(
                  text: accumulated.isNotEmpty ? accumulated : _messages[idx].text,
                  isStreaming: false,
                  latency: "${sec}s (${sw.elapsedMilliseconds} ms)",
                );
              }
              _isGenerating = false;
            });

            // Auto-speak in Voice Study Mode or when prompt was spoken
            if ((_isVoiceStudyMode || _isListening) && accumulated.isNotEmpty) {
              _speakText(accumulated);
            }
          }
        }
      }
    } catch (e) {
      sw.stop();
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == aiMsgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              text: 'Sorry, an unexpected error occurred: $e',
              isStreaming: false,
            );
          }
          _isGenerating = false;
          _error = 'Failed to generate response: $e';
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: TextSanitizer.cleanOutput(text)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied response to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: UEColors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelProvider = context.watch<OfflineModelProvider>();

    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: Column(
        children: [
          // Header Bar
          _buildHeader(modelProvider),

          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: UEColors.pdfBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: UEColors.pdfFg.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: UEColors.pdfFg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: UETypography.inter(fontSize: 11, color: UEColors.pdfFg),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: UEColors.pdfFg),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _error = null),
                  ),
                ],
              ),
            ),

          // Main Chat Area / Clean Empty State
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(modelProvider)
                : _buildMessageList(),
          ),

          // Attached Image Preview Pill
          if (_attachedImageBytes != null) _buildAttachedImagePill(),

          // Floating Input Bar
          _buildInputBar(modelProvider),
        ],
      ),
    );
  }

  Widget _buildHeader(OfflineModelProvider modelProvider) {
    final activeModelName = modelProvider.activeModel?.name ??
        (DenizenAI().engine.loadedModel?.name ?? 'No Model Active');
    final hasVision = modelProvider.hasVisionLoaded;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(bottom: BorderSide(color: UEColors.bgCard, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: UEColors.indigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasVision ? TablerIcons.eye : TablerIcons.sparkles,
              color: UEColors.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'AI Research',
                        style: UETypography.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: UEColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasVision) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: UEColors.indigo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: UEColors.indigo.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'VISION',
                          style: TextStyle(
                            color: UEColors.indigo,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (_isVoiceStudyMode) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'VOICE MODE',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  activeModelName,
                  style: UETypography.inter(
                    fontSize: 11,
                    color: UEColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isVoiceStudyMode = !_isVoiceStudyMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isVoiceStudyMode
                      ? '🔊 Hands-Free Voice Study Mode Enabled (TTS Auto-Read)'
                      : '🔇 Voice Study Mode Disabled'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: UEColors.surface,
                ),
              );
            },
            icon: Icon(
              _isVoiceStudyMode ? TablerIcons.volume : TablerIcons.volume_3,
              size: 20,
              color: _isVoiceStudyMode ? Colors.redAccent : UEColors.textMuted,
            ),
            tooltip: _isVoiceStudyMode ? 'Disable Voice Mode' : 'Enable Hands-Free Voice Mode',
          ),
          IconButton(
            onPressed: _showResearchHistory,
            icon: const Icon(TablerIcons.history, size: 20, color: UEColors.textMuted),
            tooltip: 'Previous Research Chats',
          ),
          IconButton(
            onPressed: _pickImageFromDevice,
            icon: const Icon(TablerIcons.photo_plus, size: 20, color: UEColors.accent),
            tooltip: 'Attach Image for Analysis',
          ),
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(TablerIcons.plus, size: 20, color: UEColors.accent),
            tooltip: 'New Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedImagePill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: UEColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UEColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _attachedImageBytes!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _attachedImageName ?? 'Attached Image',
                  style: UETypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: UEColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${(_attachedImageBytes!.length / 1024).toStringAsFixed(1)} KB",
                  style: UETypography.inter(
                    fontSize: 10,
                    color: UEColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearAttachedImage,
            icon: const Icon(Icons.close, size: 18, color: UEColors.textMuted),
            tooltip: 'Remove Attachment',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(OfflineModelProvider modelProvider) {
    final isModelLoaded = modelProvider.hasActiveModel;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: UEColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: UEColors.border, width: 0.5),
              ),
              child: const Icon(
                TablerIcons.sparkles,
                size: 26,
                color: UEColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What would you like to research?',
              textAlign: TextAlign.center,
              style: UETypography.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: UEColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isModelLoaded
                  ? 'Ask any academic question or clinical query for instant token-by-token neural streaming responses.'
                  : 'Activate a model in Settings to enable live neural research streaming.',
              textAlign: TextAlign.center,
              style: UETypography.inter(
                fontSize: 13,
                color: UEColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isModelLoaded) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suggested Topics:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: UEColors.textMuted),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedQueries.map((query) {
                  return ActionChip(
                    avatar: const Icon(TablerIcons.bulb, size: 15, color: UEColors.indigo),
                    label: Text(query, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(query),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildChatBubble(ResearchMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 48, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: UEColors.indigo.withValues(alpha: 0.18),
            border: Border.all(color: UEColors.indigo.withValues(alpha: 0.3), width: 0.5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imageBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    msg.imageBytes!,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                msg.text,
                style: UETypography.inter(
                  fontSize: 14,
                  color: UEColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // AI Response Bubble
    return Container(
      margin: const EdgeInsets.only(right: 24, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: UEColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: UEColors.border, width: 0.5),
            ),
            child: const Icon(
              TablerIcons.sparkles,
              size: 16,
              color: UEColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Research Assistant',
                            style: UETypography.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: UEColors.textMuted,
                            ),
                          ),
                          if (msg.latency != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '• ${msg.latency!}',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!msg.isStreaming && msg.text.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => _speakText(msg.text),
                        icon: const Icon(TablerIcons.volume, size: 16, color: UEColors.accent),
                        tooltip: 'Read Aloud',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _copyToClipboard(msg.text),
                        icon: const Icon(TablerIcons.copy, size: 16, color: UEColors.textMuted),
                        tooltip: 'Copy',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: UEColors.surface,
                    border: Border.all(color: UEColors.border, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.text.isEmpty && msg.isStreaming)
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: UEColors.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Thinking & researching…',
                              style: UETypography.inter(
                                fontSize: 13,
                                color: UEColors.textMuted,
                              ),
                            ),
                          ],
                        )
                      else
                        UEMarkdownText(msg.text),

                      if (msg.sources != null && msg.sources!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: UEColors.border, height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(TablerIcons.file_text, size: 14, color: UEColors.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Grounded in library: ${msg.sources!.join(", ")}',
                                style: UETypography.inter(
                                  fontSize: 11,
                                  color: UEColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(OfflineModelProvider modelProvider) {
    final isEnabled = modelProvider.hasActiveModel;
    final hasImage = _attachedImageBytes != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: UEColors.bgPrimary,
        border: Border(top: BorderSide(color: UEColors.bgCard, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: UEColors.surface,
                  border: Border.all(
                    color: _isListening
                        ? UEColors.accent
                        : (hasImage ? UEColors.indigo : UEColors.border),
                    width: _isListening || hasImage ? 1.0 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isGenerating ? null : _pickImageFromDevice,
                      icon: Icon(
                        hasImage ? TablerIcons.photo_check : TablerIcons.photo,
                        color: hasImage ? UEColors.indigo : UEColors.textMuted,
                        size: 20,
                      ),
                      tooltip: 'Attach Image / Diagram',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        enabled: isEnabled && !_isGenerating,
                        minLines: 1,
                        maxLines: 4,
                        style: UETypography.inter(fontSize: 14, color: UEColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening to speech...'
                              : hasImage
                                  ? 'Ask anything about this image...'
                                  : isEnabled
                                      ? 'Ask anything (e.g. quantum physics, calculus)...'
                                      : 'Activate a model in Settings to ask...',
                          hintStyle: UETypography.inter(
                            fontSize: 13,
                            color: _isListening
                                ? UEColors.accent
                                : UEColors.textMuted,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) => _sendMessage(val),
                      ),
                    ),
                    IconButton(
                      onPressed: isEnabled ? _toggleListening : null,
                      icon: Icon(
                        _isListening ? TablerIcons.microphone_off : TablerIcons.microphone,
                        color: _isListening ? UEColors.accent : UEColors.textMuted,
                        size: 20,
                      ),
                      tooltip: _isListening ? 'Stop Listening' : 'Speak Prompt',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: (isEnabled || hasImage) && !_isGenerating
                  ? () => _sendMessage()
                  : null,
              style: IconButton.styleFrom(
                backgroundColor: (isEnabled || hasImage) && !_isGenerating ? UEColors.indigo : UEColors.surface,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(TablerIcons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
