import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localgpt/providers/chat_provider.dart';
import 'package:localgpt/databases/ai_model_db.dart';
import 'package:provider/provider.dart';

class MessageBubble extends StatefulWidget {
  final String content;
  final bool isUser;
  final Future<void> Function(String newMessage)? onEdit;
  final Future<void> Function()? onRegenerate;

  const MessageBubble({
    required this.content,
    required this.isUser,
    this.onEdit,
    this.onRegenerate,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.isUser) {
      setState(() => _isEditing = true);
    }
  }

  void _sendEdit() async {
    if (!await context.read<AiModelDb>().isAnyModelLoaded()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Load a Model first")));
      return;
    }
    final newMessage = _controller.text.trim();
    if (newMessage.isNotEmpty && widget.onEdit != null) {
      await widget.onEdit!(newMessage);
    }

    setState(() => _isEditing = false);
  }

  Future<void> _regenerateMessage() async {
    debugPrint("regenerate clicked");
    if (!await context.read<AiModelDb>().isAnyModelLoaded()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Load a Model first")));
      return;
    }
    if (widget.onRegenerate != null) {
      await widget.onRegenerate!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _isEditing
            ? Container(
                alignment: widget.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isUser ? Colors.blueAccent : Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        style: TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendEdit(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                            },
                            child: Text(
                              "Calcel",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: _sendEdit,
                            child: Text(
                              "Send",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                alignment: widget.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isUser ? Colors.blueAccent : Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: SelectableText(
                    widget.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
        Row(
          mainAxisAlignment: widget.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: widget.isUser
                  ? IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.content));
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Copied")));
                      },
                      icon: Icon(Icons.copy),
                    )
                  : context.read<ChatProvider>().hasResponseCompleted
                  ? Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.content),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("Copied")));
                          },
                          icon: Icon(Icons.copy),
                        ),
                        IconButton(
                          onPressed: _regenerateMessage,
                          icon: Icon(Icons.loop),
                        ),
                      ],
                    )
                  : null,
            ),
            if (widget.isUser && !_isEditing)
              IconButton(onPressed: _startEditing, icon: Icon(Icons.edit)),
          ],
        ),
      ],
    );
  }
}
