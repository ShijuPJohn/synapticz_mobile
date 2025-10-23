class QuizModel {
  final String id;
  final String name;
  final String mode;
  final String subject;
  final String? exam;
  final String language;
  final int? timeDuration;
  final String? description;
  final String? associatedResource;
  final String? coverImage;
  final DateTime createdAt;
  final int createdById;
  final String createdByName;
  final String createdByEmail;
  final String accessLevel;
  final String? creatorType;
  final bool verified;
  final String visibility;
  final String urlSlug;
  final List<int> questionIds;
  final int totalQuestions;
  final List<String> tags;
  final int testSessionsTaken;
  final String? learningArticleId;
  final List<num>? marks;

  QuizModel({
    required this.id,
    required this.name,
    required this.mode,
    required this.subject,
    this.exam,
    required this.language,
    this.timeDuration,
    this.description,
    this.associatedResource,
    this.coverImage,
    required this.createdAt,
    required this.createdById,
    required this.createdByName,
    required this.createdByEmail,
    required this.accessLevel,
    this.creatorType,
    required this.verified,
    required this.visibility,
    required this.urlSlug,
    required this.questionIds,
    required this.totalQuestions,
    required this.tags,
    required this.testSessionsTaken,
    this.learningArticleId,
    this.marks,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from dynamic (can be String or int)
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper function to safely parse int with default
    int _parseIntWithDefault(dynamic value, int defaultValue) {
      final parsed = _parseInt(value);
      return parsed ?? defaultValue;
    }

    return QuizModel(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: json['mode'] as String,
      subject: json['subject'] as String,
      exam: json['exam'] as String?,
      language: json['language'] as String,
      timeDuration: _parseInt(json['time_duration']),
      description: json['description'] as String?,
      associatedResource: json['associated_resource'] as String?,
      coverImage: json['cover_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdById: _parseIntWithDefault(json['created_by_id'], 0),
      createdByName: json['created_by_name'] as String? ?? '',
      createdByEmail: json['created_by_email'] as String? ?? '',
      accessLevel: json['access_level'] as String? ?? 'free',
      creatorType: json['creator_type'] as String?,
      verified: json['verified'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'public',
      urlSlug: json['url_slug'] as String? ?? '',
      questionIds: (json['question_ids'] as List<dynamic>?)?.map((e) => _parseIntWithDefault(e, 0)).toList() ?? [],
      totalQuestions: _parseIntWithDefault(json['total_questions'], 0),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      testSessionsTaken: _parseIntWithDefault(json['test_sessions_taken'], 0),
      learningArticleId: json['learning_article_id'] as String?,
      marks: (json['marks'] as List<dynamic>?)?.map((e) => e as num).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mode': mode,
      'subject': subject,
      'exam': exam,
      'language': language,
      'time_duration': timeDuration,
      'description': description,
      'associated_resource': associatedResource,
      'cover_image': coverImage,
      'created_at': createdAt.toIso8601String(),
      'created_by_id': createdById,
      'created_by_name': createdByName,
      'created_by_email': createdByEmail,
      'access_level': accessLevel,
      'creator_type': creatorType,
      'verified': verified,
      'visibility': visibility,
      'url_slug': urlSlug,
      'question_ids': questionIds,
      'total_questions': totalQuestions,
      'tags': tags,
      'test_sessions_taken': testSessionsTaken,
      'learning_article_id': learningArticleId,
      'marks': marks,
    };
  }
}

class PaginationInfo {
  final int total;
  final int totalPages;
  final int perPage;
  final int current;
  final int? next;
  final int? prev;

  PaginationInfo({
    required this.total,
    required this.totalPages,
    required this.perPage,
    required this.current,
    this.next,
    this.prev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
      perPage: json['per_page'] as int,
      current: json['current'] as int,
      next: json['next'] as int?,
      prev: json['prev'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'total_pages': totalPages,
      'per_page': perPage,
      'current': current,
      'next': next,
      'prev': prev,
    };
  }

  bool get hasNext => next != null;
  bool get hasPrev => prev != null;
}

class QuizResponse {
  final List<QuizModel> data;
  final PaginationInfo pagination;

  QuizResponse({
    required this.data,
    required this.pagination,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => QuizModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}
