import 'package:flutter/material.dart';
import 'login_screen.dart';

class IntroScreenWithUser extends StatelessWidget {
  final int user_id;
  final String? displayName; // ✅ 추가: 이름

  const IntroScreenWithUser({
    required this.user_id,
    this.displayName,        // ✅ 선택 인자
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isGuest = user_id == -1 || (displayName == null || displayName!.trim().isEmpty);

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
              const SizedBox(height: 24),

              // ✅ 이름 인사말
              if (!isGuest) ...[
                Text(
                  "${displayName}님, 반가워요",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo[800],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                "마음톡",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isGuest
                    ? "게스트로 접속하셨습니다."
                    : "당신의 감정을 이해하고 위로하는 정신건강 챗봇",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/chat',
                      arguments: {"displayName": displayName}); // ✅ 전달(선택)
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("시작하기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/survey',
                    arguments: {
                      'user_id': user_id,
                      'displayName': displayName, // 이름도 같이 전달
                    },
                  );
                },
                icon: const Icon(Icons.assignment),
                label: const Text("자가 진단하기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/history'),
                icon: const Icon(Icons.bar_chart),
                label: const Text("감정 기록 보기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),

              const SizedBox(height: 40),

              TextButton.icon(
                onPressed: () {
                  // (선택) 여기에 토큰/세션 제거 로직 추가 후 로그인 화면으로
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
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
