import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/quizbook_model.dart';
import '../../../core/services/quizbook_service.dart';
import 'package:intl/intl.dart';

class QuizBookDetailScreen extends ConsumerStatefulWidget {
  final String quizBookId;

  const QuizBookDetailScreen({
    super.key,
    required this.quizBookId,
  });

  @override
  ConsumerState<QuizBookDetailScreen> createState() => _QuizBookDetailScreenState();
}

class _QuizBookDetailScreenState extends ConsumerState<QuizBookDetailScreen> {
  QuizBookModel? _quizBook;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuizBookDetails();
  }

  Future<void> _loadQuizBookDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final quizBook = await QuizBookService.getQuizBookById(widget.quizBookId);
      setState(() {
        _quizBook = quizBook;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openQuiz(QuizBookQuizModel quiz) {
    Navigator.pushNamed(
      context,
      '/quiz-detail',
      arguments: quiz.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuizBook Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load quizbook',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadQuizBookDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _quizBook == null
                  ? const Center(child: Text('QuizBook not found'))
                  : RefreshIndicator(
                      onRefresh: _loadQuizBookDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover Image
                            _buildCoverImage(context),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              _quizBook!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),

                            // Visibility Badge
                            _buildVisibilityBadge(context),
                            const SizedBox(height: 16),

                            // Description
                            if (_quizBook!.description != null && _quizBook!.description!.isNotEmpty) ...[
                              Text(
                                _quizBook!.description!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Info Row
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Created ${DateFormat('MMM dd, yyyy').format(_quizBook!.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const Spacer(),
                                Icon(Icons.quiz_outlined, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${_quizBook!.quizCount} Quizzes',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Quizzes Section
                            Row(
                              children: [
                                Text(
                                  'Quizzes',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_quizBook!.quizzes?.length ?? 0}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Quiz List
                            if (_quizBook!.quizzes == null || _quizBook!.quizzes!.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No quizzes in this book yet',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _quizBook!.quizzes!.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final quiz = _quizBook!.quizzes![index];
                                  return _buildQuizCard(context, quiz);
                                },
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (_quizBook!.coverImage != null && _quizBook!.coverImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _quizBook!.coverImage!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildGradientPlaceholder(context);
          },
        ),
      );
    } else {
      return _buildGradientPlaceholder(context);
    }
  }

  Widget _buildGradientPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book,
          size: 64,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildVisibilityBadge(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (_quizBook!.visibility) {
      case 'public':
        color = Colors.green;
        icon = Icons.public;
        label = 'Public';
        break;
      case 'private':
        color = Colors.red;
        icon = Icons.lock_outline;
        label = 'Private';
        break;
      case 'shared':
        color = Colors.blue;
        icon = Icons.share;
        label = 'Shared';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = _quizBook!.visibility;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizBookQuizModel quiz) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openQuiz(quiz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                quiz.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (quiz.description != null && quiz.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  quiz.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),

              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (quiz.subject != null)
                    _buildBadge(
                      Icons.book_outlined,
                      quiz.subject!,
                      Colors.blue,
                    ),
                  if (quiz.exam != null)
                    _buildBadge(
                      Icons.school_outlined,
                      quiz.exam!,
                      Colors.orange,
                    ),
                  if (quiz.difficulty != null)
                    _buildBadge(
                      Icons.psychology,
                      'Level ${quiz.difficulty}',
                      Colors.purple,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
