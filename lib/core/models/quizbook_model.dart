class QuizBookModel {
  final String id;
  final String name;
  final String? urlSlug;
  final String? description;
  final String? coverImage;
  final String visibility;
  final int createdById;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuizBookQuizModel>? quizzes;

  QuizBookModel({
    required this.id,
    required this.name,
    this.urlSlug,
    this.description,
    this.coverImage,
    required this.visibility,
    required this.createdById,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
    this.quizzes,
  });

  factory QuizBookModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from dynamic (can be String or int)
    int parseIntWithDefault(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return QuizBookModel(
      id: json['id'] as String,
      name: json['name'] as String,
      urlSlug: json['url_slug'] as String?,
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      createdById: parseIntWithDefault(json['created_by_id'], 0),
      deleted: json['deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      quizzes: json['quizzes'] != null
          ? (json['quizzes'] as List<dynamic>)
              .map((e) => QuizBookQuizModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url_slug': urlSlug,
      'description': description,
      'cover_image': coverImage,
      'visibility': visibility,
      'created_by_id': createdById,
      'deleted': deleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (quizzes != null) 'quizzes': quizzes!.map((e) => e.toJson()).toList(),
    };
  }

  int get quizCount => quizzes?.length ?? 0;
}

// Simplified quiz model for quizzes within a quizbook
class QuizBookQuizModel {
  final String id;
  final String name;
  final String? mode;
  final String? subject;
  final String? exam;
  final String? visibility;
  final String? description;
  final String? coverImage;
  final int? difficulty;

  QuizBookQuizModel({
    required this.id,
    required this.name,
    this.mode,
    this.subject,
    this.exam,
    this.visibility,
    this.description,
    this.coverImage,
    this.difficulty,
  });

  factory QuizBookQuizModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int from dynamic
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return QuizBookQuizModel(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: json['mode'] as String?,
      subject: json['subject'] as String?,
      exam: json['exam'] as String?,
      visibility: json['visibility'] as String?,
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String?,
      difficulty: parseInt(json['difficulty']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mode': mode,
      'subject': subject,
      'exam': exam,
      'visibility': visibility,
      'description': description,
      'cover_image': coverImage,
      'difficulty': difficulty,
    };
  }
}

class QuizBookResponse {
  final List<QuizBookModel> quizBooks;
  final PaginationInfo pagination;

  QuizBookResponse({
    required this.quizBooks,
    required this.pagination,
  });

  factory QuizBookResponse.fromJson(Map<String, dynamic> json) {
    return QuizBookResponse(
      quizBooks: (json['quiz_books'] as List<dynamic>)
          .map((e) => QuizBookModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
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

  bool get hasNext => next != null;
  bool get hasPrev => prev != null;
}
