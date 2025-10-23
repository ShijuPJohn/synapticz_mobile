import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/profile_overview_model.dart';
import '../../core/services/profile_service.dart';

// Profile state
class ProfileState {
  final ProfileOverviewModel? overview;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.overview,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileOverviewModel? overview,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      overview: overview ?? this.overview,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState());

  Future<void> loadProfileOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final overview = await ProfileService.getProfileOverview();
      state = state.copyWith(overview: overview, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await ProfileService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
