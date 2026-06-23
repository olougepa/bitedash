import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final int orderId;
  const ChatScreen({required this.orderId, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  List<dynamic> _messages = [];
  bool _loading = false;
  late int _userId;

  @override
  void initState() {
    super.initState();
    _userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? 0;
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final msgs = await api.fetchChatsForOrder(widget.orderId, auth.token);
    setState(() => _messages = msgs ?? []);
    setState(() => _loading = false);
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final api = Provider.of<ApiService>(context, listen: false);
    await api.sendMessage(widget.orderId, _controller.text);
    _controller.clear();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i] as Map<String, dynamic>;
                    final isMe = msg['sender_id'] == _userId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color: isMe ? Colors.deepOrange : Colors.grey.shade200,
                        child: Padding(padding: const EdgeInsets.all(12), child: Text(msg['message'] ?? '')),
                      ),
                    );
                  },
                ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Type a message...'))),
            IconButton(icon: const Icon(Icons.send, color: Colors.deepOrange), onPressed: _sendMessage),
          ]),
        ),
      ]),
    );
  }
}