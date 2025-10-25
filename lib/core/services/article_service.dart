import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ArticleService {
  static const String baseUrl = ApiConstants.baseUrl;

  /// Get all articles with pagination and filtering
  static Future<Map<String, dynamic>> getArticles({
    int page = 1,
    int limit = 10,
    String? subject,
    String? language,
    String? search,
    bool? verified,
    bool myArticles = false,
    bool showPublic = false,
    bool showPrivate = false,
    bool showShared = false,
  }) async {
    final token = StorageService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (subject != null) 'subject': subject,
      if (language != null) 'language': language,
      if (search != null) 'search': search,
      if (verified != null) 'verified': verified.toString(),
      if (myArticles) 'myArticles': 'true',
      if (showPublic) 'showPublic': 'true',
      if (showPrivate) 'showPrivate': 'true',
      if (showShared) 'showShared': 'true',
    };

    final uri = Uri.parse('$baseUrl/articles/').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'articles': (data['data'] as List<dynamic>?)
                ?.map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        'pagination': data['pagination'] as Map<String, dynamic>? ?? {},
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get articles');
    }
  }

  /// Get public articles (no authentication required)
  static Future<Map<String, dynamic>> getPublicArticles({
    int page = 1,
    int limit = 10,
    String? subject,
    String? language,
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (subject != null) 'subject': subject,
      if (language != null) 'language': language,
      if (search != null) 'search': search,
    };

    final uri = Uri.parse('$baseUrl/articles/public').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'articles': (data['data'] as List<dynamic>?)
                ?.map((item) => ArticleModel.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        'pagination': data['pagination'] as Map<String, dynamic>? ?? {},
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get public articles');
    }
  }

  /// Get article by ID
  static Future<ArticleModel> getArticleById(String articleId) async {
    final token = StorageService.getToken();

    final headers = token != null
        ? {'Authorization': 'Bearer $token'}
        : <String, String>{};

    final response = await http.get(
      Uri.parse('$baseUrl/articles/$articleId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ArticleModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get article');
    }
  }
}
