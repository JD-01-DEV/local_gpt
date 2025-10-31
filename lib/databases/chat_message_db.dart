import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:localgpt/schemas/chat_session_model.dart';

class ChatMessageDb extends ChangeNotifier {
  final Isar _isar;
  int? lastMessageId;
  ChatMessageDb(this._isar);

  Future<int> addMessageToSession(
    int sessionId,
    bool isUser,
    String content,
  ) async {
    final session = await _isar.chatSessions.get(sessionId);
    if (session == null) return -1;

    final message = ChatMessage()
      ..isUser = isUser
      ..sessionId = sessionId
      ..content = content
      ..createdAt = DateTime.now();

    return await _isar.writeTxn(() async {
      final id = await _isar.chatMessages.put(message);
      session.messages.add(message);
      await session.messages.save();
      notifyListeners();
      lastMessageId = id;
      return id;
    });
  }

  Future<ChatMessage> getLastMessage() async {
    final messages = await _isar.chatMessages.where().findAll();
    final msg = messages.last;
    return msg;
  }

  Future<List<ChatMessage>> getMessagesForSession(int sessionId) async {
    final session = await _isar.chatSessions.get(sessionId);
    if (session == null) return [];
    await session.messages.load();
    final list = session.messages.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<bool> updateMessageContent(int id, String newContent) async {
    return await _isar.writeTxn(() async {
      final msg = await _isar.chatMessages.get(id);
      if (msg == null) return false;
      msg.content = newContent;
      await _isar.chatMessages.put(msg);
      notifyListeners();
      return true;
    });
  }

  Future<bool> deleteMessage(int id) async {
    final deleted = await _isar.writeTxn(() async {
      return await _isar.chatMessages.delete(id);
    });
    if (deleted) notifyListeners();
    return deleted;
  }

  Future<void> deleteMessagesAfter(int sessionId, int messageId) async {
    final allMessages = await getMessagesForSession(sessionId);
    final idx = allMessages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final toDelete = allMessages.skip(idx + 1).map((m) => m.id).toList();

    if (toDelete.isNotEmpty) {
      await _isar.writeTxn(() async {
        for (final id in toDelete) {
          await _isar.chatMessages.delete(id);
        }
      });
      notifyListeners();
    }
  }
}
