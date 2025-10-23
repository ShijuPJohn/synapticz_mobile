import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await _prefs?.setString(ApiConstants.tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(ApiConstants.tokenKey);
  }

  static Future<void> removeToken() async {
    await _prefs?.remove(ApiConstants.tokenKey);
  }

  // User data management
  static Future<void> saveUserId(int userId) async {
    await _prefs?.setInt(ApiConstants.userIdKey, userId);
  }

  static int? getUserId() {
    return _prefs?.getInt(ApiConstants.userIdKey);
  }

  static Future<void> saveUserEmail(String email) async {
    await _prefs?.setString(ApiConstants.userEmailKey, email);
  }

  static String? getUserEmail() {
    return _prefs?.getString(ApiConstants.userEmailKey);
  }

  static Future<void> saveUserName(String name) async {
    await _prefs?.setString(ApiConstants.userNameKey, name);
  }

  static String? getUserName() {
    return _prefs?.getString(ApiConstants.userNameKey);
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}
