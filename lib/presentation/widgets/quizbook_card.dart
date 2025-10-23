import 'package:flutter/material.dart';
import '../../core/models/quizbook_model.dart';
import 'package:intl/intl.dart';

class QuizBookCard extends StatelessWidget {
  final QuizBookModel quizBook;
  final VoidCallback onTap;

  const QuizBookCard({
    super.key,
    required this.quizBook,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image (if available) or gradient placeholder
            _buildCoverImage(context),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    quizBook.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description (if available)
                  if (quizBook.description != null && quizBook.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      quizBook.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Quiz Count Badge
                      _buildBadge(
                        context,
                        '${quizBook.quizCount} Quizzes',
                        Colors.purple,
                        Icons.quiz_outlined,
                      ),

                      // Visibility Badge
                      _buildVisibilityBadge(context),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Footer Row (Created date)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Created ${_formatDate(quizBook.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (quizBook.coverImage != null && quizBook.coverImage!.isNotEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          image: DecorationImage(
            image: NetworkImage(quizBook.coverImage!),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // Image failed to load, will show gradient fallback
            },
          ),
        ),
      );
    } else {
      // Gradient placeholder with book icon
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.menu_book,
            size: 48,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
    }
  }

  Widget _buildVisibilityBadge(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (quizBook.visibility) {
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
        label = quizBook.visibility;
    }

    return _buildBadge(context, label, color, icon);
  }

  Widget _buildBadge(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
  ) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
