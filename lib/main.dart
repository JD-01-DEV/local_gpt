import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:localgpt/providers/chat_provider.dart';

import 'package:localgpt/databases/ai_model_db.dart';
import 'package:localgpt/schemas/chat_session_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:localgpt/databases/chat_message_db.dart';
import 'package:localgpt/databases/chat_session_db.dart';
import 'package:localgpt/schemas/ai_model_model.dart';
import 'package:localgpt/screens/model_manager_screen.dart';
import 'package:localgpt/screens/chat_screen.dart';
import 'package:localgpt/screens/settings_screen.dart';

late Isar isar; // creating Isar variable named isar

// it the main function that runs / starts the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ensuring that widgets are initialized

  final dir =
      await getApplicationSupportDirectory(); // getiing the directory in which Isar data will be stored
  // initializing Isar with schemas and storage path
  isar = await Isar.open([
    AiModelSchema,
    ChatSessionSchema,
    ChatMessageSchema,
  ], directory: dir.path);

  // this func is from material.dart which runs the app
  runApp(
    // defining MultiProvider that allows to use multiple provider in app
    MultiProvider(
      // list of providers
      providers: [
        // this type of provider helps to re-build/refresh widgets/UI when value in it changes
        ChangeNotifierProvider(
          create: (_) =>
              ChatProvider(
                  ChatSessionDb(isar),
                  ChatMessageDb(isar),
                ) // creating ChatSessionDb and ChatMessageDb which will have session and message infos
                ..loadSessions(), // calling loadSession function when creating ChatSessionDb so UI can Have previous session info
        ),
        ChangeNotifierProvider(
          // creating AiModelDb as well to handle model's list and other related
          create: (_) => AiModelDb(isar),
        ),
      ],
      child:
          const App(), // assinging APP as child to provider so it can be run by runApp function
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => ChatScreen(),
        '/settings': (context) => SettingsScreen(),
        '/model_manager': (context) => ModelManagerScreen(),
      },
    );
  }
}
