import 'package:flutter/material.dart';
import 'package:localgpt/providers/chat_provider.dart';
import 'package:localgpt/databases/ai_model_db.dart';
import 'package:localgpt/schemas/chat_session_model.dart';
import 'package:localgpt/services/api_service.dart';
import 'package:localgpt/widgets/message_bubble.dart';
import 'package:localgpt/widgets/model_options.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => __ChatScreenState();
}

class __ChatScreenState extends State<ChatScreen> {
  final FocusNode _focusNode = FocusNode(); // allows to focus on TextField
  final _messageController = TextEditingController(); // controller for messages
  final _messageScrollController =
      ScrollController(); // help to auto scroll when chat exceeds screen hieght
  final _chatScrollController = ScrollController();
  final _searchController =
      TextEditingController(); // helps to access TextField's properties and methods
  List<ChatSession> _searchResults = [];

  int? currentSessionId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    context.read<AiModelDb>().resetOnStartup();
  }

  // diposing / deleting controllers and focus variables when app closes
  @override
  void dispose() {
    _focusNode.dispose(); // removing focusNode when app closed
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose(); // deleting searchController
    _messageController.dispose(); // diposing _messageController
    _chatScrollController.dispose();
    _messageScrollController.dispose(); // same with scrollController

    super.dispose(); // calling dispose func of its parent class
  }

  double temperature = 0.5; // model temprature
  double topP = 0.8; // probabilty parameter for less bias and more creativity
  int maxTokens =
      512; // maximum tokens to limit leanth of output sequence by model

  bool isLoading = false;
  // bool _isInChatSession = false;

  // handles creating new chat
  void _newChat(ChatProvider chatProvider) {
    // initializing session with model and session name
    chatProvider.startNewSession();
    Navigator.pop(context); // closing drawer
  }

  void _scrollToBottom({bool force = false}) {
    if (_messageScrollController.hasClients) {
      final maxScroll = _messageScrollController.position.maxScrollExtent;

      _messageScrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
    } else {
      _searchChats(query);
    }
  }

  void _searchChats(String query) async {
    final results = await context.read<ChatProvider>().searchChats(query);
    setState(() {
      _searchResults = results;
    });
  }

  Future<void> _sendMessage(ChatProvider chatProvider) async {
    final aiModelDb = context.read<AiModelDb>();
    final String modelName = await aiModelDb.getActiveModelName();
    setState(() {
      chatProvider
          .sendMessage(true, _messageController.text, modelName)
          .then((_) => {setState(() => isLoading = false)});
      isLoading = true;
    });
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
    });
  }

  String exportAsText(List<ChatMessage> messages) {
    final buffer = StringBuffer();
    for (final m in messages) {
      buffer.writeln(m.isUser ? "User: ${m.content}" : "AI: ${m.content}");
      buffer.writeln(); // blank for line spaces
    }
    debugPrint(buffer.toString());
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(
      context,
    ); // getting chatProvider at the start of app
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),

                  onSubmitted: (query) => _searchChats(query),
                ),
              ),
            ),
            Expanded(
              child: _searchController.text.isNotEmpty
                  ? (_searchResults.isNotEmpty
                        ? ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final session = _searchResults[index];
                              return ListTile(
                                title: Text(session.title),
                                subtitle: Text(
                                  session.createdAt.toString().substring(0, 16),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  chatProvider.loadMessages(session.id);
                                },
                              );
                            },
                          )
                        : Center(child: Text("No Result found")))
                  : Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.chat_bubble_outline),
                          title: Text("New Chat"),
                          onTap: () => _newChat(chatProvider),
                        ),
                        ListTile(
                          leading: Icon(Icons.view_comfy_alt_outlined),
                          title: Text("Models"),
                          onTap: () =>
                              Navigator.pushNamed(context, '/model_manager'),
                        ),
                        ListTile(
                          leading: Icon(Icons.message),
                          title: Text("Chats"),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 20,
                            ),
                            child: ListView.builder(
                              controller: _chatScrollController,
                              itemCount: chatProvider.sessions.length,
                              itemBuilder: (context, index) {
                                final session = chatProvider.sessions[index];
                                return ListTile(
                                  title: Text(session.title),
                                  subtitle: Text(session.modelUsed),
                                  onTap: () {
                                    Navigator.pop(context);
                                    chatProvider.loadMessages(session.id);
                                  },
                                  trailing: IconButton(
                                    onPressed: () =>
                                        chatProvider.deleteSession(session.id),
                                    icon: Icon(Icons.delete),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    icon: Icon(Icons.settings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Center(child: Text("Local GPT")),
        actions: [
          IconButton(
            icon: MenuOptions(),
            onPressed: () => MenuOptions(
              onExport: () async {
                final messages = await chatProvider.getMessagesForSession(
                  currentSessionId,
                );
                if (messages == []) return;
                exportAsText(messages);
              },
            ),
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 15),
      ),
      body: Column(
        children: [
          Expanded(
            // child: ListView.builder(
            //   controller: _messageScrollController,
            //   itemCount: chatProvider.messages.length,
            //   itemBuilder: (context, index) {
            //     final msg = chatProvider.messages[index];
            //     if (index == chatProvider.messages.length - 1) {
            //       WidgetsBinding.instance.addPostFrameCallback((_) {
            //         _scrollToBottom(force: true);
            //       });
            //     }
            //     return MessageBubble(content: msg.content, isUser: msg.isUser);
            //   },
            // ),
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(force: true);
                });

                return ListView.builder(
                  controller: _messageScrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatProvider.messages[index];
                    return MessageBubble(
                      content: msg.content,
                      isUser: msg.isUser,
                      onEdit: msg.isUser
                          ? (newMessage) async {
                              context.read<ChatProvider>().editMessage(
                                msg.sessionId,
                                msg.id,
                                newMessage,
                              );
                              setState(() => isLoading = true);
                            }
                          : null,
                      onRegenerate: !msg.isUser
                          ? () async {
                              final db = context.read<ChatProvider>();

                              final messages = await db.getMessagesForSession(
                                msg.sessionId,
                              );
                              final index = messages.indexWhere(
                                (m) => m.id == msg.id,
                              );

                              if (index > 0) {
                                final userMessage = messages[index - 1];
                                final aiMessage = messages[index];

                                if (userMessage.isUser) {
                                  context.read<ChatProvider>().regenerate(
                                    userMessage.sessionId,
                                    userMessage.id,
                                    aiMessage.id,
                                    userMessage.content,
                                  );
                                  setState(() => isLoading = true);
                                }
                              }
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          GestureDetector(
            onTap: _focusNode.requestFocus,
            child: Container(
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(chatProvider),
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Ask any thing ...",
                        hintStyle: TextStyle(color: Colors.white24),
                        contentPadding: EdgeInsets.only(left: 25),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: isLoading
                        ? Icon(Icons.stop_circle_outlined, size: 30)
                        : Icon(Icons.send),
                    onPressed: () {
                      if (!isLoading ||
                          context.read<ChatProvider>().hasResponseCompleted) {
                        if (chatProvider.currentSessionId == null) {
                          chatProvider.startNewSessions(
                            "MyGGUFModel",
                            "Chat ${DateTime.now().toString().substring(0, 10)}",
                          );
                        }
                        _sendMessage(chatProvider);
                        currentSessionId = chatProvider.currentSessionId;
                      } else {
                        ApiService.stopStream();
                        setState(() => isLoading = false);
                      }
                    },
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
