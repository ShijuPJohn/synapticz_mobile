import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/quizbook_model.dart';
import '../../core/services/quizbook_service.dart';

// QuizBook state
class QuizBookState {
  final List<QuizBookModel> quizBooks;
  final PaginationInfo? pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? searchQuery;
  final bool showMyQuizBooks;

  QuizBookState({
    this.quizBooks = const [],
    this.pagination,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.searchQuery,
    this.showMyQuizBooks = false,
  });

  QuizBookState copyWith({
    List<QuizBookModel>? quizBooks,
    PaginationInfo? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? searchQuery,
    bool? showMyQuizBooks,
  }) {
    return QuizBookState(
      quizBooks: quizBooks ?? this.quizBooks,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      showMyQuizBooks: showMyQuizBooks ?? this.showMyQuizBooks,
    );
  }
}

// QuizBook notifier
class QuizBookNotifier extends StateNotifier<QuizBookState> {
  QuizBookNotifier() : super(QuizBookState());

  Future<void> loadQuizBooks({
    int page = 1,
    bool append = false,
  }) async {
    if (append) {
      state = state.copyWith(isLoadingMore: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await QuizBookService.fetchQuizBooks(
        page: page,
        limit: 20,
        search: state.searchQuery,
        myQuizBooks: state.showMyQuizBooks ? true : null,
        showPublic: !state.showMyQuizBooks ? true : null,
      );

      final newQuizBooks = append ? [...state.quizBooks, ...response.quizBooks] : response.quizBooks;

      state = state.copyWith(
        quizBooks: newQuizBooks,
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

  Future<void> loadMoreQuizBooks() async {
    if (state.pagination?.hasNext == true && !state.isLoadingMore) {
      await loadQuizBooks(
        page: state.pagination!.next!,
        append: true,
      );
    }
  }

  Future<void> refreshQuizBooks() async {
    await loadQuizBooks(page: 1, append: false);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
    loadQuizBooks(page: 1);
  }

  void toggleMyQuizBooks() {
    state = state.copyWith(showMyQuizBooks: !state.showMyQuizBooks);
    loadQuizBooks(page: 1);
  }

  void clearFilters() {
    state = QuizBookState();
    loadQuizBooks(page: 1);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final quizBookProvider = StateNotifierProvider<QuizBookNotifier, QuizBookState>((ref) {
  return QuizBookNotifier();
});
