import 'package:flutter/material.dart';
import 'screens/intro_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/survey_screen.dart';
import 'package:heartware/services/api_client.dart';

void main() {
  runApp(MindTalkApp());
}

class MindTalkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '마음톡 MindTalk',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/intro': (context) => IntroScreenWithUser(user_id: -1),

        // ✅ /chat: arguments로 token, initialMessage 받기
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          String? token = args?['token'] as String?;
          final initialMessage = args?['initialMessage'] as String?;

          return FutureBuilder<String>(
            future: () async {
              // 이미 토큰 있으면 그대로 사용
              if (token != null && token.isNotEmpty) return token!;
              // 없으면 게스트 토큰 발급
              final resp = await ApiClient('http://127.0.0.1:5000')
                  .post('/api/auth/guest');
              return (resp['access_token'] as String);
            }(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return ChatScreen(token: snap.data!, initialMessage: initialMessage);
            },
          );
        },

        '/history': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String && args.isNotEmpty) {
            return HistoryScreen(token: args);
          }
          return const Scaffold(
            body: Center(child: Text('로그인 후 이용 가능합니다.')),
          );
        },

        // ✅ /survey: arguments로 token(필수), displayName(옵션) 받기
        '/survey': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

          final token = args?['token'] as String?;
          final displayName = args?['displayName'] as String?;

          if (token == null || token.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('토큰 누락: 로그인 후 이용해주세요.')),
            );
          }

          return SurveyScreen(
            token: token,                // 🔑 SurveyScreen은 token을 required로 받는 버전
            displayName: displayName,    // (옵션)
          );
        },
      },
    );
  }
}
