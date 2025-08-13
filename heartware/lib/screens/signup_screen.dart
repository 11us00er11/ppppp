import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _userIdController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  bool _validName(String s) {
    final re = RegExp(r'^[A-Za-z가-힣\s\-]{2,30}$');
    return re.hasMatch(s.trim());
  }

  Future<void> _signup() async {
    final user_id = _userIdController.text.trim();
    final user_name = _userNameController.text.trim();
    final password = _passwordController.text.trim();

    if (user_id.isEmpty || user_name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("아이디, 이름, 비밀번호를 모두 입력해주세요.")),
      );
      return;
    }
    if (!_validName(user_name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이름 형식이 올바르지 않습니다. (2~30자, 한글/영문/공백/하이픈)")),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("비밀번호는 8자 이상으로 설정해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resp = await http
          .post(
        Uri.parse("http://<YOUR_SERVER_IP>:5000/api/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": user_id,       // ← 스키마/백엔드와 일치
          "user_name": user_name,   // ← 스키마/백엔드와 일치
          "password": password,
        }),
      )
          .timeout(Duration(seconds: 10));

      setState(() => _isLoading = false);

      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원가입 성공! 로그인 해주세요.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      } else if (resp.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("이미 사용 중인 아이디입니다.")),
        );
      } else {
        String msg;
        try {
          msg = (jsonDecode(resp.body)['error'] ?? resp.body).toString();
        } catch (_) {
          msg = resp.body;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("회원가입 실패: $msg")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("네트워크 오류: $e")),
      );
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 아이디 입력
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: "아이디"),
              textInputAction: TextInputAction.next,
            ),
            // 이름 입력
            TextField(
              controller: _userNameController,
              decoration: InputDecoration(labelText: "이름"),
              textInputAction: TextInputAction.next,
            ),
            // 비밀번호 입력
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "비밀번호 (8자 이상)"),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _signup,
              child: Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}
