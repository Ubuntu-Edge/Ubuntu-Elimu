import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/patient.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../services/database_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  final Patient patient;

  const ChatHistoryScreen({super.key, required this.patient});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  Map<String, List<ChatMessage>> _sessionGroups = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    setState(() => _isLoading = true);
    
    final allMessages = await _dbService.getChatMessagesByPatient(widget.patient.id);
    
    // Group messages by session ID
    final Map<String, List<ChatMessage>> groups = {};
    for (var message in allMessages) {
      if (!groups.containsKey(message.sessionId)) {
        groups[message.sessionId] = [];
      }
      groups[message.sessionId]!.add(message);
    }
    
    // Sort messages within each session
    for (var sessionMessages in groups.values) {
      sessionMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    
    setState(() {
      _sessionGroups = groups;
      _isLoading = false;
    });
  }

  String _getSessionPreview(List<ChatMessage> messages) {
    final userMessages = messages.where((m) => m.sender == 'You').toList();
    if (userMessages.isEmpty) return 'Empty conversation';
    
    final firstMessage = userMessages.first.message;
    return firstMessage.length > 60 
      ? '${firstMessage.substring(0, 60)}...' 
      : firstMessage;
  }

  String _getSessionTime(List<ChatMessage> messages) {
    if (messages.isEmpty) return '';
    
    final latestMessage = messages.reduce((a, b) => 
      a.timestamp.isAfter(b.timestamp) ? a : b
    );
    
    final now = DateTime.now();
    final diff = now.difference(latestMessage.timestamp);
    
    if (diff.inDays > 7) {
      return '${latestMessage.timestamp.day}/${latestMessage.timestamp.month}/${latestMessage.timestamp.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  int _getMessageCount(List<ChatMessage> messages) {
    return messages.where((m) => m.sender == 'You').length;
  }

  void _loadSession(String sessionId) {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.loadSpecificSession(widget.patient.id, sessionId);
    Navigator.pop(context);
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteChatSession(sessionId);
      await _loadChatSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History - ${widget.patient.displayId}'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _sessionGroups.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No chat history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _sessionGroups.length,
              itemBuilder: (context, index) {
                final sessionId = _sessionGroups.keys.elementAt(index);
                final messages = _sessionGroups[sessionId]!;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(
                        '${_getMessageCount(messages)}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    title: Text(
                      _getSessionPreview(messages),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      _getSessionTime(messages),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteSession(sessionId),
                    ),
                    onTap: () => _loadSession(sessionId),
                  ),
                );
              },
            ),
    );
  }
}
