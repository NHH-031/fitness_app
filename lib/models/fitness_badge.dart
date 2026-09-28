class FitnessBadge {
  final String id;
  final String titleVi;
  final String titleEn;
  final String descriptionVi;
  final String descriptionEn;
  final String iconEmoji;
  final String category; // 'streak', 'water', 'steps', 'food', 'workout', 'energy'
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0
  final String progressLabel;

  const FitnessBadge({
    required this.id,
    required this.titleVi,
    required this.titleEn,
    required this.descriptionVi,
    required this.descriptionEn,
    required this.iconEmoji,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
    required this.progressLabel,
  });

  FitnessBadge copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
    String? progressLabel,
  }) {
    return FitnessBadge(
      id: id,
      titleVi: titleVi,
      titleEn: titleEn,
      descriptionVi: descriptionVi,
      descriptionEn: descriptionEn,
      iconEmoji: iconEmoji,
      category: category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      progressLabel: progressLabel ?? this.progressLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleVi': titleVi,
        'titleEn': titleEn,
        'descriptionVi': descriptionVi,
        'descriptionEn': descriptionEn,
        'iconEmoji': iconEmoji,
        'category': category,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'progress': progress,
        'progressLabel': progressLabel,
      };

  factory FitnessBadge.fromJson(Map<String, dynamic> json) {
    return FitnessBadge(
      id: json['id']?.toString() ?? '',
      titleVi: json['titleVi']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      descriptionVi: json['descriptionVi']?.toString() ?? '',
      descriptionEn: json['descriptionEn']?.toString() ?? '',
      iconEmoji: json['iconEmoji']?.toString() ?? '🏆',
      category: json['category']?.toString() ?? 'general',
      isUnlocked: json['isUnlocked'] == true,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'].toString())
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      progressLabel: json['progressLabel']?.toString() ?? '',
    );
  }
}
