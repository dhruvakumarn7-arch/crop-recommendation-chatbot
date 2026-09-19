/// chat_message.dart
/// -----------------
/// Represents a single message bubble in the chatbot interface.
/// A message can come from the user or from the bot.
/// It can also contain structured recommendation data returned by Flask.

enum MessageSender { user, bot }

class RecommendationItem {
  final String crop;
  final int score;
  final String suitability;
  final String description;
  final String tips;
  final List<String> reasons;

  RecommendationItem({
    required this.crop,
    required this.score,
    required this.suitability,
    required this.description,
    required this.tips,
    required this.reasons,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      crop: json['crop'] ?? 'Unknown Crop',
      score: json['score'] is int ? json['score'] : (json['score'] as num?)?.toInt() ?? 0,
      suitability: json['suitability'] ?? 'Recommended',
      description: json['description'] ?? '',
      tips: json['tips'] ?? '',
      reasons: (json['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final List<RecommendationItem>? recommendations;
  final List<String>? quickReplies; // Buttons user can tap for quick answers

  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? timestamp,
    this.recommendations,
    this.quickReplies,
  }) : timestamp = timestamp ?? DateTime.now();
}
