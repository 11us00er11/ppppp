import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:heartware/screens/intro_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();   // ← user_id
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
    final user_id = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (user_id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("아이디와 비밀번호를 모두 입력해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://61.254.189.212:5000/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": user_id,             // ✅ 통일
          "password": password,
        }),
      ).timeout(const Duration(seconds: 10));

      setState(() => _isLoading = false);

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        final String token = (body['token'] ?? '') as String;

        int userPk;        // DB PK (정수 id)
        String displayName;

        if (body['user'] != null) {
          final user = body['user'] as Map<String, dynamic>;
          userPk = (user['id'] as num).toInt();
          displayName = (user['user_name'] ?? user['user_id'] ?? user_id).toString();
        } else {
          // 서버가 user 블록 없이 보낼 경우 대비 (선택)
          userPk = (body['user_id'] as num?)?.toInt() ?? -1;
          final claims = _decodeJwtPayload(token);
          displayName = (claims['user_name'] ?? claims['user_id'] ?? user_id).toString();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => IntroScreenWithUser(
              user_id: userPk,
              displayName: displayName,
            ),
          ),
        );
      } else {
        final errorMessage = body['error'] ?? body['message'] ?? "알 수 없는 오류가 발생했습니다.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: $errorMessage")),
        );
      }
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
              controller: _userIdController,                  // ✅ user_id
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
                MaterialPageRoute(builder: (_) => IntroScreenWithUser(user_id: -1, displayName: null)),
              ),
              child: Text("게스트로 시작하기"),
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
