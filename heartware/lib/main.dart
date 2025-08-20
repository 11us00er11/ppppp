// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_storage.dart';
import 'screens/intro_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/survey_screen.dart';
import 'services/api_client.dart';

// --- 토큰 저장/로드 유틸 ---
Future<String?> getStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<void> saveStoredToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<void> clearStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}

// --- 전역 ApiClient (요청 직전 최신 토큰을 읽어 Authorization 자동 부착) ---
late final ApiClient apiClient;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initApiClient(); // apiClient 초기화
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
              if (token != null && token.isNotEmpty) return token;
              // 없으면 게스트 토큰 발급 (ApiClient는 이름있는 인자 생성자!)
              final resp = await apiClient.post('/api/auth/guest');
              final t = resp['access_token'] as String;
              await saveStoredToken(t); // 전역 저장 (다른 화면에서도 자동 사용)
              return t;
            }(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return ChatScreen(token: snap.data!, initialMessage: initialMessage);
            },
          );
        },

        // ✅ /history: 토큰 인자 없이도 동작 (ApiClient가 내부에서 최신 토큰을 읽어 부착)
        '/history': (context) {
          // 이전 화면에서 token(String)으로 넘겨왔다면 저장해 주고 사용 가능
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String && args.isNotEmpty) {
            // 히스토리 진입 전에 넘겨받은 토큰을 저장 (선택)
            saveStoredToken(args);
          }
          return const HistoryScreen(); // ← 더 이상 token 파라미터 불필요
        },

        // ✅ /survey: arguments로 token(옵션으로 처리), displayName(옵션)
        '/survey': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final token = args?['token'] as String?;
          final displayName = args?['displayName'] as String?;

          // token 인자를 안 넘겨도, ApiClient가 저장소의 토큰으로 Authorization 자동 부착
          if (token != null && token.isNotEmpty) {
            saveStoredToken(token); // 선택
          }

          return SurveyScreen(
            token: token ?? '',        // 기존 시그니처 유지 필요 시
            displayName: displayName,
          );
        },
      },
    );
  }
}
