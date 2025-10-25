class ApiConstants {
  // Base URL - Change this for different environments
  // Development (Android Emulator): http://10.0.2.2:8080/api
  // Development (iOS Simulator): http://localhost:8080/api
  // Development (Physical Device on same network): http://<YOUR_LOCAL_IP>:8080/api (e.g., http://192.168.1.100:8080/api)
  // Production / Cloud Backend: https://synapticz-backend-go-801753403122.asia-southeast1.run.app/api

  static const String baseUrl = 'https://synapticz-backend-go-801753403122.asia-southeast1.run.app/api'; // Cloud backend

  // Auth Endpoints
  static const String checkEmail = '/auth/check-email';
  static const String sendVerification = '/auth/users/send-verification';
  static const String createUser = '/auth/users/';
  static const String verifyEmail = '/auth/users/verify';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google-login';
  static const String getUser = '/auth/users';
  static const String updateUser = '/auth/users';
  static const String resendVerification = '/auth/users/resend-verification';

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
}
