import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/test_session_model.dart';
import '../models/test_history_model.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class TestSessionService {
  static const String baseUrl = ApiConstants.baseUrl;

  /// Start a new test session
  static Future<String> startTestSession({
    required String questionSetId,
    required bool randomizeQuestions,
    required String mode,
    required int secondsPerQuestion,
    required int timeCapSeconds,
    required bool shareWithCreator,
  }) async {
    final token = StorageService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/test_session'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'question_set_id': questionSetId,
        'randomize_questions': randomizeQuestions,
        'mode': mode,
        'seconds_per_question': secondsPerQuestion,
        'time_cap_seconds': timeCapSeconds,
        'share_with_creator': shareWithCreator,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['test_session'] as String;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to start test session');
    }
  }

  /// Resume an existing test session
  static Future<TestSessionModel> resumeTestSession(String sessionId) async {
    final token = StorageService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/test_session/$sessionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // The entire response contains test_session, questions, question_set, etc.
      return TestSessionModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to resume test session');
    }
  }

  /// Save answer for a question - uses PUT to update session
  static Future<void> saveAnswer({
    required String sessionId,
    required int questionId,
    required List<int> selectedOptions,
    required int currentQuestionIndex,
    int? remainingTime,
  }) async {
    final token = StorageService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final requestBody = {
      'question_answer_data': {
        questionId.toString(): {
          'selected_answer_list': selectedOptions,
          'answered': true, // Explicitly set to true when saving answer
        }
      },
      'current_question_index': currentQuestionIndex,
      if (remainingTime != null) 'remaining_time': remainingTime,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/test_session/$sessionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to save answer');
    }
  }

  /// Submit the test session - uses finish endpoint
  static Future<Map<String, dynamic>> submitTestSession(String sessionId) async {
    final token = StorageService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/test_session/finish/$sessionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to submit test session');
    }
  }

  /// Get user's test history
  static Future<Map<String, dynamic>> getTestHistory({
    int page = 1,
    int limit = 20,
    String? subject,
    String? exam,
    String? date,
  }) async {
    final token = StorageService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (subject != null) 'subject': subject,
      if (exam != null) 'exam': exam,
      if (date != null) 'date': date,
    };

    final uri = Uri.parse('$baseUrl/test_session/history').replace(
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
        'history': (data['history'] as List<dynamic>?)
                ?.map((item) => TestHistoryModel.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        'page': data['page'] ?? page,
        'limit': data['limit'] ?? limit,
        'count': data['count'] ?? 0,
        'hasMore': data['hasMore'] ?? false,
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get test history');
    }
  }
}
