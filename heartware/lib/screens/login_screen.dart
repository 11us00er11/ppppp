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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ✅ jwt_decoder 패키지 없이 payload 파싱하는 헬퍼
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      // Base64 패딩 보정
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final payload = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
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
        body: jsonEncode({"username": username, "password": password}),
      );

      setState(() => _isLoading = false);

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      print("응답 코드: ${response.statusCode}");
      print("응답 내용: $body");

      if (response.statusCode == 200) {
        final String token = (body['token'] ?? '') as String;

        int userId;
        String? displayName;

        if (body['user'] != null) {
          // ✅ 서버가 user 객체를 함께 주는 경우
          final user = body['user'] as Map<String, dynamic>;
          userId = (user['id'] as num).toInt();
          displayName = (user['name'] ?? user['username'])?.toString();
        } else {
          // ✅ 서버가 user_id만 주는 경우: 토큰에서 클레임 추출
          userId = (body['user_id'] as num?)?.toInt() ?? -1;
          final claims = _decodeJwtPayload(token);
          displayName = (claims['name'] ?? claims['username'])?.toString();
        }

        displayName ??= username; // 폴백

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => IntroScreenWithUser(
              userId: userId,
              displayName: displayName, // 👈 인사말 전달
            ),
          ),
        );
      } else {
        final errorMessage = body['message'] ?? "알 수 없는 오류가 발생했습니다.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: $errorMessage")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("서버에 연결할 수 없습니다. (에러: $e)")),
      );
      print("로그인 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _usernameController, decoration: InputDecoration(labelText: "아이디")),
            TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: "비밀번호")),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen())),
              child: Text("회원가입이 필요하신가요?"),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => IntroScreenWithUser(userId: -1, displayName: null)),
              ),
              child: Text("게스트로 시작하기"),
            ),
            SizedBox(height: 20),
            _isLoading ? CircularProgressIndicator() : ElevatedButton(onPressed: _login, child: Text("로그인")),
          ],
        ),
      ),
    );
  }
}
