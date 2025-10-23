import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/main_scaffold.dart';
import '../../providers/quizbook_provider.dart';
import '../../widgets/quizbook_card.dart';

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Load quizbooks when screen opens
    Future.microtask(() => ref.read(quizBookProvider.notifier).loadQuizBooks());

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
      ref.read(quizBookProvider.notifier).loadMoreQuizBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizBookState = ref.watch(quizBookProvider);

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
                  hintText: 'Search quizbooks...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  ref.read(quizBookProvider.notifier).setSearchQuery(value);
                },
              )
            : const Text('QuizBooks'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(quizBookProvider.notifier).setSearchQuery(null);
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              quizBookState.showMyQuizBooks ? Icons.person : Icons.person_outline,
              color: quizBookState.showMyQuizBooks ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              ref.read(quizBookProvider.notifier).toggleMyQuizBooks();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(quizBookProvider.notifier).refreshQuizBooks();
        },
        child: quizBookState.isLoading && quizBookState.quizBooks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : quizBookState.error != null && quizBookState.quizBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load quizbooks',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quizBookState.error!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(quizBookProvider.notifier).loadQuizBooks();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : quizBookState.quizBooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              quizBookState.showMyQuizBooks ? 'No quizbooks yet' : 'No quizbooks found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              quizBookState.showMyQuizBooks
                                  ? 'Create your first quizbook'
                                  : 'Try adjusting your search',
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
                        itemCount: quizBookState.quizBooks.length + (quizBookState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == quizBookState.quizBooks.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final quizBook = quizBookState.quizBooks[index];
                          return QuizBookCard(
                            quizBook: quizBook,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/quizbook-detail',
                                arguments: quizBook.id,
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
