import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:heartware/screens/intro_screen.dart';
import 'signup_screen.dart';
import 'package:heartware/main.dart' show saveStoredToken, apiClient;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) normalized += '=';
      final payload = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _login() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("아이디와 비밀번호를 모두 입력해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resp = await http
          .post(
        Uri.parse("http://61.254.189.212:5000/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "password": password}),
      )
          .timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);

      Map<String, dynamic> body = {};
      try {
        body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {}

      if (resp.statusCode != 200) {
        final msg = (body['error'] ?? body['message'] ?? '로그인 실패').toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final token = (body['access_token'] ?? body['token'] ?? '') as String;
      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("토큰이 없습니다. 서버 응답을 확인하세요.")),
        );
        return;
      }

      int userPk = -1;

      if (body['user'] is Map) {
        final u = body['user'] as Map;
        final v = u['user_pk'];
        if (v is num) userPk = v.toInt();
        if (v is String) userPk = int.tryParse(v) ?? userPk;
      }

      if (userPk < 0) {
        final claims = _decodeJwtPayload(token);
        final v = claims['user_pk'];
        if (v is num) userPk = v.toInt();
        if (v is String) userPk = int.tryParse(v) ?? userPk;
      }

      if (userPk < 0 && token.isNotEmpty) userPk = 0;
      String displayName = userId;
      if (body['user'] is Map) {
        final u = body['user'] as Map;
        displayName = (u['user_name'] ?? u['user_id'] ?? displayName).toString();
      } else {
        final claims = _decodeJwtPayload(token);
        displayName =
            (claims['user_name'] ?? claims['user_id'] ?? displayName).toString();
      }

      await saveStoredToken(token);
      apiClient;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IntroScreenWithUser(
            user_id: userPk,
            displayName: displayName,
            token: token,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("서버에 연결할 수 없습니다. (에러: $e)")),
      );
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: "아이디"),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "비밀번호"),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen())),
              child: Text("회원가입이 필요하신가요?"),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => IntroScreenWithUser(
                    user_id: -1,
                    displayName: '게스트',
                    token: '',
                  ),
                ),
              ),
              child: const Text("게스트로 시작하기"),
            ),
            const SizedBox(height: 20),
            _isLoading ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text("로그인")),
          ],
        ),
      ),
    );
  }
}
