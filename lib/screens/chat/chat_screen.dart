import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/model_selector.dart';
import '../../widgets/sidebar_drawer.dart';
import '../auth/login_webview_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  String _selectedModel = 'gpt-4';
  bool _isLoading = false;
  bool _isStreaming = false;
  String _streamingMessage = '';

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final models = await _apiClient.getModels();
      if (models.isNotEmpty && mounted) {
        setState(() {
          _selectedModel = models[0]['id'] ?? 'gpt-4';
        });
      }
    } catch (e) {
      print('Error loading models: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isStreaming) return;

    setState(() {
      _messages.add(ChatMessage(content: message, isUser: true));
      _messageController.clear();
      _isStreaming = true;
      _streamingMessage = '';
    });

    _scrollToBottom();

    try {
      await for (var chunk in _apiClient.sendMessageStream(message, _selectedModel)) {
        setState(() {
          _streamingMessage += chunk;
        });
        _scrollToBottom();
      }

      if (_streamingMessage.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(content: _streamingMessage, isUser: false));
          _streamingMessage = '';
        });
      }
    } catch (e) {
      if (e.toString().contains('Authentication failed')) {
        _handleAuthError();
      } else {
        _showError('Failed to send message: $e');
      }
    } finally {
      setState(() {
        _isStreaming = false;
      });
      _scrollToBottom();
    }
  }

  void _handleAuthError() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginWebViewScreen(
          onLoginSuccess: (token) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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

  void _newChat() {
    setState(() {
      _messages.clear();
      _streamingMessage = '';
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: ModelSelector(
          selectedModel: _selectedModel,
          onModelChanged: (model) {
            setState(() => _selectedModel = model);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _newChat,
            tooltip: 'New Chat',
          ),

          /// 🔒 UPDATED LOGOUT BUTTON (confirmation dialog)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await _authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LoginWebViewScreen(
                      onLoginSuccess: (token) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        );
                      },
                    ),
                  ),
                  (route) => false,
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: const SidebarDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isStreaming
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: _messages.length + (_isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        final message = _messages[index];
                        return MessageBubble(
                          message: message.content,
                          isUser: message.isUser,
                        );
                      } else {
                        return MessageBubble(
                          message: _streamingMessage.isEmpty ? '...' : _streamingMessage,
                          isUser: false,
                          isStreaming: true,
                          modelName: _selectedModel,
                        );
                      }
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message Eden AI...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.blue.shade600),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: _isStreaming ? Colors.grey.shade300 : Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isStreaming ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _isStreaming ? Icons.stop : Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({required this.content, required this.isUser});
}
