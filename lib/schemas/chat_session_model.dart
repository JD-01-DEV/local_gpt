import 'package:isar/isar.dart';

part 'chat_session_model.g.dart';

@collection
class ChatSession {
  Id id = Isar.autoIncrement;

  late String modelUsed;
  late String title;
  late DateTime createdAt;

  final messages = IsarLinks<ChatMessage>(); // connect messages
}

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;
  late int sessionId;
  late bool isUser; // "user" or "assistant"
  late String content;
  late DateTime createdAt;
}
