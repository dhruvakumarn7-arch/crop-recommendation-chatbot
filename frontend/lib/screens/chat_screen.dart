/// chat_screen.dart
/// ----------------
/// The main chatbot user interface.
/// Displays the chat conversation, asks the agricultural questions step-by-step,
/// validates user inputs, and presents the crop recommendations.

import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/crop_data.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final CropInputData _cropData = CropInputData();

  // Tracks which question the chatbot is currently asking:
  // 0 = Soil, 1 = Temp, 2 = Rainfall, 3 = Humidity, 4 = pH, 5 = Season, 6 = Region, 7 = Complete
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isServerHealthy = true;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
    _startConversation();
  }

  Future<void> _checkServerStatus() async {
    final isOnline = await _apiService.checkHealth();
    if (mounted) {
      setState(() {
        _isServerHealthy = isOnline;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startConversation() {
    setState(() {
      _messages.clear();
      _cropData.reset();
      _currentStep = 0;

      // Initial welcome message from the chatbot
      _messages.add(
        ChatMessage(
          sender: MessageSender.bot,
          text:
              "Hello! I am your Crop Recommendation Assistant.\n\nI will ask you a few simple questions about your soil and weather, and then recommend the best crops for your land.\n\nLet's begin: What is your **Soil Type**?",
          quickReplies: ["Clay", "Loamy", "Sandy", "Black", "Red", "Alluvial"],
        ),
      );
    });
    _scrollToBottom();
  }

  void _handleUserResponse(String userText) {
    final trimmed = userText.trim();
    if (trimmed.isEmpty) return;

    _textController.clear();

    // 1. Add user message to chat
    setState(() {
      _messages.add(ChatMessage(sender: MessageSender.user, text: trimmed));
    });
    _scrollToBottom();

    // 2. Validate and process answer according to current step
    _processStepAnswer(trimmed);
  }

  void _processStepAnswer(String input) {
    switch (_currentStep) {
      case 0: // Soil Type
        _cropData.soilType = input;
        _currentStep++;
        _askQuestion(
          "Great! What is the average **Temperature** (in °C)?\n(e.g., 25 or 30)",
          quickReplies: ["18", "24", "28", "32"],
        );
        break;

      case 1: // Temperature
        final temp = double.tryParse(input);
        if (temp == null || temp < -10 || temp > 60) {
          _botReply("Please enter a valid number for temperature between -10°C and 60°C (e.g. 26).");
          return;
        }
        _cropData.temperature = temp;
        _currentStep++;
        _askQuestion(
          "Got it. What is your expected **Rainfall** (in mm)?\n(e.g., 500 for moderate rain, 1200 for high rain)",
          quickReplies: ["400", "700", "1100", "1600"],
        );
        break;

      case 2: // Rainfall
        final rain = double.tryParse(input);
        if (rain == null || rain < 0 || rain > 5000) {
          _botReply("Please enter a valid rainfall value in mm (e.g., 600).");
          return;
        }
        _cropData.rainfall = rain;
        _currentStep++;
        _askQuestion(
          "What is the average **Humidity** percentage (%)\n(e.g., 50 for dry/moderate, 80 for humid)",
          quickReplies: ["40", "55", "70", "85"],
        );
        break;

      case 3: // Humidity
        final humidity = double.tryParse(input);
        if (humidity == null || humidity < 0 || humidity > 100) {
          _botReply("Please enter a valid humidity percentage between 0 and 100 (e.g., 65).");
          return;
        }
        _cropData.humidity = humidity;
        _currentStep++;
        _askQuestion(
          "What is the **Soil pH** value?\n(7 is neutral, below 7 is acidic, above 7 is alkaline)",
          quickReplies: ["5.5", "6.5", "7.0", "7.5"],
        );
        break;

      case 4: // Soil pH
        final ph = double.tryParse(input);
        if (ph == null || ph < 0 || ph > 14) {
          _botReply("Please enter a valid pH value between 0 and 14 (e.g., 6.5).");
          return;
        }
        _cropData.ph = ph;
        _currentStep++;
        _askQuestion(
          "Which **Season** are you planning for?",
          quickReplies: ["Kharif (Monsoon)", "Rabi (Winter)", "Summer / Zaid"],
        );
        break;

      case 5: // Season
        _cropData.season = input;
        _currentStep++;
        _askQuestion(
          "Almost done! What is your **Location / Region**? (Or type 'Skip')",
          quickReplies: ["Plains", "Coastal", "Plateau", "Skip"],
        );
        break;

      case 6: // Region & Submit
        _cropData.location = input.toLowerCase() == "skip" ? "" : input;
        _currentStep++;
        _submitAgriculturalData();
        break;
    }
  }

  void _askQuestion(String question, {List<String>? quickReplies}) {
    setState(() {
      _messages.add(
        ChatMessage(
          sender: MessageSender.bot,
          text: question,
          quickReplies: quickReplies,
        ),
      );
    });
    _scrollToBottom();
  }

  void _botReply(String message) {
    setState(() {
      _messages.add(ChatMessage(sender: MessageSender.bot, text: message));
    });
    _scrollToBottom();
  }

  Future<void> _submitAgriculturalData() async {
    setState(() {
      _isLoading = true;
      _messages.add(
        ChatMessage(
          sender: MessageSender.bot,
          text: "Analyzing your agricultural data and consulting the backend... 🌾",
        ),
      );
    });
    _scrollToBottom();

    // Call our Python Flask REST API
    final result = await _apiService.getRecommendations(_cropData);

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        final List<RecommendationItem> items = result['items'];
        if (items.isEmpty) {
          _messages.add(
            ChatMessage(
              sender: MessageSender.bot,
              text:
                  "I evaluated your data, but couldn't find a strong crop match for those exact numbers. Try adjusting your rainfall or temperature.",
              quickReplies: ["Try Again"],
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              sender: MessageSender.bot,
              text: "Here are the top recommended crops for your conditions:",
              recommendations: items,
              quickReplies: ["Start Over with New Values"],
            ),
          );
        }
      } else {
        _messages.add(
          ChatMessage(
            sender: MessageSender.bot,
            text: "Error: ${result['message']}",
            quickReplies: ["Retry Connection"],
          ),
        );
      }
    });
    _scrollToBottom();
  }

  void _onQuickReplySelected(String value) {
    if (value == "Start Over with New Values" || value == "Try Again") {
      _startConversation();
    } else if (value == "Retry Connection") {
      _checkServerStatus();
      _submitAgriculturalData();
    } else {
      _handleUserResponse(value);
    }
  }

  TextInputType _getKeyboardType() {
    // Show numeric keypad for numbers (Temp, Rain, Humidity, pH)
    if (_currentStep == 1 || _currentStep == 2 || _currentStep == 3 || _currentStep == 4) {
      return const TextInputType.numberWithOptions(decimal: true);
    }
    return TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.eco, color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Crop Advisor Bot",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isServerHealthy ? Colors.lightGreenAccent : Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isServerHealthy ? "Flask Backend Connected" : "Backend Offline",
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Reset Conversation",
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _startConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageItem(msg);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                  ),
                  SizedBox(width: 10),
                  Text("Computing recommendation...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Bottom Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                const Padding(
                  padding: EdgeInsets.only(right: 8, top: 4),
                  child: CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    radius: 14,
                    child: Icon(Icons.psychology, color: Color(0xFF2E7D32), size: 18),
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : const Color(0xFF1E293B),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // If message contains crop recommendations, display them as cards
          if (msg.recommendations != null && msg.recommendations!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 36),
              child: Column(
                children: msg.recommendations!.map((crop) => _buildCropCard(crop)).toList(),
              ),
            ),

          // If message has quick reply buttons, render them
          if (msg.quickReplies != null && msg.quickReplies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 36),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: msg.quickReplies!.map((reply) {
                  return ActionChip(
                    backgroundColor: const Color(0xFFE8F5E9),
                    side: const BorderSide(color: Color(0xFFA5D6A7)),
                    label: Text(
                      reply,
                      style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _onQuickReplySelected(reply),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCropCard(RecommendationItem item) {
    final isHigh = item.score >= 75;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHigh ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.crop,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHigh ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${item.score}% Match",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isHigh ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Why this matches:",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 3),
          ...item.reasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              )),
          if (item.tips.isNotEmpty) ...[
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFF57C00)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Farming Tip: ${item.tips}",
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                keyboardType: _getKeyboardType(),
                textInputAction: TextInputAction.send,
                onSubmitted: _handleUserResponse,
                decoration: InputDecoration(
                  hintText: "Type your answer here...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: () => _handleUserResponse(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
