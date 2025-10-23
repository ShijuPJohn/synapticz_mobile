import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/profile_overview_model.dart';
import 'storage_service.dart';

class ProfileService {
  // Get profile overview with activity stats
  static Future<ProfileOverviewModel> getProfileOverview() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      // Get timezone offset (e.g., "Asia/Kolkata" or "+05:30")
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60).abs();
      final tz = '${hours >= 0 ? '+' : ''}${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/auth/users/overview?tz=$tz'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          ApiConstants.authorization: '${ApiConstants.bearer} $token',
        },
      );

      developer.log('Profile Overview Status: ${response.statusCode}', name: 'ProfileService');
      developer.log('Profile Overview Body: ${response.body}', name: 'ProfileService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ProfileOverviewModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get profile overview');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to get profile overview: ${e.toString()}');
    }
  }

  // Change password
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/users/change-password'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          ApiConstants.authorization: '${ApiConstants.bearer} $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      developer.log('Change Password Status: ${response.statusCode}', name: 'ProfileService');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }
}
