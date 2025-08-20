// lib/services/gpt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GPTService {
  // 서버가 /api 프리픽스를 쓰므로 baseUrl은 /api로 끝나게 유지
  static const String baseUrl = "http://61.254.189.212:5000/api";

  // 게스트 허용: token을 선택적으로 받음
  static Future<String> sendMessage(String message, {String token = ''}) async {
    // ✅ /api 중복 금지 → /chat 만 붙임
    final uri = Uri.parse("$baseUrl/chat");

    // ✅ 토큰이 있을 때만 Authorization 헤더 추가
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
    // ✅ 무한대기 방지
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) {
      // 서버 에러 본문을 그대로 보여주면 디버깅이 쉬움
      throw Exception("Chat API error (${resp.statusCode}): ${resp.body}");
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return (data["reply"] as String?) ?? "서버 응답 오류";
  }
}
