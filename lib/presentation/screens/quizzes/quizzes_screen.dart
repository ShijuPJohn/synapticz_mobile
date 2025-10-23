import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/main_scaffold.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/quiz_card.dart';

class QuizzesScreen extends ConsumerStatefulWidget {
  const QuizzesScreen({super.key});

  @override
  ConsumerState<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends ConsumerState<QuizzesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Load quizzes when screen opens
    Future.microtask(() => ref.read(quizProvider.notifier).loadQuizzes());

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(quizProvider.notifier).loadMoreQuizzes();
    }
  }

  void _showFilterDialog() {
    final currentState = ref.read(quizProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Quizzes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subject',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildFilterChips(
                ['Mathematics', 'Science', 'History', 'English', 'Geography'],
                currentState.subjectFilter,
                (value) => ref.read(quizProvider.notifier).setSubjectFilter(value),
              ),
              const SizedBox(height: 16),
              Text(
                'Exam',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildFilterChips(
                ['JEE', 'NEET', 'SSC', 'UPSC', 'GATE'],
                currentState.examFilter,
                (value) => ref.read(quizProvider.notifier).setExamFilter(value),
              ),
              const SizedBox(height: 16),
              Text(
                'Language',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildFilterChips(
                ['English', 'Hindi', 'Tamil', 'Telugu', 'Malayalam'],
                currentState.languageFilter,
                (value) => ref.read(quizProvider.notifier).setLanguageFilter(value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(quizProvider.notifier).clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    List<String> options,
    String? selectedValue,
    Function(String?) onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            onSelected(selected ? option : null);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search quizzes...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  ref.read(quizProvider.notifier).setSearchQuery(value);
                },
              )
            : const Text('Quizzes'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(quizProvider.notifier).setSearchQuery(null);
                }
              });
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (quizState.subjectFilter != null ||
                    quizState.examFilter != null ||
                    quizState.languageFilter != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(
              quizState.showMyQuizzes ? Icons.person : Icons.person_outline,
              color: quizState.showMyQuizzes ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              ref.read(quizProvider.notifier).toggleMyQuizzes();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(quizProvider.notifier).refreshQuizzes();
        },
        child: quizState.isLoading && quizState.quizzes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : quizState.error != null && quizState.quizzes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load quizzes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quizState.error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(quizProvider.notifier).loadQuizzes();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : quizState.quizzes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              quizState.showMyQuizzes ? 'No quizzes yet' : 'No quizzes found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              quizState.showMyQuizzes
                                  ? 'Create your first quiz'
                                  : 'Try adjusting your filters',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: quizState.quizzes.length + (quizState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == quizState.quizzes.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final quiz = quizState.quizzes[index];
                          return QuizCard(
                            quiz: quiz,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/quiz-detail',
                                arguments: quiz.id,
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
