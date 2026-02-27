import 'dart:convert';

class PeriodLog {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final String intensity; // e.g., 'Spotting', 'Light', 'Medium', 'Heavy'
  final String notes;

  PeriodLog({
    required this.id,
    required this.startDate,
    this.endDate,
    required this.intensity,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'intensity': intensity,
      'notes': notes,
    };
  }

  factory PeriodLog.fromMap(Map<String, dynamic> map) {
    return PeriodLog(
      id: map['id'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      intensity: map['intensity'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PeriodLog.fromJson(String source) =>
      PeriodLog.fromMap(json.decode(source) as Map<String, dynamic>);

  PeriodLog copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? intensity,
    String? notes,
  }) {
    return PeriodLog(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PeriodLog &&
        other.id == id &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.intensity == intensity &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        intensity.hashCode ^
        notes.hashCode;
  }
}
