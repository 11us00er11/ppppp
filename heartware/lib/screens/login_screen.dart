import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'survey_screen.dart';
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

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("아이디와 비밀번호를 모두 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://61.254.189.212:5000/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      print("응답 코드: ${response.statusCode}");
      print("응답 내용: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final userId = result['user_id'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => IntroScreenWithUser(userId: userId),
          ),
        );
      } else {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = result['message'] ?? "알 수 없는 오류가 발생했습니다.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: $errorMessage")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "아이디"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "비밀번호"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupScreen()),
                );
              },
              child: Text("회원가입이 필요하신가요?"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IntroScreenWithUser(userId: -1), // 비회원용 userId
                  ),
                );
              },
              child: Text("게스트로 시작하기"),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: Text("로그인"),
            ),
          ],
        ),
      ),
    );
  }
}