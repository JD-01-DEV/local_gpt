import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:localgpt/databases/chat_message_db.dart';
import 'package:localgpt/databases/chat_session_db.dart';
import 'package:localgpt/schemas/chat_session_model.dart';
import 'package:localgpt/services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatSessionDb _chatSessionDb;
  final ChatMessageDb _chatMessageDb;

  List<ChatSession> sessions = [];
  List<ChatMessage> messages = [];
  int? currentSessionId;
  bool hasResponseCompleted = true;

  ChatProvider(this._chatSessionDb, this._chatMessageDb);

  Future<void> loadSessions() async {
    sessions = await _chatSessionDb.getAllChatSessions();
    for (var s in sessions) {
      debugPrint("Session ${s.id} -> ${s.title} (${s.modelUsed})");
    }
    notifyListeners();
  }

  Future<void> startNewSessions(String modelUsed, String title) async {
    currentSessionId = await _chatSessionDb.createChatSession(modelUsed, title);
    await loadSessions();
    messages = [];
    notifyListeners();
  }

  Future<void> loadMessages(int sessionId) async {
    messages = await _chatMessageDb.getMessagesForSession(sessionId);
    currentSessionId = sessionId;
    notifyListeners();
  }

  Future<void> sendMessage(
    bool isUser,
    String content,
    String modelName,
  ) async {
    if (content.trim().isEmpty) return;

    if (currentSessionId == null) {
      String title = "New Chat";
      try {
        title = await _generateTitle(content);
      } catch (_) {
        title = content.length > 30
            ? "${content.substring(0, 30)}..."
            : content;
      }
      currentSessionId = await _chatSessionDb.createChatSession(
        modelName,
        title,
      );
      await loadSessions();
    }
    final sid = currentSessionId!;
    final msgId = await _chatMessageDb.addMessageToSession(sid, true, content);
    await loadMessages(sid);

    final history = await getHistoryUpToMessage(sid, msgId);
    await _streamAssistantReply(sid, content, history);
    // await loadMessages(sid);
  }

  Future<void> _streamAssistantReply(
    int sessionId,
    String userText,
    List<Map<String, String>>? history,
  ) async {
    hasResponseCompleted = false;
    // create empty assistant message to update progressively
    final botId = await _chatMessageDb.addMessageToSession(
      sessionId,
      false,
      "",
    );
    final buffer = StringBuffer();

    final fullPrompt = history != null ? jsonEncode(history) : userText;

    await for (final chunk in ApiService.streamPrompt(fullPrompt)) {
      buffer.write(chunk);
      await _chatMessageDb.updateMessageContent(botId, buffer.toString());
      // Optional: avoid over-notifying; DB already notifies on update
      await loadMessages(sessionId);
    }
    hasResponseCompleted = true;
  }

  Future<void> deleteSession(int id) async {
    await _chatSessionDb.deleteChatSession(id);
    await loadSessions();
    if (currentSessionId == id) {
      currentSessionId = null;
      messages = [];
    }
    notifyListeners();
  }

  Future<void> startNewSession() async {
    currentSessionId = null; // reset so next message triggers a fresh session
    messages = [];
    notifyListeners();
  }

  Future<String> _generateTitle(String userText) async {
    // Ask the local AI to make a concise title
    final prompt =
        "Generate a short 3–5 word title for this conversation (make sure to not to response any other word than title):\n\n$userText";

    final buffer = StringBuffer();
    await for (final chunk in ApiService.streamPrompt(
      prompt,
      maxTokens: 1024,
    )) {
      buffer.write(chunk);
    }

    return buffer.toString().trim();
  }

  Future<List<ChatSession>> searchChats(String query) async {
    return _chatSessionDb.searchChats(query);
  }

  Future<List<Map<String, String>>> getHistoryUpToMessage(
    int sid,
    int mid,
  ) async {
    final msgs = await _chatMessageDb.getMessagesForSession(sid);

    final history = <Map<String, String>>[
      {"role": "system", "content": "You are a helpful assistant."},
    ];

    for (final m in msgs) {
      history.add({
        "role": m.isUser ? "user" : "assistant",
        "content": m.content,
      });
      if (m.id == mid) break;
    }
    return history;
  }

  Future<void> editMessage(int sid, int id, String newMessage) async {
    if (currentSessionId == null) return;

    await _chatMessageDb.updateMessageContent(id, newMessage);

    await _chatMessageDb.deleteMessagesAfter(sid, id);

    await loadMessages(sid);

    final history = await getHistoryUpToMessage(sid, id);

    await _streamAssistantReply(sid, newMessage, history);
  }

  Future<void> regenerate(int sid, int uId, int aiId, String message) async {
    if (currentSessionId == null) return;

    //await _chatMessageDb.updateMessageContent(uId, newMessage);

    await _chatMessageDb.deleteMessagesAfter(sid, uId);

    await loadMessages(sid);

    final history = await getHistoryUpToMessage(sid, uId);

    await _streamAssistantReply(sid, message, history);
  }

  Future<ChatMessage> getLastMessage() async {
    return await _chatMessageDb.getLastMessage();
  }

  Future<List<ChatMessage>> getMessagesForSession(int? sessionId) async {
    if (sessionId == null) return [];
    return await _chatMessageDb.getMessagesForSession(sessionId);
  }
}
