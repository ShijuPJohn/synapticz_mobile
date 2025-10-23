import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/quizbook_model.dart';
import 'storage_service.dart';

class QuizBookService {
  // Fetch quizbooks with pagination and filters
  static Future<QuizBookResponse> fetchQuizBooks({
    int page = 1,
    int limit = 20,
    String? search,
    bool? showPublic,
    bool? showPrivate,
    bool? showShared,
    bool? myQuizBooks,
  }) async {
    try {
      final token = StorageService.getToken();

      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) params['search'] = search;
      if (showPublic != null) params['showPublic'] = showPublic.toString();
      if (showPrivate != null) params['showPrivate'] = showPrivate.toString();
      if (showShared != null) params['showShared'] = showShared.toString();
      if (myQuizBooks != null) params['myQuizBooks'] = myQuizBooks.toString();

      final uri = Uri.parse('${ApiConstants.baseUrl}/quiz-books/').replace(
        queryParameters: params,
      );

      final headers = <String, String>{
        'Content-Type': ApiConstants.contentTypeJson,
      };
      if (token != null) {
        headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
      }

      developer.log('Fetching quizbooks: $uri', name: 'QuizBookService');

      final response = await http.get(uri, headers: headers);

      developer.log('Fetch QuizBooks Status: ${response.statusCode}', name: 'QuizBookService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return QuizBookResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch quizbooks');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to fetch quizbooks: ${e.toString()}');
    }
  }

  // Get single quizbook by ID with associated quizzes
  static Future<QuizBookModel> getQuizBookById(String id) async {
    try {
      final token = StorageService.getToken();

      final headers = <String, String>{
        'Content-Type': ApiConstants.contentTypeJson,
      };
      if (token != null) {
        headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/quiz-books/$id'),
        headers: headers,
      );

      developer.log('Get QuizBook Status: ${response.statusCode}', name: 'QuizBookService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // The API returns quiz_book and quizzes separately
        final quizBookData = data['quiz_book'] as Map<String, dynamic>;
        if (data['quizzes'] != null) {
          quizBookData['quizzes'] = data['quizzes'];
        }
        return QuizBookModel.fromJson(quizBookData);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get quizbook');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to get quizbook: ${e.toString()}');
    }
  }

  // Create quizbook
  static Future<QuizBookModel> createQuizBook({
    required String name,
    String? urlSlug,
    String? description,
    String? coverImage,
    String visibility = 'public',
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final body = <String, dynamic>{
        'name': name,
        'visibility': visibility,
      };
      if (urlSlug != null) body['url_slug'] = urlSlug;
      if (description != null) body['description'] = description;
      if (coverImage != null) body['cover_image'] = coverImage;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/quiz-books/'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          ApiConstants.authorization: '${ApiConstants.bearer} $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return QuizBookModel.fromJson(data['quiz_book'] as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create quizbook');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to create quizbook: ${e.toString()}');
    }
  }

  // Update quizbook
  static Future<QuizBookModel> updateQuizBook({
    required String id,
    String? name,
    String? urlSlug,
    String? description,
    String? coverImage,
    String? visibility,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (urlSlug != null) body['url_slug'] = urlSlug;
      if (description != null) body['description'] = description;
      if (coverImage != null) body['cover_image'] = coverImage;
      if (visibility != null) body['visibility'] = visibility;

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/quiz-books/$id'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          ApiConstants.authorization: '${ApiConstants.bearer} $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return QuizBookModel.fromJson(data['quiz_book'] as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update quizbook');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to update quizbook: ${e.toString()}');
    }
  }

  // Delete quizbook
  static Future<void> deleteQuizBook(String id) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/quiz-books/$id'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          ApiConstants.authorization: '${ApiConstants.bearer} $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete quizbook');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to delete quizbook: ${e.toString()}');
    }
  }
}
