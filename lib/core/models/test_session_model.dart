import 'question_model.dart';

class TestSessionModel {
  final String sessionId;
  final String name;
  final String mode;
  final bool finished;
  final DateTime startedTime;
  final DateTime? finishedTime;
  final double totalMarks;
  final double scoredMarks;
  final int currentQuestionNum;
  final int rank;
  final int secondsPerQuestion;
  final int timeCapSeconds;
  final int remainingTime;

  final String questionSetId;
  final String questionSetName;
  final String? questionSetDescription;
  final String? questionSetCoverImage;
  final String? questionSetSubject;

  final List<QuestionModel> questions;
  final List<int> bookmarkedQuestionIds;
  final List<int> savedExplanationQuestionIds;
  final Map<String, dynamic>? testStats;

  TestSessionModel({
    required this.sessionId,
    required this.name,
    required this.mode,
    required this.finished,
    required this.startedTime,
    this.finishedTime,
    required this.totalMarks,
    required this.scoredMarks,
    required this.currentQuestionNum,
    required this.rank,
    required this.secondsPerQuestion,
    required this.timeCapSeconds,
    required this.remainingTime,
    required this.questionSetId,
    required this.questionSetName,
    this.questionSetDescription,
    this.questionSetCoverImage,
    this.questionSetSubject,
    required this.questions,
    required this.bookmarkedQuestionIds,
    required this.savedExplanationQuestionIds,
    this.testStats,
  });

  factory TestSessionModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from dynamic
    int _parseIntWithDefault(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper function to safely parse double from dynamic
    double _parseDoubleWithDefault(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    final testSession = json['test_session'] as Map<String, dynamic>? ?? {};
    final questionSet = json['question_set'] as Map<String, dynamic>? ?? {};
    final questions = (json['questions'] as List<dynamic>?)?.map((e) =>
      QuestionModel.fromJson(e as Map<String, dynamic>)
    ).toList() ?? [];

    return TestSessionModel(
      sessionId: testSession['id'] as String? ?? '',
      name: testSession['name'] as String? ?? '',
      mode: testSession['mode'] as String? ?? 'practice',
      finished: testSession['finished'] as bool? ?? false,
      startedTime: testSession['started_time'] != null
        ? DateTime.parse(testSession['started_time'] as String)
        : DateTime.now(),
      finishedTime: testSession['finished_time'] != null
        ? DateTime.parse(testSession['finished_time'] as String)
        : null,
      totalMarks: _parseDoubleWithDefault(testSession['total_marks'], 0.0),
      scoredMarks: _parseDoubleWithDefault(testSession['scored_marks'], 0.0),
      currentQuestionNum: _parseIntWithDefault(testSession['current_question_num'], 0),
      rank: _parseIntWithDefault(testSession['rank'], 0),
      secondsPerQuestion: _parseIntWithDefault(testSession['seconds_per_question'], 0),
      timeCapSeconds: _parseIntWithDefault(testSession['time_cap_seconds'], 0),
      remainingTime: _parseIntWithDefault(testSession['remaining_time'], 0),
      questionSetId: questionSet['id'] as String? ?? '',
      questionSetName: questionSet['name'] as String? ?? '',
      questionSetDescription: questionSet['description'] as String?,
      questionSetCoverImage: questionSet['cover_image'] as String?,
      questionSetSubject: questionSet['subject'] as String?,
      questions: questions,
      bookmarkedQuestionIds: (json['bookmarked_question_ids'] as List<dynamic>?)
        ?.map((e) => _parseIntWithDefault(e, 0))
        .toList() ?? [],
      savedExplanationQuestionIds: (json['saved_explanation_question_ids'] as List<dynamic>?)
        ?.map((e) => _parseIntWithDefault(e, 0))
        .toList() ?? [],
      testStats: json['test_stats'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_session': {
        'id': sessionId,
        'name': name,
        'mode': mode,
        'finished': finished,
        'started_time': startedTime.toIso8601String(),
        'finished_time': finishedTime?.toIso8601String(),
        'total_marks': totalMarks,
        'scored_marks': scoredMarks,
        'current_question_num': currentQuestionNum,
        'rank': rank,
        'seconds_per_question': secondsPerQuestion,
        'time_cap_seconds': timeCapSeconds,
        'remaining_time': remainingTime,
      },
      'question_set': {
        'id': questionSetId,
        'name': questionSetName,
        'description': questionSetDescription,
        'cover_image': questionSetCoverImage,
        'subject': questionSetSubject,
      },
      'questions': questions.map((e) => e.toJson()).toList(),
      'bookmarked_question_ids': bookmarkedQuestionIds,
      'saved_explanation_question_ids': savedExplanationQuestionIds,
      if (testStats != null) 'test_stats': testStats,
    };
  }

  int get totalQuestions => questions.length;
  int get answeredCount => questions.where((q) => q.answered).length;
  int get unansweredCount => totalQuestions - answeredCount;
  int get markedForReviewCount => bookmarkedQuestionIds.length;

  bool isQuestionAnswered(int questionId) =>
    questions.any((q) => q.id == questionId && q.answered);

  bool isQuestionMarkedForReview(int questionId) =>
    bookmarkedQuestionIds.contains(questionId);

  List<int> getSelectedOptions(int questionId) {
    final question = questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => questions.first,
    );
    return question.selectedAnswerList;
  }

  // Calculate time duration in minutes
  int? get timeDuration {
    if (timeCapSeconds > 0) {
      return (timeCapSeconds / 60).ceil();
    }
    return null;
  }

  TestSessionModel copyWith({
    String? sessionId,
    String? name,
    String? mode,
    bool? finished,
    DateTime? startedTime,
    DateTime? finishedTime,
    double? totalMarks,
    double? scoredMarks,
    int? currentQuestionNum,
    int? rank,
    int? secondsPerQuestion,
    int? timeCapSeconds,
    int? remainingTime,
    String? questionSetId,
    String? questionSetName,
    String? questionSetDescription,
    String? questionSetCoverImage,
    String? questionSetSubject,
    List<QuestionModel>? questions,
    List<int>? bookmarkedQuestionIds,
    List<int>? savedExplanationQuestionIds,
    Map<String, dynamic>? testStats,
  }) {
    return TestSessionModel(
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      finished: finished ?? this.finished,
      startedTime: startedTime ?? this.startedTime,
      finishedTime: finishedTime ?? this.finishedTime,
      totalMarks: totalMarks ?? this.totalMarks,
      scoredMarks: scoredMarks ?? this.scoredMarks,
      currentQuestionNum: currentQuestionNum ?? this.currentQuestionNum,
      rank: rank ?? this.rank,
      secondsPerQuestion: secondsPerQuestion ?? this.secondsPerQuestion,
      timeCapSeconds: timeCapSeconds ?? this.timeCapSeconds,
      remainingTime: remainingTime ?? this.remainingTime,
      questionSetId: questionSetId ?? this.questionSetId,
      questionSetName: questionSetName ?? this.questionSetName,
      questionSetDescription: questionSetDescription ?? this.questionSetDescription,
      questionSetCoverImage: questionSetCoverImage ?? this.questionSetCoverImage,
      questionSetSubject: questionSetSubject ?? this.questionSetSubject,
      questions: questions ?? this.questions,
      bookmarkedQuestionIds: bookmarkedQuestionIds ?? this.bookmarkedQuestionIds,
      savedExplanationQuestionIds: savedExplanationQuestionIds ?? this.savedExplanationQuestionIds,
      testStats: testStats ?? this.testStats,
    );
  }
}
