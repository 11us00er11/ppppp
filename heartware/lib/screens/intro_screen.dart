import 'package:flutter/material.dart';
import 'login_screen.dart'; // LoginScreen 직접 라우팅을 위해 필요

class IntroScreenWithUser extends StatelessWidget {
  final int userId;

  const IntroScreenWithUser({required this.userId});

  @override
  Widget build(BuildContext context) {
    final isGuest = userId == -1;

    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: Text(isGuest ? "게스트 모드" : "마음톡"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mood, size: 100, color: Colors.indigo),
              SizedBox(height: 24),
              Text(
                "마음톡",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                isGuest
                    ? "게스트로 접속하셨습니다."
                    : "당신의 감정을 이해하고 위로하는 정신건강 챗봇",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
                icon: Icon(Icons.chat_bubble_outline),
                label: Text("시작하기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/survey');
                },
                icon: Icon(Icons.assignment),
                label: Text("자가 진단하기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
                icon: Icon(Icons.bar_chart),
                label: Text("감정 기록 보기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              SizedBox(height: 40),

              // ✅ 로그인 or 로그아웃 버튼
              TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                  );
                },
                icon: Icon(isGuest ? Icons.login : Icons.logout),
                label: Text(isGuest ? "로그인하기" : "로그아웃"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo[800],
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
