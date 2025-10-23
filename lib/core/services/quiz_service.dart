import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/quiz_model.dart';
import 'storage_service.dart';

class QuizService {
  // Fetch quizzes with pagination and filters
  static Future<QuizResponse> fetchQuizzes({
    int page = 1,
    int limit = 10,
    String? subject,
    String? exam,
    String? language,
    String? tags,
    String? search,
    bool? showPublic,
    bool? showPrivate,
    bool? showShared,
    bool? myQuizzes,
    bool? verified,
  }) async {
    try {
      final token = StorageService.getToken();

      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (subject != null && subject.isNotEmpty) params['subject'] = subject;
      if (exam != null && exam.isNotEmpty) params['exam'] = exam;
      if (language != null && language.isNotEmpty) params['language'] = language;
      if (tags != null && tags.isNotEmpty) params['tags'] = tags;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (showPublic != null) params['showPublic'] = showPublic.toString();
      if (showPrivate != null) params['showPrivate'] = showPrivate.toString();
      if (showShared != null) params['showShared'] = showShared.toString();
      if (myQuizzes != null) params['myQuizzes'] = myQuizzes.toString();
      if (verified != null) params['verified'] = verified.toString();

      final uri = Uri.parse('${ApiConstants.baseUrl}/questionsets').replace(
        queryParameters: params,
      );

      final headers = <String, String>{
        'Content-Type': ApiConstants.contentTypeJson,
      };
      if (token != null) {
        headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
      }

      developer.log('Fetching quizzes: $uri', name: 'QuizService');

      final response = await http.get(uri, headers: headers);

      developer.log('Fetch Quizzes Status: ${response.statusCode}', name: 'QuizService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return QuizResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch quizzes');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to fetch quizzes: ${e.toString()}');
    }
  }

  // Fetch public quizzes (no auth required)
  static Future<QuizResponse> fetchPublicQuizzes({
    int page = 1,
    int limit = 10,
    String? subject,
    String? exam,
    String? language,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (subject != null && subject.isNotEmpty) params['subject'] = subject;
      if (exam != null && exam.isNotEmpty) params['exam'] = exam;
      if (language != null && language.isNotEmpty) params['language'] = language;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('${ApiConstants.baseUrl}/questionsets/public').replace(
        queryParameters: params,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': ApiConstants.contentTypeJson},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return QuizResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch public quizzes');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to fetch public quizzes: ${e.toString()}');
    }
  }

  // Fetch verified quizzes
  static Future<QuizResponse> fetchVerifiedQuizzes({
    int page = 1,
    int limit = 10,
    String? subject,
    String? exam,
    String? language,
    String? search,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (subject != null && subject.isNotEmpty) params['subject'] = subject;
      if (exam != null && exam.isNotEmpty) params['exam'] = exam;
      if (language != null && language.isNotEmpty) params['language'] = language;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('${ApiConstants.baseUrl}/questionsets/verified').replace(
        queryParameters: params,
      );

      final token = StorageService.getToken();
      final headers = <String, String>{
        'Content-Type': ApiConstants.contentTypeJson,
      };
      if (token != null) {
        headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return QuizResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch verified quizzes');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to fetch verified quizzes: ${e.toString()}');
    }
  }

  // Get single quiz by ID
  static Future<QuizModel> getQuizById(String id) async {
    try {
      final token = StorageService.getToken();

      final headers = <String, String>{
        'Content-Type': ApiConstants.contentTypeJson,
      };
      if (token != null) {
        headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/questionsets/$id'),
        headers: headers,
      );

      developer.log('Get Quiz Status: ${response.statusCode}', name: 'QuizService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return QuizModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get quiz');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to get quiz: ${e.toString()}');
    }
  }
}
