import 'package:flutter/material.dart';
import '../services/agro_api_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class BotPage extends StatefulWidget {
  const BotPage({super.key});

  @override
  State<BotPage> createState() => _BotPageState();
}

class _BotPageState extends State<BotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final DatabaseReference _chatRef =
      FirebaseDatabase.instance.ref('chats/agrobot/messages');

  List<_Message> _messages = [];
  bool _sending = false;
  bool _isListening = false;
  bool _isTyping = false;

  String selectedLang = ""; // "en", "hi"
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();

    _listenMessages();

    Future.delayed(const Duration(milliseconds: 400), () async {
      if (_messages.isEmpty) {
        await _resetChat(); // reset only on first open
      }
    });
  }

  Future<void> _resetChat() async {
    await _chatRef.remove(); // clear old chat
    selectedLang = ""; // 🔥 FIXED: reset language mode
    _isTyping = false; // reset typing
    _isListening = false; // reset listening

    await Future.delayed(const Duration(milliseconds: 300));

    await _chatRef.push().set({
      "text":
          "🌐 Please choose your language:\n\nType **English 🇬🇧** or **Hindi 🇮🇳**",
      "fromUser": false,
      "timestamp": ServerValue.timestamp,
    });
  }

  // ------------------------------------------------------------------------
  // 🌐 1. Initial Language Message
  // ------------------------------------------------------------------------
  // ignore: unused_element
  Future<void> _showLanguageSelection() async {
    await _chatRef.push().set({
      "text":
          "🌐 Please choose your language:\n\nType **English 🇬🇧** or **Hindi 🇮🇳**",
      "fromUser": false,
      "timestamp": ServerValue.timestamp,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _chatSubscription?.cancel(); // 🔥🔥 FIX
    super.dispose();
  }

  // ------------------------------------------------------------------------
  // 🔄 2. Listen to Firebase database chat updates
  // ------------------------------------------------------------------------
  void _listenMessages() {
    _chatSubscription =
        _chatRef.orderByChild("timestamp").onValue.listen((event) {
      final data = event.snapshot.value;
      List<_Message> msgs = [];

      if (data is Map) {
        data.forEach((key, value) {
          msgs.add(
            _Message(
              text: value["text"] ?? "",
              fromUser: value["fromUser"] ?? false,
              timestamp: value["timestamp"] ?? 0,
            ),
          );
        });
      }

      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() => _messages = msgs);

      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    });
  }

  // ------------------------------------------------------------------------
  // 💬 3. Send text message to bot
  // ------------------------------------------------------------------------
  Future<void> _sendText(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => _sending = true);

    // Store user message
    await _chatRef.push().set({
      "text": text,
      "fromUser": true,
      "timestamp": ServerValue.timestamp,
    });

    // 🏁 LANGUAGE SELECTION
    if (selectedLang.isEmpty) {
      if (text.toLowerCase().contains("hindi") ||
          text.toLowerCase().contains("हिंदी")) {
        selectedLang = "hi";

        // Hindi welcome messages
        await _chatRef.push().set({
          "text": "भाषा चुनी गई: हिंदी 🇮🇳",
          "fromUser": false,
          "timestamp": ServerValue.timestamp,
        });

        await _chatRef.push().set({
          "text":
              "बहुत बढ़िया! मैं फसल सुझाव, मिट्टी की समस्या, मौसम अपडेट, खाद की जानकारी, कीट नियंत्रण और खेती से जुड़ी हर मदद कर सकता हूँ।\n\nआप क्या जानना चाहते हैं?",
          "fromUser": false,
          "timestamp": ServerValue.timestamp,
        });
      } else {
        selectedLang = "en";

        // English welcome messages
        await _chatRef.push().set({
          "text": "Language set to English 🇬🇧",
          "fromUser": false,
          "timestamp": ServerValue.timestamp,
        });

        await _chatRef.push().set({
          "text":
              "Great! I can help you with crop prediction, soil issues, weather updates, fertilizer guidance, pest control, and farming best practices.\n\nWhat would you like to know?",
          "fromUser": false,
          "timestamp": ServerValue.timestamp,
        });
      }

      setState(() => _sending = false);
      return;
    }

    // 🟡 BOT TYPING...
    setState(() => _isTyping = true);

    // Get BOT reply
    String reply = await AgroApi.getBotReply(text, selectedLang);

    // 🟢 Stop typing
    setState(() => _isTyping = false);

    // Store bot reply
    await _chatRef.push().set({
      "text": reply,
      "fromUser": false,
      "timestamp": ServerValue.timestamp,
    });

    setState(() => _sending = false);
  }

  // ------------------------------------------------------------------------
  // 🎤 4. Voice Input
  // ------------------------------------------------------------------------
  Future<void> _voiceInput() async {
    setState(() => _isListening = true);

    String heard =
        await AgroApi.speechToText(selectedLang.isEmpty ? "en" : selectedLang);

    setState(() => _isListening = false);

    if (heard.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not understand speech")));
      return;
    }

    await _sendText(heard);
  }

  // ------------------------------------------------------------------------
  // 🎧 LISTENING OVERLAY
  // ------------------------------------------------------------------------
  Widget listeningOverlay() {
    if (!_isListening) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Listening... Speak now",
                style: TextStyle(color: Colors.white, fontSize: 16),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // ⌨ CHAT BUBBLE UI
  // ------------------------------------------------------------------------
  Widget chatBubble(_Message msg) {
    return Row(
      mainAxisAlignment:
          msg.fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!msg.fromUser)
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.shade600,
            child: const Icon(Icons.agriculture, color: Colors.white),
          ),
        if (!msg.fromUser) const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: msg.fromUser ? Colors.green.shade300 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: Text(msg.text, style: const TextStyle(fontSize: 15)),
          ),
        ),
        if (msg.fromUser) const SizedBox(width: 8),
        if (msg.fromUser)
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------------
  // 💬 Typing Indicator
  // ------------------------------------------------------------------------
  Widget typingIndicator() {
    if (!_isTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.green.shade600,
            child: const Icon(Icons.agriculture, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text("AgroBot is typing...",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // BOTTOM INPUT BAR
  // ------------------------------------------------------------------------
  Widget inputBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.mic,
                size: 32, color: _isListening ? Colors.red : Colors.green),
            onPressed: _sending ? null : _voiceInput,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _sendText(value.trim());
                  _controller.clear();
                }
              },
              decoration: InputDecoration(
                hintText: "Ask AgroBot…",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green, size: 30),
            onPressed: () {
              if (_controller.text.trim().isNotEmpty) {
                _sendText(_controller.text.trim());
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.green.shade600,
        title: const Text("AgroBot AI Assistant"),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => chatBubble(_messages[index]),
                ),
              ),
              typingIndicator(),
              inputBar(),
            ],
          ),
          listeningOverlay(),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// Data Model
// ------------------------------------------------------------------------
class _Message {
  final String text;
  final bool fromUser;
  final int timestamp;

  _Message({
    required this.text,
    required this.fromUser,
    required this.timestamp,
  });
}
