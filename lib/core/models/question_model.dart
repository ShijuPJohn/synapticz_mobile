class QuestionModel {
  final int id;
  final String question;
  final String questionType;
  final List<String> options;
  final List<int> correctOptions;
  final String? explanation;
  final List<int> selectedAnswerList;
  final double questionsTotalMark;
  final double questionsScoredMark;
  final bool answered;
  final bool isCorrect;

  QuestionModel({
    required this.id,
    required this.question,
    required this.questionType,
    required this.options,
    required this.correctOptions,
    this.explanation,
    required this.selectedAnswerList,
    required this.questionsTotalMark,
    required this.questionsScoredMark,
    required this.answered,
    required this.isCorrect,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
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

    return QuestionModel(
      id: _parseIntWithDefault(json['id'], 0),
      question: json['question'] as String? ?? '',
      questionType: json['question_type'] as String? ?? 'm-choice',
      options: (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      correctOptions: (json['correct_options'] as List<dynamic>?)
              ?.map((e) => _parseIntWithDefault(e, 0))
              .toList() ??
          [],
      explanation: json['explanation'] as String?,
      selectedAnswerList: (json['selected_answer_list'] as List<dynamic>?)
              ?.map((e) => _parseIntWithDefault(e, 0))
              .toList() ??
          [],
      questionsTotalMark: _parseDoubleWithDefault(json['questions_total_mark'], 1.0),
      questionsScoredMark: _parseDoubleWithDefault(json['questions_scored_mark'], 0.0),
      answered: json['answered'] as bool? ?? false,
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'question_type': questionType,
      'options': options,
      'correct_options': correctOptions,
      'explanation': explanation,
      'selected_answer_list': selectedAnswerList,
      'questions_total_mark': questionsTotalMark,
      'questions_scored_mark': questionsScoredMark,
      'answered': answered,
      'is_correct': isCorrect,
    };
  }

  bool get isMultiSelect => questionType == 'm-select';
  bool get isSingleSelect => questionType == 'm-choice';

  // Convenience getters for compatibility
  String get statement => question;
  num get marks => questionsTotalMark;
  num? get negativeMarks => null; // Not provided in this structure
}
