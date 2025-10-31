import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:localgpt/schemas/chat_session_model.dart';

class ChatSessionDb extends ChangeNotifier {
  final Isar _isar;
  ChatSessionDb(this._isar);

  Future<List<ChatSession>> searchChats(String query) async {
    final q = query.toLowerCase();

    final sessionsByTitle = await _isar.chatSessions
        .filter()
        .titleContains(q, caseSensitive: false)
        .findAll();

    final results = <ChatSession>[];
    for (final s in sessionsByTitle) {
      results.add(s);
    }
    return results;
  }

  Future<int> createChatSession(String modelUsed, String title) async {
    final ChatSession chatSession = ChatSession()
      ..modelUsed = modelUsed
      ..title = title
      ..createdAt = DateTime.now();

    final id = await _isar.writeTxn(() async {
      return await _isar.chatSessions.put(chatSession);
    });
    notifyListeners();
    return id;
  }

  Future<List<ChatSession>> getAllChatSessions() async {
    return await _isar.chatSessions.where().sortByCreatedAtDesc().findAll();
  }

  Future<ChatSession?> getChatSession(int id) async {
    return await _isar.chatSessions.get(id);
  }

  Future<bool> deleteChatSession(int id) async {
    final session = await _isar.chatSessions.get(id);
    if (session == null) return false;

    await _isar.writeTxn(() async {
      await session.messages.load();
      for (var msg in session.messages) {
        await _isar.chatMessages.delete(msg.id);
      }

      await _isar.chatSessions.delete(id);
    });

    notifyListeners();
    return true;
  }

  Future<List<ChatMessage>> getSessionMessages(int sessionId) async {
    return await _isar.chatMessages
        .filter()
        .sessionIdEqualTo(sessionId)
        .sortByCreatedAt()
        .findAll();
  }
}
