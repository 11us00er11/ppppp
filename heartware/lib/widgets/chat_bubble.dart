import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isUser;

  const ChatBubble({
    required this.text,
    required this.time,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              SizedBox(
                width: 12,
                height: 24,
                child: CustomPaint(painter: BubbleTail(isUser)),
              ),
            Container(
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isUser ? Colors.indigo[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(text),
            ),
            if (isUser)
              SizedBox(
                width: 12,
                height: 24,
                child: CustomPaint(painter: BubbleTail(isUser)),
              ),
          ],
        ),
        SizedBox(height: 4),
        Padding(
          padding: isUser
              ? const EdgeInsets.only(right: 16)
              : const EdgeInsets.only(left: 16),
          child: Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}

class BubbleTail extends CustomPainter {
  final bool isUser;

  BubbleTail(this.isUser);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isUser ? Colors.indigo[100]! : Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isUser) {
      path.moveTo(0, 0);
      path.lineTo(-6, 10);
      path.lineTo(0, 20);
    } else {
      path.moveTo(0, 0);
      path.lineTo(6, 10);
      path.lineTo(0, 20);
    }

    canvas.translate(isUser ? 5 : 7, 12);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
