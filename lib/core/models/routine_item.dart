enum RoutineCategory {
  exercise('Exercise & Fitness', 'fitness_center'),
  commute('Travel & Commuting', 'commute'),
  school('Children & School', 'school'),
  indoor('Indoor Environment', 'home'),
  evening('Family & Evening', 'nightlight_round');

  final String label;
  final String iconName;
  const RoutineCategory(this.label, this.iconName);

  static RoutineCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'exercise':
      case 'fitness':
        return RoutineCategory.exercise;
      case 'commute':
      case 'travel':
        return RoutineCategory.commute;
      case 'school':
      case 'children':
        return RoutineCategory.school;
      case 'evening':
      case 'family':
        return RoutineCategory.evening;
      case 'indoor':
      default:
        return RoutineCategory.indoor;
    }
  }
}

/// Strongly typed domain model representing an explanatory daily routine card.
///
/// Every routine item presents:
/// 1. [time]: Action timestamp (e.g. "7:00 AM").
/// 2. [title] & [detail]: Concrete action to take.
/// 3. [reason]: Explanatory "Why it matters" scientific rationale.
class RoutineItem {
  final String id;
  final String time;
  final String timePeriod; // 'Morning', 'Afternoon', 'Evening', 'Night'
  final String title;
  final String detail;
  final String reason;
  final RoutineCategory category;
  final String targetAudience; // 'All Household Members', 'Children', etc.
  final bool isCompleted;

  const RoutineItem({
    required this.id,
    required this.time,
    required this.timePeriod,
    required this.title,
    required this.detail,
    required this.reason,
    this.category = RoutineCategory.indoor,
    this.targetAudience = 'All Household Members',
    this.isCompleted = false,
  });

  /// Deserialization from the FastAPI `RoutineItemResponse` schema.
  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    final catStr = json['category'] as String?;
    return RoutineItem(
      id: json['id'] as String,
      time: json['time'] as String,
      timePeriod: json['time_period'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      reason: json['reason'] as String,
      category: RoutineCategory.fromString(catStr),
      targetAudience: json['target_audience'] as String,
      isCompleted: false,
    );
  }

  /// Serialization to JSON, matching FastAPI `RoutineItemResponse`.
  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'time_period': timePeriod,
        'title': title,
        'detail': detail,
        'reason': reason,
        'category': category.name,
        'target_audience': targetAudience,
        'is_completed': isCompleted,
      };

  RoutineItem copyWith({
    String? id,
    String? time,
    String? timePeriod,
    String? title,
    String? detail,
    String? reason,
    RoutineCategory? category,
    String? targetAudience,
    bool? isCompleted,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      time: time ?? this.time,
      timePeriod: timePeriod ?? this.timePeriod,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      targetAudience: targetAudience ?? this.targetAudience,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Typed container model matching FastAPI `RoutineListResponse`.
class RoutineListResponse {
  final String city;
  final List<RoutineItem> routines;

  const RoutineListResponse({
    required this.city,
    required this.routines,
  });

  factory RoutineListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['routines'] as List;
    return RoutineListResponse(
      city: json['city'] as String,
      routines: rawList
          .map((e) => RoutineItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'routines': routines.map((r) => r.toJson()).toList(),
      };
}
