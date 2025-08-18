import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String token;
  final String baseUrl = "http://<서버IP>:5000";

  ApiClient(this.token);

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers());
    return _decode(resp);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http.post(uri,
        headers: _headers(), body: jsonEncode(body ?? {}));
    return _decode(resp);
  }

  Future<void> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http.delete(uri, headers: _headers());
    _decode(resp);
  }

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  dynamic _decode(http.Response resp) {
    final json = jsonDecode(utf8.decode(resp.bodyBytes));
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(json['error'] ?? json['message'] ?? 'HTTP ${resp.statusCode}');
    }
    return json;
  }
}
