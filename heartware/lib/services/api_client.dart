// api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final TokenProvider tokenProvider;
  final String baseUrl;

  ApiClient({required this.tokenProvider, required this.baseUrl});

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    print('[ApiClient] GET $uri');
    final resp = await http.get(uri, headers: await _headers());
    return _decode(resp);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http.post(uri, headers: await _headers(), body: jsonEncode(body ?? {}));
    return _decode(resp);
  }

  Future<void> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http.delete(uri, headers: await _headers());
    _decode(resp);
  }

  Future<Map<String, String>> _headers() async {
    final t = await tokenProvider();
    print('[ApiClient] token? ${t != null && t.isNotEmpty}');
    return {
      'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  dynamic _decode(http.Response resp) {
    // body가 비어도 안전하게
    final bodyStr = (resp.bodyBytes.isEmpty) ? '{}' : utf8.decode(resp.bodyBytes);
    final json = jsonDecode(bodyStr);
    if (resp.statusCode == 401) {
      throw UnauthorizedException(json['message'] ?? 'Unauthorized');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(json['error'] ?? json['message'] ?? 'HTTP ${resp.statusCode}');
    }
    return json;
  }
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => message;
}
