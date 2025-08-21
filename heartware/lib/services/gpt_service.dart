// lib/services/gpt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GPTService {
  static const String baseUrl = "http://61.254.189.212:5000";
  // 게스트 허용: token을 선택적으로 받음
  static Future<String> sendMessage(String message, {String token = ''}) async {
    final uri = Uri.parse("$baseUrl/api/chat");
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final resp = await http
        .post(
      uri,
      headers: headers,
      body: jsonEncode({"message": message}),
    )
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      throw Exception("Chat API error (${resp.statusCode}): ${resp.body}");
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return (data["reply"] as String?) ?? "서버 응답 오류";
  }
}
