class Message {
  final String text;
  final String time;
  final String role;

  Message({required this.text, required this.time, required this.role});

  bool get isUser => role == "user";

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map["text"] ?? "",
      time: map["time"] ?? "",
      role: map["role"] ?? "bot",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "text": text,
      "time": time,
      "role": role,
    };
  }
}
