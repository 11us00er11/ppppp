import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const InputField({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                focusNode: focusNode,
                maxLines: 5,
                minLines: 1,
                maxLength: 300,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration.collapsed(hintText: "감정을 입력해보세요"),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.indigo),
              onPressed: onSend,
            )
          ],
        ),
      ),
    );
  }
}
