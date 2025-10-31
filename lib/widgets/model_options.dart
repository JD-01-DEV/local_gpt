import 'package:flutter/material.dart';
import 'package:localgpt/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class MenuOptions extends StatefulWidget {
  final VoidCallback? onExport;
  const MenuOptions({this.onExport, super.key});

  @override
  State<MenuOptions> createState() => _ModelOptionsState();
}

class _ModelOptionsState extends State<MenuOptions> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ),
        PopupMenuItem(
          value: 'model_manager',
          child: ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Model Manager'),
            onTap: () {
              Navigator.pushNamed(context, '/model_manager');
            },
          ),
        ),
        PopupMenuItem(
          value: 'new_chat',
          child: ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('New Chat'),
            onTap: () {
              context.read<ChatProvider>().startNewSession();
              Navigator.pop(context);
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.save_as),
            title: Text("Export Chat"),
            onTap: () => widget.onExport,
          ),
        ),
      ],
    );
  }
}
