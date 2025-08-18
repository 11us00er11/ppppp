// lib/services/gpt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GPTService {
  static const String baseUrl = "http://61.254.189.212:5000";

  static Future<String> sendMessage(String message, {required String token}) async {
    final uri = Uri.parse("$baseUrl/api/chat");
    final resp = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // ✅ JWT 추가
      },
      body: jsonEncode({"message": message}),
    );

    if (resp.statusCode != 200) {
      throw Exception("Chat API error: ${resp.body}");
    }

    final json = jsonDecode(utf8.decode(resp.bodyBytes));
    return json["reply"] ?? "서버 응답 오류";
  }
}
