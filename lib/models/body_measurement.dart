class BodyMeasurement {
  final String id;
  final String date; // YYYY-MM-DD
  final double? weight; // kg
  final double? neckCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? bicepCm;
  final double? thighCm;
  final double? bodyFatPercent; // %
  final String? notes;
  final DateTime createdAt;

  const BodyMeasurement({
    required this.id,
    required this.date,
    this.weight,
    this.neckCm,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.bicepCm,
    this.thighCm,
    this.bodyFatPercent,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'weight': weight,
      'neck_cm': neckCm,
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'hips_cm': hipsCm,
      'bicep_cm': bicepCm,
      'thigh_cm': thighCm,
      'body_fat_percent': bodyFatPercent,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id']?.toString() ?? '',
      date: map['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      weight: (map['weight'] as num?)?.toDouble(),
      neckCm: (map['neck_cm'] as num?)?.toDouble(),
      chestCm: (map['chest_cm'] as num?)?.toDouble(),
      waistCm: (map['waist_cm'] as num?)?.toDouble(),
      hipsCm: (map['hips_cm'] as num?)?.toDouble(),
      bicepCm: (map['bicep_cm'] as num?)?.toDouble(),
      thighCm: (map['thigh_cm'] as num?)?.toDouble(),
      bodyFatPercent: (map['body_fat_percent'] as num?)?.toDouble(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  BodyMeasurement copyWith({
    String? id,
    String? date,
    double? weight,
    double? neckCm,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bicepCm,
    double? thighCm,
    double? bodyFatPercent,
    String? notes,
    DateTime? createdAt,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      neckCm: neckCm ?? this.neckCm,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      bicepCm: bicepCm ?? this.bicepCm,
      thighCm: thighCm ?? this.thighCm,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
