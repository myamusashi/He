enum EmotionType { veryHappy, happy, neutral, bored, sad, stressed, anxious }

extension EmotionTypeExtension on EmotionType {
  String get emoji {
    switch (this) {
      case EmotionType.veryHappy:
        return '😄';
      case EmotionType.happy:
        return '😊';
      case EmotionType.neutral:
        return '😐';
      case EmotionType.bored:
        return '😑';
      case EmotionType.sad:
        return '😢';
      case EmotionType.stressed:
        return '😤';
      case EmotionType.anxious:
        return '😰';
    }
  }

  String get label {
    switch (this) {
      case EmotionType.veryHappy:
        return 'Sangat Bahagia';
      case EmotionType.happy:
        return 'Senang';
      case EmotionType.neutral:
        return 'Netral';
      case EmotionType.bored:
        return 'Bosan';
      case EmotionType.sad:
        return 'Sedih';
      case EmotionType.stressed:
        return 'Stres';
      case EmotionType.anxious:
        return 'Cemas';
    }
  }
}
