import 'dart:convert';
import 'package:http/http.dart' as http;

class GPTService {
  static const String _apiUrl = "http://localhost:5000/chat"; // 필요 시 수정

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"] ?? "응답 없음";
      } else {
        return "서버 오류: ${response.statusCode}";
      }
    } catch (e) {
      return "연결 실패: $e";
    }
  }
}
