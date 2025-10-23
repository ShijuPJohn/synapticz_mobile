import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  // Check if email exists
  static Future<Map<String, dynamic>> checkEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkEmail}'),
        headers: {'Content-Type': ApiConstants.contentTypeJson},
        body: jsonEncode({'email': email}),
      );

      developer.log('Check Email Status: ${response.statusCode}', name: 'AuthService');
      developer.log('Check Email Body: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw Exception('Invalid response format');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Failed to check email');
        } catch (e) {
          throw Exception('Failed to check email (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Send OTP/Verification code
  static Future<void> sendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.sendVerification}'),
        headers: {'Content-Type': ApiConstants.contentTypeJson},
        body: jsonEncode({'email': email}),
      );

      developer.log('Send Verification Status: ${response.statusCode}', name: 'AuthService');
      developer.log('Send Verification Body: ${response.body}', name: 'AuthService');

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Failed to send verification code');
        } catch (e) {
          throw Exception('Failed to send code (${response.statusCode})');
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Create new user (signup)
  static Future<Map<String, dynamic>> createUser({
    required String email,
    String? referralCode,
  }) async {
    try {
      final body = <String, dynamic>{'email': email};
      if (referralCode != null && referralCode.isNotEmpty) {
        body['referral_code'] = referralCode;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createUser}'),
        headers: {'Content-Type': ApiConstants.contentTypeJson},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Verify email with code
  static Future<UserModel> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyEmail}'),
        headers: {'Content-Type': ApiConstants.contentTypeJson},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      // Log response for debugging
      developer.log('Verify Email Status: ${response.statusCode}', name: 'AuthService');
      developer.log('Verify Email Body: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          // Check if response has 'user' field or if the data itself is the user
          Map<String, dynamic>? user;
          String? token;

          if (data.containsKey('user')) {
            // Response format: { "token": "...", "user": {...} }
            user = data['user'] as Map<String, dynamic>?;
            token = data['token'] as String?;
          } else if (data.containsKey('token') && (data.containsKey('id') || data.containsKey('user_id'))) {
            // Response format: { "token": "...", "id": 1, "email": "...", ... }
            // or: { "token": "...", "user_id": 1, "name": "...", ... }
            user = Map<String, dynamic>.from(data);
            token = user.remove('token') as String?;

            // Convert user_id to id for consistency
            if (user.containsKey('user_id') && !user.containsKey('id')) {
              user['id'] = user['user_id'];
            }

            // Add email from parameter if not present in response
            if (!user.containsKey('email') && email.isNotEmpty) {
              user['email'] = email;
            }
          } else {
            // Unknown format
            developer.log('Unknown verify email response format. Keys: ${data.keys.toList()}', name: 'AuthService');
            throw Exception('Unexpected response format');
          }

          // Save token
          if (token != null && token.isNotEmpty) {
            await StorageService.saveToken(token);
          }

          // Save user data
          if (user != null) {
            if (user['id'] != null) {
              await StorageService.saveUserId(user['id'] as int);
            }
            if (user['email'] != null) {
              await StorageService.saveUserEmail(user['email'] as String);
            }
            if (user['name'] != null) {
              await StorageService.saveUserName(user['name'] as String);
            }

            return UserModel.fromJson({
              ...user,
              'token': token,
            });
          }

          throw Exception('User data not found in response');
        } catch (e) {
          // JSON parsing failed
          throw Exception('Invalid response format: ${e.toString()}');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Failed to verify email');
        } catch (e) {
          throw Exception('Verification failed (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Login with email and password
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': ApiConstants.contentTypeJson},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      // Log response for debugging
      developer.log('Login Status: ${response.statusCode}', name: 'AuthService');
      developer.log('Login Body: ${response.body}', name: 'AuthService');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;

          // Check if response has 'user' field or if the data itself is the user
          Map<String, dynamic>? user;
          String? token;

          if (data.containsKey('user')) {
            // Response format: { "token": "...", "user": {...} }
            user = data['user'] as Map<String, dynamic>?;
            token = data['token'] as String?;
          } else if (data.containsKey('token') && (data.containsKey('id') || data.containsKey('user_id'))) {
            // Response format: { "token": "...", "id": 1, "email": "...", ... }
            // or: { "token": "...", "user_id": 1, "name": "...", ... }
            user = Map<String, dynamic>.from(data);
            token = user.remove('token') as String?;

            // Convert user_id to id for consistency
            if (user.containsKey('user_id') && !user.containsKey('id')) {
              user['id'] = user['user_id'];
            }

            // Add email from token or use a placeholder if not present
            if (!user.containsKey('email') && token != null) {
              // We'll need to get user details separately if email is not in response
              user['email'] = email; // Use the email from login parameter
            }
          } else {
            // Unknown format
            developer.log('Unknown response format. Keys: ${data.keys.toList()}', name: 'AuthService');
            throw Exception('Unexpected response format');
          }

          // Save token
          if (token != null && token.isNotEmpty) {
            await StorageService.saveToken(token);
          }

          // Save user data
          if (user != null) {
            if (user['id'] != null) {
              await StorageService.saveUserId(user['id'] as int);
            }
            if (user['email'] != null) {
              await StorageService.saveUserEmail(user['email'] as String);
            }
            if (user['name'] != null) {
              await StorageService.saveUserName(user['name'] as String);
            }

            return UserModel.fromJson({
              ...user,
              'token': token,
            });
          }

          throw Exception('User data not found in response');
        } catch (e) {
          // JSON parsing failed
          throw Exception('Invalid response format: ${e.toString()}');
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? error['error'] ?? 'Login failed');
        } catch (e) {
          throw Exception('Login failed (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get current user
  static Future<UserModel> getCurrentUser() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getUser}'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          ApiConstants.authorization: '${ApiConstants.bearer} $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;
        return UserModel.fromJson({...user, 'token': token});
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get user');
      }
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Update user profile
  static Future<UserModel> updateUser({
    String? name,
    String? about,
    String? goal,
    String? profilePic,
    String? country,
    String? countryCode,
    String? mobileNumber,
    String? linkedin,
    String? facebook,
    String? instagram,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (about != null) body['about'] = about;
      if (goal != null) body['goal'] = goal;
      if (profilePic != null) body['profile_pic'] = profilePic;
      if (country != null) body['country'] = country;
      if (countryCode != null) body['country_code'] = countryCode;
      if (mobileNumber != null) body['mobile_number'] = mobileNumber;
      if (linkedin != null) body['linkedin'] = linkedin;
      if (facebook != null) body['facebook'] = facebook;
      if (instagram != null) body['instagram'] = instagram;

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateUser}'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          ApiConstants.authorization: '${ApiConstants.bearer} $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = data['user'] as Map<String, dynamic>;

        // Update stored user name if changed
        if (name != null) {
          await StorageService.saveUserName(name);
        }

        return UserModel.fromJson({...user, 'token': token});
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Update failed: ${e.toString()}');
    }
  }

  // Validate referral code
  static Future<Map<String, dynamic>> validateReferralCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/referrals/validate'),
        headers: {'Content-Type': ApiConstants.contentTypeJson},
        body: jsonEncode({'referral_code': code}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Invalid referral code');
      }
    } catch (e) {
      throw Exception('Validation failed: ${e.toString()}');
    }
  }

  // Resend verification code
  static Future<void> resendVerificationCode({
    required int id,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resendVerification}'),
        headers: {'Content-Type': ApiConstants.contentTypeJson},
        body: jsonEncode({
          'id': id,
          'email': email,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to resend code');
      }
    } catch (e) {
      throw Exception('Resend failed: ${e.toString()}');
    }
  }

  // Logout
  static Future<void> logout() async {
    await StorageService.clearAll();
  }
}
