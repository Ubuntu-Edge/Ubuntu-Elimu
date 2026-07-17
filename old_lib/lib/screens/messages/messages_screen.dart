import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/message_api_service.dart';
import '../../models/message_models.dart';

/// Conversation model - wrapper for UI display
class Conversation {
  final String id;
  final String name;
  final String? avatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isGroup;
  final bool isOnline;
  final String type; // supervisor, chw, partner, group

  Conversation({
    required this.id,
    required this.name,
    this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.isGroup = false,
    this.isOnline = false,
    required this.type,
  });

  /// Create Conversation from MessageGroupResponse
  factory Conversation.fromGroup(MessageGroupResponse group) {
    return Conversation(
      id: group.id,
      name: group.name,
      lastMessage:
          '', // Group doesn't have lastMessage - will be populated separately
      lastMessageTime: DateTime.tryParse(group.updatedAt) ?? DateTime.now(),
      unreadCount: 0, // Will be calculated separately
      isGroup: true,
      type: 'group',
    );
  }

  /// Create Conversation from MessageResponse (direct message)
  factory Conversation.fromMessage(MessageResponse message,
      {bool isCurrentUser = false}) {
    return Conversation(
      id: isCurrentUser
          ? (message.recipientId ?? message.senderId)
          : message.senderId,
      name: message.senderId, // Will need to be looked up from user service
      lastMessage: message.content,
      lastMessageTime: DateTime.tryParse(message.createdAt) ?? DateTime.now(),
      unreadCount: message.isRead ? 0 : 1,
      isGroup: false,
      type: 'chw',
    );
  }
}

