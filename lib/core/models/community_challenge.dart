class CommunityChallenge {
  const CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.goal,
    required this.participantGoal,
    required this.participantsCount,
    required this.isJoined,
    required this.endsAt,
    required this.createdBy,
  });

  final String id;
  final String title;
  final String description;
  final String goal;
  final int participantGoal;
  final int participantsCount;
  final bool isJoined;
  final DateTime endsAt;
  final String createdBy;

  double get currentProgress =>
      participantGoal > 0
          ? (participantsCount / participantGoal).clamp(0, 1).toDouble()
          : 0.0;

  int get daysLeft => endsAt.difference(DateTime.now()).inDays.clamp(0, 36500);

  CommunityChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? goal,
    int? participantGoal,
    int? participantsCount,
    bool? isJoined,
    DateTime? endsAt,
    String? createdBy,
  }) {
    return CommunityChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goal: goal ?? this.goal,
      participantGoal: participantGoal ?? this.participantGoal,
      participantsCount: participantsCount ?? this.participantsCount,
      isJoined: isJoined ?? this.isJoined,
      endsAt: endsAt ?? this.endsAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory CommunityChallenge.fromJson(Map<String, dynamic> json) {
    return CommunityChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      goal: json['goal'] as String,
      participantGoal: json['participant_goal'] as int,
      participantsCount: json['participants_count'] as int,
      isJoined: json['joined'] as bool,
      endsAt: DateTime.parse(json['ends_at'] as String),
      createdBy: json['created_by'] as String,
    );
  }
}
