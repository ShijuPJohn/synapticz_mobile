class TestHistoryModel {
  final String id;
  final String qSetName;
  final bool finished;
  final bool started;
  final DateTime startedTime;
  final DateTime? finishedTime;
  final String mode;
  final double totalMarks;
  final double scoredMarks;
  final String? subject;
  final String? exam;
  final String? language;
  final String? coverImage;
  final DateTime updatedTime;

  TestHistoryModel({
    required this.id,
    required this.qSetName,
    required this.finished,
    required this.started,
    required this.startedTime,
    this.finishedTime,
    required this.mode,
    required this.totalMarks,
    required this.scoredMarks,
    this.subject,
    this.exam,
    this.language,
    this.coverImage,
    required this.updatedTime,
  });

  factory TestHistoryModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double from dynamic
    double parseDoubleWithDefault(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return TestHistoryModel(
      id: json['id'] as String? ?? '',
      qSetName: json['qSetName'] as String? ?? '',
      finished: json['finished'] as bool? ?? false,
      started: json['started'] as bool? ?? false,
      startedTime: json['startedTime'] != null
          ? DateTime.parse(json['startedTime'] as String)
          : DateTime.now(),
      finishedTime: json['finishedTime'] != null
          ? DateTime.parse(json['finishedTime'] as String)
          : null,
      mode: json['mode'] as String? ?? 'untimed',
      totalMarks: parseDoubleWithDefault(json['totalMarks'], 0.0),
      scoredMarks: parseDoubleWithDefault(json['scoredMarks'], 0.0),
      subject: json['subject'] as String?,
      exam: json['exam'] as String?,
      language: json['language'] as String?,
      coverImage: json['coverImage'] as String?,
      updatedTime: json['updatedTime'] != null
          ? DateTime.parse(json['updatedTime'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qSetName': qSetName,
      'finished': finished,
      'started': started,
      'startedTime': startedTime.toIso8601String(),
      'finishedTime': finishedTime?.toIso8601String(),
      'mode': mode,
      'totalMarks': totalMarks,
      'scoredMarks': scoredMarks,
      'subject': subject,
      'exam': exam,
      'language': language,
      'coverImage': coverImage,
      'updatedTime': updatedTime.toIso8601String(),
    };
  }

  // Compute percentage
  double get percentage {
    if (totalMarks == 0) return 0;
    return (scoredMarks / totalMarks) * 100;
  }

  // Get status text
  String get statusText {
    if (!started) return 'Not Started';
    if (!finished) return 'In Progress';
    return 'Completed';
  }

  // Get mode display text
  String get modeDisplayText {
    switch (mode) {
      case 'untimed':
        return 'Untimed';
      case 'q_timed':
        return 'Per Question';
      case 't_timed':
        return 'Timed';
      default:
        return mode;
    }
  }

  // Duration (if finished)
  Duration? get duration {
    if (finishedTime == null) return null;
    return finishedTime!.difference(startedTime);
  }
}
