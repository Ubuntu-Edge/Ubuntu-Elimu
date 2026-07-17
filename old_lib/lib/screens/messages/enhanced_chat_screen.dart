import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enhanced_message.dart';
import '../../services/audio_recording_service.dart';
import '../../services/location_sharing_service.dart';

/// Enhanced Chat Detail Screen with audio, images, location, and calls
class EnhancedChatScreen extends StatefulWidget {
  final EnhancedConversation conversation;

  const EnhancedChatScreen({super.key, required this.conversation});

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecordingService _audioService = AudioRecordingService();
  final LocationSharingService _locationService = LocationSharingService();
  final ImagePicker _imagePicker = ImagePicker();

  List<EnhancedMessage> _messages = [];
  bool _isRecording = false;
  int _recordingDuration = 0;
  bool _showAttachmentMenu = false;
  EnhancedMessage? _replyingTo;
  bool _isTyping = false;
  
  StreamSubscription<RecordingState>? _recordingSubscription;
  late AnimationController _attachmentAnimController;
  late Animation<double> _attachmentAnimation;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRecordingListener();
    _setupAnimations();
  }

  void _setupAnimations() {
    _attachmentAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentAnimController,
      curve: Curves.easeOut,
    );
  }

  void _setupRecordingListener() {
    _recordingSubscription = _audioService.recordingStateStream.listen((state) {
      setState(() {
        _isRecording = state.isRecording;
        _recordingDuration = state.duration;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recordingSubscription?.cancel();
    _attachmentAnimController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    final now = DateTime.now();
    
    // Sample messages with different types
    _messages = [
      EnhancedMessage(
        id: '1',
        senderId: 'other',
        senderName: widget.conversation.name,
        type: MessageType.text,
        textContent: 'Good morning! How are the visits going today?',
        timestamp: now.subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      EnhancedMessage(
        id: '2',
        senderId: 'me',
        senderName: 'Me',
        type: MessageType.text,
        textContent: 'Good morning! Going well so far. Completed 3 home visits.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
        status: MessageStatus.read,
      ),
      EnhancedMessage(
        id: '3',
        senderId: 'other',
        senderName: widget.conversation.name,
        type: MessageType.audio,
        mediaUrl: '/path/to/audio.m4a',
        mediaDuration: 15,
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.read,
      ),
      EnhancedMessage(
        id: '4',
        senderId: 'me',
        senderName: 'Me',
        type: MessageType.location,
        location: LocationData(
          latitude: -1.2921,
          longitude: 36.8219,
          address: 'Kibera Sector 5, Nairobi',
          placeName: 'Patient Home Visit',
        ),
        timestamp: now.subtract(const Duration(hours: 1)),
        status: MessageStatus.delivered,
      ),
      EnhancedMessage(
        id: '5',
        senderId: 'other',
        senderName: widget.conversation.name,
        type: MessageType.text,
        textContent: 'Great! Please follow up with the patient in Kibera sector 5.',
        timestamp: now.subtract(const Duration(minutes: 30)),
        status: MessageStatus.read,
      ),
      EnhancedMessage(
        id: '6',
        senderId: 'other',
        senderName: widget.conversation.name,
        type: MessageType.call,
        callData: CallData(
          type: CallType.voice,
          status: CallStatus.ended,
          duration: 180,
        ),
        timestamp: now.subtract(const Duration(minutes: 15)),
        status: MessageStatus.read,
      ),
    ];
    
    setState(() {});
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
    if (_showAttachmentMenu) {
      _attachmentAnimController.forward();
    } else {
      _attachmentAnimController.reverse();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    _toggleAttachmentMenu();
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1080,
      );
      
      if (image != null) {
        await _sendImageMessage(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showError('Failed to pick image');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await _sendDocumentMessage(
          filePath: file.path ?? '',
          fileName: file.name,
          fileSize: file.size,
        );
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      _showError('Failed to pick document');
    }
  }

  Future<void> _sendDocumentMessage({
    required String filePath,
    required String fileName,
    required int fileSize,
  }) async {
    // Format file size
    String formattedSize;
    if (fileSize < 1024) {
      formattedSize = '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      formattedSize = '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      formattedSize = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    
    final message = EnhancedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Me',
      type: MessageType.file,
      mediaUrl: filePath,
      textContent: '$fileName ($formattedSize)',
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessageId: _replyingTo?.id,
    );
    
    setState(() {
      _messages.add(message);
      _replyingTo = null;
    });
    
    _scrollToBottom();
    
    // Simulate sending
    await Future.delayed(const Duration(seconds: 1));
    _updateMessageStatus(message.id, MessageStatus.sent);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document sent: $fileName'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _sendImageMessage(String imagePath) async {
    final message = EnhancedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Me',
      type: MessageType.image,
      mediaUrl: imagePath,
      mediaThumbnailUrl: imagePath,
      textContent: null,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessageId: _replyingTo?.id,
    );
    
    setState(() {
      _messages.add(message);
      _replyingTo = null;
    });
    
    _scrollToBottom();
    
    // Simulate sending
    await Future.delayed(const Duration(seconds: 1));
    _updateMessageStatus(message.id, MessageStatus.sent);
  }

  Future<void> _shareLocation() async {
    _toggleAttachmentMenu();
    
    final l10n = AppLocalizations.of(context);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 16),
            Text(l10n.translate('gettingLocation') ?? 'Getting your location...'),
          ],
        ),
      ),
    );
    
    try {
      final location = await _locationService.getCurrentLocation();
      Navigator.pop(context); // Dismiss loading
      
      if (location != null) {
        _showLocationPreview(location);
      } else {
        _showError(l10n.translate('locationFailed') ?? 'Failed to get location');
      }
    } catch (e) {
      Navigator.pop(context);
      _showError('Location error: $e');
    }
  }

  void _showLocationPreview(LocationData location) {
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    l10n.translate('shareLocation') ?? 'Share Location',
                    style: AppTheme.headingSmall,
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: FaIcon(FontAwesomeIcons.xmark, size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.locationDot, 
                        color: AppColors.primary, 
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        location.placeName ?? location.address ?? 'Current Location',
                        style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendLocationMessage(location);
                  },
                  icon: FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                  label: Text(l10n.translate('sendLocation') ?? 'Send Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendLocationMessage(LocationData location) {
    final message = EnhancedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Me',
      type: MessageType.location,
      location: location,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessageId: _replyingTo?.id,
    );
    
    setState(() {
      _messages.add(message);
      _replyingTo = null;
    });
    
    _scrollToBottom();
    
    // Simulate sending
    Future.delayed(const Duration(seconds: 1), () {
      _updateMessageStatus(message.id, MessageStatus.sent);
    });
  }

  Future<void> _startRecording() async {
    final started = await _audioService.startRecording();
    if (!started) {
      _showError('Failed to start recording. Please check microphone permissions.');
    }
  }

  Future<void> _stopRecording() async {
    final result = await _audioService.stopRecording();
    if (result != null) {
      _sendAudioMessage(result.path, result.duration);
    }
  }

  void _cancelRecording() {
    _audioService.cancelRecording();
  }

  void _sendAudioMessage(String path, int duration) {
    final message = EnhancedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Me',
      type: MessageType.audio,
      mediaUrl: path,
      mediaDuration: duration,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessageId: _replyingTo?.id,
    );
    
    setState(() {
      _messages.add(message);
      _replyingTo = null;
    });
    
    _scrollToBottom();
    
    // Simulate sending
    Future.delayed(const Duration(seconds: 1), () {
      _updateMessageStatus(message.id, MessageStatus.sent);
    });
  }

  void _sendTextMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = EnhancedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Me',
      type: MessageType.text,
      textContent: _messageController.text.trim(),
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessageId: _replyingTo?.id,
    );
    
    setState(() {
      _messages.add(message);
      _replyingTo = null;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate sending
    Future.delayed(const Duration(seconds: 1), () {
      _updateMessageStatus(message.id, MessageStatus.sent);
    });
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: status);
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _initiateVoiceCall() {
    final l10n = AppLocalizations.of(context);
    _showCallDialog(
      l10n.translate('voiceCall') ?? 'Voice Call',
      CallType.voice,
    );
  }

  void _initiateVideoCall() {
    final l10n = AppLocalizations.of(context);
    _showCallDialog(
      l10n.translate('videoCall') ?? 'Video Call',
      CallType.video,
    );
  }

  void _showCallDialog(String title, CallType type) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                widget.conversation.name[0],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(title, style: AppTheme.headingSmall),
            SizedBox(height: 8),
            Text(
              widget.conversation.name,
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              l10n.translate('calling') ?? 'Calling...',
              style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCallActionButton(
                  FontAwesomeIcons.phoneSlash,
                  AppColors.error,
                  () {
                    Navigator.pop(context);
                    // Record missed/declined call
                    _recordCallEvent(type, CallStatus.declined, 0);
                  },
                ),
                if (type == CallType.video)
                  _buildCallActionButton(
                    FontAwesomeIcons.video,
                    AppColors.primary,
                    () {},
                    isActive: true,
                  ),
                _buildCallActionButton(
                  FontAwesomeIcons.microphone,
                  AppColors.primary,
                  () {},
                  isActive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : color,
          shape: BoxShape.circle,
        ),
        child: FaIcon(
          icon,
          color: isActive ? color : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _recordCallEvent(CallType type, CallStatus status, int duration) {
    final message = EnhancedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      senderName: 'Me',
      type: MessageType.call,
      callData: CallData(
        type: type,
        status: status,
        duration: duration,
        endTime: DateTime.now(),
      ),
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    
    setState(() {
      _messages.add(message);
    });
    
    _scrollToBottom();
  }

  void _setReplyTo(EnhancedMessage message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _clearReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showAttachmentMenu) _toggleAttachmentMenu();
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(AppTheme.spacingMd),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
              ),
            ),
          ),
          if (_showAttachmentMenu) _buildAttachmentMenu(l10n),
          if (_replyingTo != null) _buildReplyPreview(),
          _buildMessageInput(l10n),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: widget.conversation.isGroup 
                    ? FaIcon(FontAwesomeIcons.users, color: Colors.white, size: 12)
                    : Text(
                        widget.conversation.name[0], 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
              if (widget.conversation.isOnline && !widget.conversation.isGroup)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.name,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.conversation.onlineStatusText,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: FaIcon(FontAwesomeIcons.video, color: Colors.white, size: 18),
          onPressed: _initiateVideoCall,
        ),
        IconButton(
          icon: FaIcon(FontAwesomeIcons.phone, color: Colors.white, size: 18),
          onPressed: _initiateVoiceCall,
        ),
        IconButton(
          icon: FaIcon(FontAwesomeIcons.ellipsisVertical, color: Colors.white, size: 18),
          onPressed: () => _showChatOptions(l10n),
        ),
      ],
    );
  }

  void _showChatOptions(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.bellSlash, size: 18),
                title: Text(l10n.translate('muteConversation') ?? 'Mute Conversation'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.thumbtack, size: 18),
                title: Text(l10n.translate('pinConversation') ?? 'Pin Conversation'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                title: Text(l10n.translate('searchInChat') ?? 'Search in Chat'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.userGroup, size: 18),
                title: Text(l10n.translate('viewProfile') ?? 'View Profile'),
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentMenu(AppLocalizations l10n) {
    return FadeTransition(
      opacity: _attachmentAnimation,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              FontAwesomeIcons.camera,
              l10n.translate('camera') ?? 'Camera',
              AppColors.primary,
              () => _pickImage(ImageSource.camera),
            ),
            _buildAttachmentOption(
              FontAwesomeIcons.image,
              l10n.translate('gallery') ?? 'Gallery',
              AppColors.secondary,
              () => _pickImage(ImageSource.gallery),
            ),
            _buildAttachmentOption(
              FontAwesomeIcons.locationDot,
              l10n.translate('location') ?? 'Location',
              AppColors.info,
              _shareLocation,
            ),
            _buildAttachmentOption(
              FontAwesomeIcons.file,
              l10n.translate('document') ?? 'Document',
              AppColors.warning,
              () {
                _toggleAttachmentMenu();
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(label, style: AppTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _replyingTo!.senderName,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _replyingTo!.previewText,
                  style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.xmark, size: 16),
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _isRecording ? _buildRecordingUI() : _buildNormalInput(l10n),
      ),
    );
  }

  Widget _buildNormalInput(AppLocalizations l10n) {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleAttachmentMenu,
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _showAttachmentMenu 
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              _showAttachmentMenu ? FontAwesomeIcons.xmark : FontAwesomeIcons.plus,
              color: _showAttachmentMenu ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
          ),
        ),
        SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: l10n.translate('typeMessage') ?? 'Type a message...',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            minLines: 1,
            onChanged: (text) {
              setState(() {
                _isTyping = text.isNotEmpty;
              });
            },
            onSubmitted: (_) => _sendTextMessage(),
          ),
        ),
        SizedBox(width: AppTheme.spacingSm),
        if (_isTyping || _messageController.text.isNotEmpty)
          GestureDetector(
            onTap: _sendTextMessage,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 16),
            ),
          )
        else
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.microphone, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      children: [
        GestureDetector(
          onTap: _cancelRecording,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(FontAwesomeIcons.trash, color: AppColors.error, size: 16),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Text(
                AudioRecordingService.formatDuration(_recordingDuration),
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildWaveform(),
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: FaIcon(FontAwesomeIcons.stop, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    return Row(
      children: List.generate(20, (index) {
        final height = 8.0 + (index % 5) * 4.0 + (DateTime.now().millisecond % 10);
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMessageBubble(EnhancedMessage message) {
    final isMe = message.senderId == 'me';
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            bottom: AppTheme.spacingSm,
            left: isMe ? 60 : 0,
            right: isMe ? 0 : 60,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: _getMessagePadding(message),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                    bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildMessageContent(message, isMe),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsets _getMessagePadding(EnhancedMessage message) {
    switch (message.type) {
      case MessageType.image:
        return EdgeInsets.all(4);
      case MessageType.location:
        return EdgeInsets.all(8);
      default:
        return EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    }
  }

  Widget _buildMessageContent(EnhancedMessage message, bool isMe) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(message, isMe);
      case MessageType.audio:
        return _buildAudioMessage(message, isMe);
      case MessageType.image:
        return _buildImageMessage(message, isMe);
      case MessageType.location:
        return _buildLocationMessage(message, isMe);
      case MessageType.call:
        return _buildCallMessage(message, isMe);
      default:
        return _buildTextMessage(message, isMe);
    }
  }

  Widget _buildTextMessage(EnhancedMessage message, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          message.textContent ?? '',
          style: AppTheme.bodyMedium.copyWith(
            color: isMe ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        _buildMessageMeta(message, isMe),
      ],
    );
  }

  Widget _buildAudioMessage(EnhancedMessage message, bool isMe) {
    final duration = message.mediaDuration ?? 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _audioService.playAudio(message.mediaUrl ?? ''),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe 
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.play,
              color: isMe ? Colors.white : AppColors.primary,
              size: 14,
            ),
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: isMe 
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  AudioRecordingService.formatDuration(duration),
                  style: AppTheme.labelSmall.copyWith(
                    color: isMe 
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 8),
                _buildMessageMeta(message, isMe),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageMessage(EnhancedMessage message, bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: message.mediaUrl != null && File(message.mediaUrl!).existsSync()
              ? Image.file(
                  File(message.mediaUrl!),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: FaIcon(FontAwesomeIcons.image, color: Colors.grey),
                  ),
                ),
        ),
        if (message.textContent != null && message.textContent!.isNotEmpty) ...[
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              message.textContent!,
              style: AppTheme.bodySmall.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.only(top: 4, right: 8, bottom: 4),
          child: _buildMessageMeta(message, isMe),
        ),
      ],
    );
  }

  Widget _buildLocationMessage(EnhancedMessage message, bool isMe) {
    final location = message.location;
    if (location == null) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.locationDot,
                  color: AppColors.primary,
                  size: 32,
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    location.placeName ?? location.address ?? 'Shared Location',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: _buildMessageMeta(message, isMe),
        ),
      ],
    );
  }

  Widget _buildCallMessage(EnhancedMessage message, bool isMe) {
    final callData = message.callData;
    if (callData == null) return SizedBox.shrink();
    
    final isVideoCall = callData.type == CallType.video;
    final isMissed = callData.status == CallStatus.missed;
    final duration = callData.duration ?? 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMissed 
                ? AppColors.error.withValues(alpha: 0.1)
                : (isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1)),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            isVideoCall ? FontAwesomeIcons.video : FontAwesomeIcons.phone,
            color: isMissed ? AppColors.error : (isMe ? Colors.white : AppColors.primary),
            size: 14,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.previewText,
              style: AppTheme.bodySmall.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (duration > 0)
              Text(
                AudioRecordingService.formatDuration(duration),
                style: AppTheme.labelSmall.copyWith(
                  color: isMe 
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        SizedBox(width: 12),
        _buildMessageMeta(message, isMe),
      ],
    );
  }

  Widget _buildMessageMeta(EnhancedMessage message, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatMessageTime(message.timestamp),
          style: AppTheme.labelSmall.copyWith(
            color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        if (isMe) ...[
          SizedBox(width: 4),
          _buildStatusIcon(message.status, isMe),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(MessageStatus status, bool isMe) {
    IconData icon;
    Color color;
    
    switch (status) {
      case MessageStatus.sending:
      case MessageStatus.queued:
        icon = FontAwesomeIcons.clock;
        color = isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary;
        break;
      case MessageStatus.sent:
        icon = FontAwesomeIcons.check;
        color = isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary;
        break;
      case MessageStatus.delivered:
        icon = FontAwesomeIcons.checkDouble;
        color = isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary;
        break;
      case MessageStatus.read:
        icon = FontAwesomeIcons.checkDouble;
        color = isMe ? Colors.white : AppColors.info;
        break;
      case MessageStatus.failed:
        icon = FontAwesomeIcons.exclamationCircle;
        color = AppColors.error;
        break;
    }
    
    return FaIcon(icon, size: 10, color: color);
  }

  void _showMessageOptions(EnhancedMessage message) {
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.reply, size: 18),
                title: Text(l10n.translate('reply') ?? 'Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _setReplyTo(message);
                },
              ),
              ListTile(
                leading: FaIcon(FontAwesomeIcons.copy, size: 18),
                title: Text(l10n.translate('copy') ?? 'Copy'),
                onTap: () => Navigator.pop(context),
              ),
              if (message.senderId == 'me')
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.trash, size: 18, color: AppColors.error),
                  title: Text(
                    l10n.translate('delete') ?? 'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
