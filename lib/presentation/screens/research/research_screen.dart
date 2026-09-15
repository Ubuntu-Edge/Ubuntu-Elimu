import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/offline_model_provider.dart';
import '../../../services/offline_ai_service.dart';
import 'package:denizen_ai/denizen_ai.dart' hide OfflineAIService;

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

class ResearchScreen extends StatefulWidget {
  const ResearchScreen({super.key});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ResearchMessage> _messages = [];
  final DenizenVoiceSession _voiceSession = DenizenVoiceSession();
  late final DenizenVisionSession _visionSession =
      DenizenVisionSession(aiService: DenizenAI().engine);

  Uint8List? _attachedImageBytes;
  String? _attachedImageName;
  Uint8List? _activeConversationImage;

  bool _isGenerating = false;
  bool _isListening = false;
  bool _isLoadingVisionModel = false;
  double _modelDownloadProgress = 0.0;
  String _modelStatusMessage = "";
  String? _error;
  StreamSubscription<String>? _streamSub;

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
          setState(() {
            _attachedImageBytes = bytes;
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

  Future<void> _activateVisionModel() async {
    final modelProvider = context.read<OfflineModelProvider>();
    setState(() {
      _isLoadingVisionModel = true;
      _modelDownloadProgress = 0.0;
      _modelStatusMessage = "Activating LFM2.5-VL Vision AI...";
      _error = null;
    });

    try {
      final visionModel = DefaultOfflineModels.getUltraLightVisionModel();
      await DenizenAI().models.load(
        visionModel.id,
        requireWifi: false,
        onProgress: (p) {
          setState(() {
            _modelDownloadProgress = p.progress;
            _modelStatusMessage =
                "Downloading Vision Model: ${(p.percent).toStringAsFixed(1)}% (${(p.bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB / ${(p.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB)";
          });
        },
      );
      await modelProvider.setActiveModel(visionModel);
      setState(() {
        _modelStatusMessage = "Vision Model Ready!";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('LFM2.5-VL Vision Model activated successfully!'),
            backgroundColor: UEColors.indigo,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to activate vision model: $e';
      });
    } finally {
      setState(() {
        _isLoadingVisionModel = false;
      });
    }
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
    await _voiceSession.speak(text);
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

  void _clearChat() {
    _streamSub?.cancel();
    _visionSession.clearHistory();
    setState(() {
      _messages.clear();
      _attachedImageBytes = null;
      _attachedImageName = null;
      _activeConversationImage = null;
      _isGenerating = false;
      _error = null;
    });
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final rawText = overrideText ?? _textController.text;
    final hasImage = _attachedImageBytes != null;
    final hasActiveVisualContext = _activeConversationImage != null;

    String prompt = rawText.trim();
    if (prompt.isEmpty && !hasImage) return;

    // If only image was attached without text, default to an intelligent research prompt
    if (prompt.isEmpty && hasImage) {
      prompt =
          "Analyze and research this image in detail. Explain all visible diagrams, equations, specimens, text, or objects clearly.";
    }

    if (_isGenerating) return;

    final modelProvider = context.read<OfflineModelProvider>();
    if (!modelProvider.hasActiveModel) {
      setState(() => _error = 'No AI model loaded — activate one in Settings or below.');
      return;
    }

    final Uint8List? imageToSend = _attachedImageBytes ?? _activeConversationImage;
    final isMultimodalQuery = imageToSend != null;

    if (isMultimodalQuery && !modelProvider.hasVisionLoaded) {
      setState(() => _error =
          'Image analysis requires the LFM2.5-VL Multimodal Vision model. Tap "Activate Vision AI" above.');
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
        final stream = _visionSession.streamChat(
          imageBytes: imageToSend,
          message: prompt,
          maxTokens: 1000,
          temperature: 0.2,
        );

        String accumulated = '';
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

        sw.stop();
        final sec = (sw.elapsedMilliseconds / 1000.0).toStringAsFixed(1);
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == aiMsgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                isStreaming: false,
                latency: "${sec}s (${sw.elapsedMilliseconds} ms)",
              );
            }
            _isGenerating = false;
          });
        }
      } else {
        // ── Standard Text Neural Inference ────────────────────────────
        const systemPrompt =
            'You are a brilliant academic research assistant. Provide thorough, well-structured, '
            'accurate, and engaging answers formatted in clear markdown. Always match and respond fluently in the exact language of the user prompt.';

        final stream = OfflineAIService.instance.generateResponseStream(
          prompt: prompt,
          systemPrompt: systemPrompt,
          maxTokens: 1000,
          temperature: 0.7,
        );

        String accumulated = '';
        _streamSub = stream.listen(
          (chunk) {
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
          },
          onError: (err) {
            if (mounted) {
              setState(() {
                _isGenerating = false;
                _error = 'Error stream: $err';
              });
            }
          },
          onDone: () {
            sw.stop();
            final sec = (sw.elapsedMilliseconds / 1000.0).toStringAsFixed(1);
            if (mounted) {
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == aiMsgId);
                if (idx != -1) {
                  _messages[idx] = _messages[idx].copyWith(
                    isStreaming: false,
                    latency: "${sec}s (${sw.elapsedMilliseconds} ms)",
                  );
                }
                _isGenerating = false;
              });
            }
          },
        );
      }
    } catch (e) {
      sw.stop();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = 'Failed to generate response: $e';
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
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
    final bool isVisionReady = modelProvider.hasVisionLoaded;

    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      body: Column(
        children: [
          // Header Bar
          _buildHeader(modelProvider),

          // Vision Model Activation Banner (if needed)
          if (!isVisionReady && (_attachedImageBytes != null || _isLoadingVisionModel))
            _buildVisionActivationBanner(),

          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: UEColors.pdfBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: UEColors.pdfFg.withOpacity(0.3)),
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

          // Main Chat Area / Empty Suggestion State
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(modelProvider)
                : _buildMessageList(),
          ),

          // Attached Image Preview Pill (if an image is selected)
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
              color: hasVision
                  ? Colors.purple.withOpacity(0.15)
                  : UEColors.indigo.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasVision ? TablerIcons.eye : TablerIcons.sparkles,
              color: hasVision ? Colors.purpleAccent : UEColors.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AI Research',
                    style: UETypography.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: UEColors.textPrimary,
                    ),
                  ),
                  if (hasVision) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'VISION',
                        style: TextStyle(
                          color: Colors.purpleAccent,
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
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _pickImageFromDevice,
            icon: const Icon(TablerIcons.photo_plus, size: 20, color: UEColors.accent),
            tooltip: 'Upload Image for Analysis',
          ),
          if (_messages.isNotEmpty)
            IconButton(
              onPressed: _clearChat,
              icon: const Icon(TablerIcons.plus, size: 20, color: UEColors.textMuted),
              tooltip: 'New Chat',
            ),
        ],
      ),
    );
  }

  Widget _buildVisionActivationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(TablerIcons.eye, color: Colors.purpleAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Vision analysis requires LFM2.5-VL multimodal weights (~322 MB)",
                  style: UETypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purpleAccent,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoadingVisionModel ? null : _activateVisionModel,
                icon: const Icon(Icons.bolt, size: 14),
                label: const Text("Activate Vision AI", style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (_isLoadingVisionModel) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _modelDownloadProgress),
            const SizedBox(height: 4),
            Text(
              _modelStatusMessage,
              style: const TextStyle(fontSize: 10, color: Colors.purpleAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachedImagePill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: UEColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        fontWeight: FontWeight.bold,
                        color: UEColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${(_attachedImageBytes!.length / 1024).toStringAsFixed(1)} KB • Multi-tile ready for reasoning",
                      style: UETypography.inter(
                        fontSize: 10,
                        color: Colors.purpleAccent,
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
          const SizedBox(height: 6),
          // Visual Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip("📐 Solve math / equation", "Solve and explain this math problem step by step with clear reasoning."),
                _buildQuickChip("🧬 Explain diagram", "Explain all labeled parts and principles shown in this diagram in detail."),
                _buildQuickChip("📝 Transcribe all text", "Read and transcribe all visible text, formulas, and labels in this image."),
                _buildQuickChip("🔍 Detailed analysis", "Analyze and summarize all key observations and data in this image."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        backgroundColor: UEColors.bgCard,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: _isGenerating ? null : () => _sendMessage(prompt),
      ),
    );
  }

  Widget _buildEmptyState(OfflineModelProvider modelProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: UEColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: UEColors.border, width: 0.5),
            ),
            child: const Icon(
              TablerIcons.sparkles,
              size: 32,
              color: UEColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'What would you like to research?',
            textAlign: TextAlign.center,
            style: UETypography.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: UEColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask any academic question or upload photos of diagrams, math problems, handwritten notes, and science charts for 100% offline multimodal analysis.',
            textAlign: TextAlign.center,
            style: UETypography.inter(
              fontSize: 13,
              color: UEColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Starter Action Cards
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ActionChip(
                avatar: const Icon(TablerIcons.photo_plus, size: 14, color: Colors.purpleAccent),
                label: const Text('📸 Upload diagram / photo to analyze'),
                onPressed: _pickImageFromDevice,
              ),
              ActionChip(
                avatar: const Icon(TablerIcons.math_function, size: 14, color: UEColors.indigo),
                label: const Text('📐 Explain Pythagorean Theorem'),
                onPressed: () => _sendMessage("Can you explain the Pythagorean theorem and provide step-by-step examples?"),
              ),
              ActionChip(
                avatar: const Icon(TablerIcons.dna, size: 14, color: Colors.greenAccent),
                label: const Text('🌿 How photosynthesis works'),
                onPressed: () => _sendMessage("Explain photosynthesis simply: what do plants need and what do they produce?"),
              ),
              ActionChip(
                avatar: const Icon(TablerIcons.language, size: 14, color: Colors.amberAccent),
                label: const Text('🇰🇪 Tofauti ya Nomino na Kitenzi'),
                onPressed: () => _sendMessage("Eleza tofauti iliyopo kati ya Nomino na Kitenzi katika sarufi ya Kiswahili."),
              ),
            ],
          ),
        ],
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
            color: UEColors.indigo.withOpacity(0.18),
            border: Border.all(color: UEColors.indigo.withOpacity(0.3), width: 0.5),
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
                      Text(
                        '• ${msg.latency!}',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                      ),
                    ],
                    const Spacer(),
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
                        SelectableText(
                          msg.text,
                          style: UETypography.inter(
                            fontSize: 14,
                            color: UEColors.textPrimary,
                            height: 1.5,
                          ),
                        ),

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
                        : (hasImage ? Colors.purpleAccent : UEColors.border),
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
                        color: hasImage ? Colors.purpleAccent : UEColors.textMuted,
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
                                : (hasImage ? Colors.purpleAccent.withOpacity(0.7) : UEColors.textMuted),
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
                backgroundColor: hasImage ? Colors.purple : (isEnabled && !_isGenerating ? UEColors.indigo : UEColors.surface),
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
