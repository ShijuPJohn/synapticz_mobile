import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/quiz_model.dart';
import '../../core/services/quiz_service.dart';

// Quiz state
class QuizState {
  final List<QuizModel> quizzes;
  final PaginationInfo? pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? searchQuery;
  final String? subjectFilter;
  final String? examFilter;
  final String? languageFilter;
  final bool showMyQuizzes;
  final String? visibilityFilter; // 'public', 'private', 'shared', or null for all

  QuizState({
    this.quizzes = const [],
    this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchQuery,
    this.subjectFilter,
    this.examFilter,
    this.languageFilter,
    this.showMyQuizzes = false,
    this.visibilityFilter,
  });

  QuizState copyWith({
    List<QuizModel>? quizzes,
    PaginationInfo? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? searchQuery,
    String? subjectFilter,
    String? examFilter,
    String? languageFilter,
    bool? showMyQuizzes,
    String? visibilityFilter,
  }) {
    return QuizState(
      quizzes: quizzes ?? this.quizzes,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      subjectFilter: subjectFilter ?? this.subjectFilter,
      examFilter: examFilter ?? this.examFilter,
      languageFilter: languageFilter ?? this.languageFilter,
      showMyQuizzes: showMyQuizzes ?? this.showMyQuizzes,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
    );
  }
}

// Quiz notifier
class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState());

  Future<void> loadQuizzes({
    int page = 1,
    bool append = false,
  }) async {
    if (append) {
      state = state.copyWith(isLoadingMore: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await QuizService.fetchQuizzes(
        page: page,
        limit: 10,
        search: state.searchQuery,
        subject: state.subjectFilter,
        exam: state.examFilter,
        language: state.languageFilter,
        myQuizzes: state.showMyQuizzes ? true : null,
        showPublic: state.visibilityFilter == 'public' ? true : (state.visibilityFilter == null ? true : null),
        showPrivate: state.visibilityFilter == 'private' ? true : null,
        showShared: state.visibilityFilter == 'shared' ? true : null,
      );

      final newQuizzes = append ? [...state.quizzes, ...response.data] : response.data;

      state = state.copyWith(
        quizzes: newQuizzes,
        pagination: response.pagination,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreQuizzes() async {
    if (state.pagination?.hasNext == true && !state.isLoadingMore) {
      await loadQuizzes(
        page: state.pagination!.next!,
        append: true,
      );
    }
  }

  Future<void> refreshQuizzes() async {
    await loadQuizzes(page: 1, append: false);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    loadQuizzes(page: 1);
  }

  void setSubjectFilter(String? subject) {
    state = state.copyWith(subjectFilter: subject);
    loadQuizzes(page: 1);
  }

  void setExamFilter(String? exam) {
    state = state.copyWith(examFilter: exam);
    loadQuizzes(page: 1);
  }

  void setLanguageFilter(String? language) {
    state = state.copyWith(languageFilter: language);
    loadQuizzes(page: 1);
  }

  void toggleMyQuizzes() {
    state = state.copyWith(showMyQuizzes: !state.showMyQuizzes);
    loadQuizzes(page: 1);
  }

  void setVisibilityFilter(String? visibility) {
    state = state.copyWith(visibilityFilter: visibility);
    loadQuizzes(page: 1);
  }

  void clearFilters() {
    state = QuizState();
    loadQuizzes(page: 1);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});
