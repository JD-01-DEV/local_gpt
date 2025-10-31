import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String server =
      "http://localhost:8000"; // defining server adress

  // Optional: a non-streaming helper that just collects the streamed text
  static Future<String> sendPrompt(
    String prompt, {
    double temperature = 0.7,
    double topP = 0.9,
    int maxTokens = 256,
  }) async {
    final buffer =
        StringBuffer(); // creating string buffer that helps in buffering response
    // func that extract chunck ( small part of text ) from response and returns buffered text
    await for (final chunk in streamPrompt(
      prompt,
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
    )) {
      buffer.write(chunk); // Writes the string representation of [object].
    }
    return buffer.toString(); // converting StringBuffer to String
  }

  // func that streams
  static Stream<String> streamPrompt(
    String prompt, {
    double temperature = 0.7,
    double topP = 0.9,
    int maxTokens = 256,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request("POST", Uri.parse("$server/chat"));
      request.headers["Content-Type"] = "application/json";
      request.body = json.encode({
        "prompt": prompt,
        "temperature": temperature,
        "top_p": topP,
        "max_tokens": maxTokens,
      });

      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          yield chunk; // server streams plain text tokens
        }
      } else {
        yield "Server Error: ${response.statusCode}";
      }
    } finally {
      client.close();
    }
  }

  static Future<bool> loadModel(String path) async {
    try {
      final res = await http.post(
        Uri.parse("$server/load_model"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"model_path": path}),
      );
      final data = json.decode(res.body);
      return data["status"] == "success";
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unloadModel() async {
    try {
      final res = await http.post(
        Uri.parse("$server/unload_model"),
        headers: {"Content-Type": "application/json"},
      );
      final data = json.decode(res.body);
      return data["status"] == "success";
    } catch (_) {
      return false;
    }
  }

  static Future<void> stopStream() async {
    await http.post(Uri.parse("$server/stop"));
  }
}
