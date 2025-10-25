class ArticleModel {
  final String id;
  final String title;
  final String subject;
  final String language;
  final String? description;
  final String contentExcerpt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String slug;
  final bool verified;
  final bool toBePublished;
  final int userId;
  final String authorName;
  final String? aiModelUsed;
  final int? iterationNumber;
  final String visibility;
  final String accessLevel;
  final String creatorType;
  final String? exam;
  final String? associatedResource;

  ArticleModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.language,
    this.description,
    required this.contentExcerpt,
    required this.createdAt,
    this.updatedAt,
    required this.slug,
    required this.verified,
    required this.toBePublished,
    required this.userId,
    required this.authorName,
    this.aiModelUsed,
    this.iterationNumber,
    required this.visibility,
    required this.accessLevel,
    required this.creatorType,
    this.exam,
    this.associatedResource,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      language: json['language'] as String? ?? '',
      description: json['description'] as String?,
      contentExcerpt: json['content_excerpt'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      slug: json['slug'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      toBePublished: json['to_be_published'] as bool? ?? false,
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id'].toString()) ?? 0,
      authorName: json['author_name'] as String? ?? '',
      aiModelUsed: json['ai_model_used'] as String?,
      iterationNumber: json['iteration_number'] is int
          ? json['iteration_number'] as int
          : int.tryParse(json['iteration_number']?.toString() ?? ''),
      visibility: json['visibility'] as String? ?? 'public',
      accessLevel: json['access_level'] as String? ?? 'free',
      creatorType: json['creator_type'] as String? ?? 'community',
      exam: json['exam'] as String?,
      associatedResource: json['associated_resource'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'language': language,
      'description': description,
      'content_excerpt': contentExcerpt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'slug': slug,
      'verified': verified,
      'to_be_published': toBePublished,
      'user_id': userId,
      'author_name': authorName,
      'ai_model_used': aiModelUsed,
      'iteration_number': iterationNumber,
      'visibility': visibility,
      'access_level': accessLevel,
      'creator_type': creatorType,
      'exam': exam,
      'associated_resource': associatedResource,
    };
  }
}
