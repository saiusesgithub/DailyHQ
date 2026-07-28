class JournalTimeBlock {
  const JournalTimeBlock({
    required this.id,
    required this.startMinutes,
    required this.endMinutes,
    required this.activity,
    required this.details,
    required this.category,
  });

  final String id;
  final int startMinutes;
  final int endMinutes;
  final String activity;
  final String details;
  final String category;

  int get durationMinutes => endMinutes - startMinutes;

  factory JournalTimeBlock.fromMap(Map<String, dynamic> data) {
    return JournalTimeBlock(
      id: data['id'] is String ? data['id'] as String : '',
      startMinutes: data['startMinutes'] is num
          ? (data['startMinutes'] as num).toInt()
          : 0,
      endMinutes: data['endMinutes'] is num
          ? (data['endMinutes'] as num).toInt()
          : 0,
      activity: data['activity'] is String ? data['activity'] as String : '',
      details: data['details'] is String ? data['details'] as String : '',
      category: data['category'] is String
          ? data['category'] as String
          : 'Uncategorized',
    );
  }

  Map<String, Object> toFirestore() {
    return {
      'id': id,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'activity': activity,
      'details': details,
      'category': category,
    };
  }

  JournalTimeBlock copyWith({
    int? startMinutes,
    int? endMinutes,
    String? activity,
    String? details,
    String? category,
  }) {
    return JournalTimeBlock(
      id: id,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      activity: activity ?? this.activity,
      details: details ?? this.details,
      category: category ?? this.category,
    );
  }
}
