/// Model biểu diễn nhật ký uống nước trong ngày.
class DailyWaterLog {
  final String date;
  final int cups;
  final int volumeMl;
  final DateTime updatedAt;

  const DailyWaterLog({
    required this.date,
    required this.cups,
    required this.volumeMl,
    required this.updatedAt,
  });

  bool get isGoalReached => cups >= 8 || volumeMl >= 2000;

  Map<String, dynamic> toJson() => {
        'date': date,
        'cups': cups,
        'volumeMl': volumeMl,
        'updatedAt': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toDbMap() => {
        'date': date,
        'cups': cups,
        'volume_ml': volumeMl,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DailyWaterLog.fromJson(Map<String, dynamic> json) {
    return DailyWaterLog(
      date: json['date']?.toString() ?? '',
      cups: (json['cups'] as num?)?.toInt() ?? 0,
      volumeMl: (json['volumeMl'] as num?)?.toInt() ??
          (json['volume_ml'] as num?)?.toInt() ??
          0,
      updatedAt: DateTime.tryParse(
              json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
