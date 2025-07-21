import 'package:flutter/material.dart';
import 'screens/intro_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/history_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => IntroScreen(),
        '/chat': (context) => ChatScreen(),
        '/survey': (context) => SurveyScreen(),
        '/history': (context) => HistoryScreen(),
      },
    );
  }
}
