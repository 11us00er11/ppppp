import 'package:flutter/material.dart';
import 'package:heartware/widgets/chat_bubble.dart';
import 'package:heartware/services/gpt_service.dart';
import 'package:heartware/widgets/input_field.dart';
import 'package:heartware/models/message.dart';
import 'dart:async';

const int typingSpeedMs = 60;

class ChatScreen extends StatefulWidget {
  final String? token;              // was: final String token;
  final String? initialMessage;
  ChatScreen({this.token, this.initialMessage});  // was: required this.token

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      _focusNode.requestFocus();

      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _messages.add(Message(
            text: "${widget.initialMessage} 라는 결과가 나왔습니다",
            time: _getCurrentTime(),
            role: "user",
          ));
        });

        _scrollToBottom();
        _sendToGPT(widget.initialMessage!);
      } else {
        if (!mounted) return;
        setState(() {
          _messages.add(Message(
            text: "안녕하세요! 오늘 기분은 어떠신가요?",
            time: _getCurrentTime(),
            role: "bot",
          ));
        });

        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _animateBotResponse(String text, int index, String time) {
    String currentText = "";
    int i = 0;

    Timer.periodic(Duration(milliseconds: typingSpeedMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (i >= text.length) {
        timer.cancel();
        return;
      }

      setState(() {
        currentText += text[i];
        _messages[index] = Message(text: currentText, time: time, role: "bot");
      });
      i++;
    });
  }

  void _sendMessage() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: input,
        time: _getCurrentTime(),
        role: "user",
      ));
    });

    _controller.clear();
    _scrollToBottom();
    await _sendToGPT(input);
  }

  Future<void> _sendToGPT(String input) async {
    final loadingIndex = _messages.length;
    final loadingTime = _getCurrentTime();

    if (!mounted) return;
    setState(() {
      _messages.add(Message(text: "...", time: loadingTime, role: "bot"));
    });

    try {
      String responseText = await GPTService.sendMessage(
        input,
        token: widget.token ?? '', // ✅ 여기서 token 전달
      );
      _animateBotResponse(responseText, loadingIndex, loadingTime);
    } catch (e) {
      setState(() {
        _messages[loadingIndex] = Message(
          text: "오류: $e",
          time: loadingTime,
          role: "bot",
        );
      });
    }
  }

  Widget _buildMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ChatBubble(
        text: message.text,
        time: message.time,
        isUser: message.isUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final String token = (args?['token'] as String?) ?? '';
    final String? displayName = args?['displayName'] as String?;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("마음톡 챗봇")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          Divider(height: 1),
          InputField(
            controller: _controller,
            focusNode: _focusNode,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
