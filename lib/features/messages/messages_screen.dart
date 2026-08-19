import 'package:flutter/material.dart';
import 'package:shambadoc/app/theme.dart';
import 'package:shambadoc/services/api/message_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    final conversations = await MessageService.listConversations();
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No conversations yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(Icons.person_rounded, color: AppColors.primary),
                        ),
                        title: Text('User ${conv['other_user_id'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          conv['unread_count'] > 0
                              ? '${conv['unread_count']} unread messages'
                              : 'Last message',
                        ),
                        trailing: conv['unread_count'] > 0
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text('${conv['unread_count']}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
