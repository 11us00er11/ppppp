import 'package:flutter/material.dart';
import 'screens/intro_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/survey_screen.dart';

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
        '/chat': (context) => ChatScreen(),
        '/history': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is String && args.isNotEmpty) {
            return HistoryScreen(token: args);
          }
          return const Scaffold(
            body: Center(child: Text('로그인 후 이용 가능합니다.')),
          );
        },
        '/survey': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return SurveyScreen(
            user_id: (args?['user_id'] as int?) ?? -1,
            displayName: args?['displayName'] as String?, // 이름도 함께 전달
          );
        },
      },
    );
  }
}
