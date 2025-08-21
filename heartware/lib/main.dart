// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/intro_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/survey_screen.dart';
import 'services/api_client.dart';
final ApiClient apiClient = ApiClient(
  tokenProvider: getStoredToken,
  baseUrl: 'http://61.254.189.212:5000',
);
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          String? token = args?['token'] as String?;
          final initialMessage = args?['initialMessage'] as String?;

          return FutureBuilder<String>(
            future: () async {
              if (token != null && token.isNotEmpty) return token;
              final resp = await apiClient.post('/api/auth/guest');
              final t = resp['access_token'] as String;
              await saveStoredToken(t);
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

        '/history': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String && args.isNotEmpty) {
            saveStoredToken(args);
          }
          return const HistoryScreen();
        },

        '/survey': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final token = args?['token'] as String?;
          final displayName = args?['displayName'] as String?;
          if (token != null && token.isNotEmpty) {
            saveStoredToken(token);
          }

          return SurveyScreen(
            token: token ?? '',
            displayName: displayName,
          );
        },
      },
    );
  }
}