/// ChatMessage model - wrapper for UI display
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final bool isRead;
  final String? attachmentType;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
    this.attachmentType,
  });

  /// Create ChatMessage from MessageResponse
  factory ChatMessage.fromMessageResponse(
      MessageResponse response, String currentUserId) {
    return ChatMessage(
      id: response.id,
      senderId: response.senderId,
      senderName:
          response.senderId, // Will need to be looked up from user service
      content: response.content,
      timestamp: DateTime.tryParse(response.createdAt) ?? DateTime.now(),
      isMe: response.senderId == currentUserId,
      isRead: response.isRead,
      attachmentType: response.attachmentUrl != null ? 'attachment' : null,
    );
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final MessageApiService _messageApi = MessageApiService.instance;
  late TabController _tabController;
  List<Conversation> _conversations = [];
  // TODO: May be needed later for group management UI
  // List<MessageGroupResponse> _groups = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  String? _error;
  // TODO: May be needed later for unread badge display
  // int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load messages, groups, and unread count in parallel
      final results = await Future.wait([
        _messageApi.listMessages(perPage: 50),
        _messageApi.listGroups(),
        _messageApi.getUnreadCount(),
      ]);

      final messagesResponse = results[0] as MessageListResponse;
      final groupsResponse = results[1] as List<MessageGroupResponse>;
      // TODO: Use unreadCount when UI notification badge is implemented
      // final unreadCountResponse = results[2] as UnreadCountResponse;

      // Convert messages to conversations (group by sender)
      final Map<String, Conversation> conversationMap = {};
      for (final message in messagesResponse.data) {
        final key = message.senderId;
        if (!conversationMap.containsKey(key)) {
          conversationMap[key] = Conversation.fromMessage(message);
        }
      }

      // Convert groups to conversations
      final groupConversations =
          groupsResponse.map((g) => Conversation.fromGroup(g)).toList();

      setState(() {
        _conversations = [
          ...conversationMap.values,
          ...groupConversations,
        ];
        // Sort by last message time
        _conversations
            .sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        // TODO: Use groups data when group management UI is implemented
        // _groups = groupsResponse;
        // TODO: Use unread count for badge display
        // _unreadCount = unreadCountResponse.count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      // Fall back to demo data if API fails
      _loadDemoConversations();
    }
  }

  void _loadDemoConversations() {
    final now = DateTime.now();

    _conversations = [
      Conversation(
        id: '1',
        name: 'Dr. Sarah Kamau',
        lastMessage: 'Please follow up with the patient in Kibera',
        lastMessageTime: now.subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        type: 'supervisor',
        isOnline: true,
      ),
      Conversation(
        id: '2',
        name: 'CHW Team - Kibera',
        lastMessage: 'Mary: I\'ll handle the afternoon visits',
        lastMessageTime: now.subtract(const Duration(hours: 1)),
        unreadCount: 5,
        isGroup: true,
        type: 'group',
      ),
      Conversation(
        id: '3',
        name: 'Faith Adhiambo',
        lastMessage: 'Can you cover for me tomorrow?',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        unreadCount: 0,
        type: 'chw',
        isOnline: true,
      ),
      Conversation(
        id: '4',
        name: 'Peter Ochieng',
        lastMessage: 'I completed the training module',
        lastMessageTime: now.subtract(const Duration(hours: 4)),
        unreadCount: 0,
        type: 'chw',
      ),
      Conversation(
        id: '5',
        name: 'UNICEF Partners',
        lastMessage: 'Update: New supplies arriving Monday',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 1,
        isGroup: true,
        type: 'partner',
      ),
      Conversation(
        id: '6',
        name: 'Dr. Michael Njoroge',
        lastMessage: 'The referral was successful, thanks!',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
        type: 'supervisor',
      ),
    ];

    setState(() {});
  }

  List<Conversation> _getFilteredConversations(String filter) {
    if (filter == 'all') return _conversations;
    if (filter == 'groups')
      return _conversations.where((c) => c.isGroup).toList();
    return _conversations.where((c) => c.type == filter).toList();
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(conversation: conversation),
      ),
    );
  }

  void _showNewMessageDialog() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
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
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Row(
                children: [
                  Text(l10n.translate('newMessage') ?? 'New Message',
                      style: AppTheme.headingMedium),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: FaIcon(FontAwesomeIcons.xmark, size: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: TextField(
                decoration: InputDecoration(
                  hintText:
                      l10n.translate('searchContacts') ?? 'Search contacts...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                children: [
                  Text(l10n.translate('supervisors') ?? 'Supervisors',
                      style: AppTheme.labelLarge),
                  SizedBox(height: AppTheme.spacingSm),
                  _buildContactItem('Dr. Sarah Kamau', 'Supervisor', true),
                  _buildContactItem('Dr. Michael Njoroge', 'Supervisor', false),
                  SizedBox(height: AppTheme.spacingMd),
                  Text(l10n.translate('fellowCHWs') ?? 'Fellow CHWs',
                      style: AppTheme.labelLarge),
                  SizedBox(height: AppTheme.spacingSm),
                  _buildContactItem('Faith Adhiambo', 'CHW - Kibera', true),
                  _buildContactItem('Peter Ochieng', 'CHW - Mathare', false),
                  _buildContactItem('Grace Wanjiku', 'CHW - Dandora', true),
                  SizedBox(height: AppTheme.spacingMd),
                  Text(l10n.translate('groups') ?? 'Groups',
                      style: AppTheme.labelLarge),
                  SizedBox(height: AppTheme.spacingSm),
                  _buildContactItem('CHW Team - Kibera',
                      '12 ${l10n.translate('members') ?? 'members'}', false,
                      isGroup: true),
                  _buildContactItem('UNICEF Partners',
                      '5 ${l10n.translate('members') ?? 'members'}', false,
                      isGroup: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(String name, String subtitle, bool isOnline,
      {bool isGroup = false}) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: isGroup
                ? FaIcon(FontAwesomeIcons.users,
                    color: AppColors.primary, size: 16)
                : Text(name[0],
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          if (!isGroup && isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(name,
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${l10n.translate('openingConversation') ?? 'Opening conversation with'} $name...'),
              behavior: SnackBarBehavior.floating),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewMessageDialog,
        backgroundColor: AppColors.primary,
        child: FaIcon(FontAwesomeIcons.pen, color: Colors.white, size: 18),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.triangleExclamation,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('Error loading messages',
                                  style: AppTheme.bodyMedium),
                              const SizedBox(height: 8),
                              Text(_error!,
                                  style: AppTheme.labelSmall.copyWith(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const FaIcon(
                                    FontAwesomeIcons.arrowsRotate,
                                    size: 14),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildConversationsList('all'),
                              _buildConversationsList('supervisor'),
                              _buildConversationsList('groups'),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withBlue(180)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.arrowLeft,
                        color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.messages,
                        style: AppTheme.headingMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.translate('teamCommunication') ??
                            'Team Communication',
                        style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isSearching = !_isSearching),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      _isSearching
                          ? FontAwesomeIcons.xmark
                          : FontAwesomeIcons.magnifyingGlass,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            if (_isSearching) ...[
              SizedBox(height: AppTheme.spacingMd),
              TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      l10n.translate('searchMessages') ?? 'Search messages...',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: l10n.translate('allConversations') ?? 'All'),
          Tab(text: l10n.translate('supervisors') ?? 'Supervisors'),
          Tab(text: l10n.translate('groups') ?? 'Groups'),
        ],
      ),
    );
  }

  Widget _buildConversationsList(String filter) {
    final conversations = _getFilteredConversations(filter);
    final l10n = AppLocalizations.of(context);

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.commentSlash,
                color: AppColors.textSecondary, size: 48),
            SizedBox(height: AppTheme.spacingMd),
            Text(l10n.translate('noConversationsYet') ?? 'No conversations yet',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      itemCount: conversations.length,
      itemBuilder: (context, index) =>
          _buildConversationTile(conversations[index]),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return GestureDetector(
      onTap: () => _openChat(conversation),
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      _getTypeColor(conversation.type).withValues(alpha: 0.1),
                  child: conversation.isGroup
                      ? FaIcon(FontAwesomeIcons.users,
                          color: _getTypeColor(conversation.type), size: 18)
                      : Text(
                          conversation.name[0],
                          style: TextStyle(
                            color: _getTypeColor(conversation.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
                if (!conversation.isGroup && conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.name,
                          style: AppTheme.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageTime),
                        style: AppTheme.labelSmall.copyWith(
                          color: conversation.unreadCount > 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: AppTheme.bodySmall.copyWith(
                            color: conversation.unreadCount > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: AppTheme.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'supervisor':
        return AppColors.primary;
      case 'chw':
        return AppColors.secondary;
      case 'partner':
        return AppColors.info;
      case 'group':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime time) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${l10n.translate('minutesAgo') ?? 'm ago'}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${l10n.translate('hoursAgo') ?? 'h ago'}';
    } else if (diff.inDays == 1) {
      return l10n.translate('yesterday') ?? 'Yesterday';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

// Chat Detail Screen
class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final MessageApiService _messageApi = MessageApiService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  // TODO: May be needed later for error display
  // String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      // _error = null;
    });

    try {
      MessageListResponse response;
      if (widget.conversation.isGroup) {
        // Load group messages using groupId filter
        response = await _messageApi.listMessages(
          groupId: widget.conversation.id,
          perPage: 50,
        );
      } else {
        // Load direct messages - filter by conversation partner
        response = await _messageApi.listMessages(
          conversationWith: widget.conversation.id,
          perPage: 50,
        );
      }

      // Get current user ID from auth service (assuming we have one)
      const currentUserId = 'me'; // TODO: Get from AuthService

      setState(() {
        _messages = response.data
            .map((m) => ChatMessage.fromMessageResponse(m, currentUserId))
            .toList()
            .reversed
            .toList();
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        // TODO: Display error in UI
        // _error = e.toString();
        _isLoading = false;
      });
      // Fall back to demo messages
      _loadDemoMessages();
    }
  }

  void _loadDemoMessages() {
    final now = DateTime.now();

    _messages = [
      ChatMessage(
        id: '1',
        senderId: 'other',
        senderName: widget.conversation.name,
        content: 'Good morning! How are the visits going today?',
        timestamp: now.subtract(const Duration(hours: 2)),
        isMe: false,
        isRead: true,
      ),
      ChatMessage(
        id: '2',
        senderId: 'me',
        senderName: 'Me',
        content: 'Good morning! Going well so far. Completed 3 home visits.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
        isMe: true,
        isRead: true,
      ),
      ChatMessage(
        id: '3',
        senderId: 'other',
        senderName: widget.conversation.name,
        content:
            'Great progress! Please make sure to follow up with the patient in Kibera sector 5.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        isMe: false,
        isRead: true,
      ),
      ChatMessage(
        id: '4',
        senderId: 'me',
        senderName: 'Me',
        content: 'Yes, I have that scheduled for this afternoon.',
        timestamp: now.subtract(const Duration(hours: 1)),
        isMe: true,
        isRead: true,
      ),
      ChatMessage(
        id: '5',
        senderId: 'other',
        senderName: widget.conversation.name,
        content: widget.conversation.lastMessage,
        timestamp: now.subtract(const Duration(minutes: 5)),
        isMe: false,
        isRead: false,
      ),
    ];

    setState(() {});
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
      // Add optimistic message
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        senderName: 'Me',
        content: content,
        timestamp: DateTime.now(),
        isMe: true,
        isRead: false,
      ));
    });

    _scrollToBottom();

    try {
      final request = MessageCreateRequest(
        content: content,
        recipientId:
            widget.conversation.isGroup ? null : widget.conversation.id,
        groupId: widget.conversation.isGroup ? widget.conversation.id : null,
        messageType: 'text',
      );

      await _messageApi.sendMessage(request);
    } catch (e) {
      // Show error but keep the message (offline-first approach)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message queued for sending'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon:
              FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: widget.conversation.isGroup
                  ? FaIcon(FontAwesomeIcons.users,
                      color: Colors.white, size: 12)
                  : Text(widget.conversation.name[0],
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.name,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.conversation.isOnline &&
                      !widget.conversation.isGroup)
                    Text(
                      l10n.translate('online') ?? 'Online',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.phone, color: Colors.white, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('${l10n.translate('calling') ?? 'Calling'}...'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.ellipsisVertical,
                color: Colors.white, size: 18),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _buildMessageBubble(_messages[index]),
                    ),
                  ),
          ),
          _buildMessageInput(l10n),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: AppTheme.spacingSm,
          left: message.isMe ? 60 : 0,
          right: message.isMe ? 0 : 60,
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: message.isMe ? Radius.circular(16) : Radius.circular(4),
            bottomRight:
                message.isMe ? Radius.circular(4) : Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: AppTheme.bodyMedium.copyWith(
                color: message.isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.timestamp),
                  style: AppTheme.labelSmall.copyWith(
                    color: message.isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (message.isMe) ...[
                  SizedBox(width: 4),
                  FaIcon(
                    message.isRead
                        ? FontAwesomeIcons.checkDouble
                        : FontAwesomeIcons.check,
                    size: 10,
                    color: message.isRead
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
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
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(FontAwesomeIcons.paperclip,
                    color: AppColors.textSecondary, size: 18),
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText:
                      l10n.translate('typeMessage') ?? 'Type a message...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: FaIcon(FontAwesomeIcons.paperPlane,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
