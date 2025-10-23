class ProfileOverviewModel {
  final UserStats? stats;
  final List<ActivityDay>? activityData;
  final String? memberSince;

  ProfileOverviewModel({
    this.stats,
    this.activityData,
    this.memberSince,
  });

  factory ProfileOverviewModel.fromJson(Map<String, dynamic> json) {
    return ProfileOverviewModel(
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      activityData: json['activity_data'] != null
          ? (json['activity_data'] as List)
              .map((item) => ActivityDay.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      memberSince: json['member_since'] as String?,
    );
  }
}

class UserStats {
  final int questionsAnswered;
  final int testsCreated;
  final int testsCompleted;
  final int activeDays;
  final int currentStreak;
  final int longestStreak;

  UserStats({
    required this.questionsAnswered,
    required this.testsCreated,
    required this.testsCompleted,
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      questionsAnswered: json['questions_answered'] as int? ?? 0,
      testsCreated: json['tests_created'] as int? ?? 0,
      testsCompleted: json['tests_completed'] as int? ?? 0,
      activeDays: json['active_days'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
    );
  }
}

class ActivityDay {
  final String date;
  final int count;

  ActivityDay({
    required this.date,
    required this.count,
  });

  factory ActivityDay.fromJson(Map<String, dynamic> json) {
    return ActivityDay(
      date: json['date'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}
