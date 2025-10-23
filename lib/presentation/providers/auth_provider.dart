import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (StorageService.isLoggedIn()) {
      try {
        final user = await AuthService.getCurrentUser();
        state = state.copyWith(user: user);
      } catch (e) {
        // Token might be expired, clear it
        await AuthService.logout();
      }
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AuthService.login(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AuthService.verifyEmail(email: email, code: code);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile({
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AuthService.updateUser(
        name: name,
        about: about,
        goal: goal,
        profilePic: profilePic,
        country: country,
        countryCode: countryCode,
        mobileNumber: mobileNumber,
        linkedin: linkedin,
        facebook: facebook,
        instagram: instagram,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = AuthState();
  }

  void setUser(UserModel user) {
    state = state.copyWith(user: user, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
