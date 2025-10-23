import 'package:flutter/material.dart';
import '../../core/models/quiz_model.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final VoidCallback onTap;

  const QuizCard({
    super.key,
    required this.quiz,
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
            // Cover Image (if available)
            if (quiz.coverImage != null && quiz.coverImage!.isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: NetworkImage(quiz.coverImage!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Image failed to load, will show placeholder color
                    },
                  ),
                ),
              ),

            // Content
            Padding(
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
                  const SizedBox(height: 8),

                  // Badges Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Subject Badge
                      _buildBadge(
                        context,
                        quiz.subject,
                        Colors.blue,
                        Icons.book_outlined,
                      ),

                      // Language Badge
                      _buildBadge(
                        context,
                        quiz.language,
                        Colors.green,
                        Icons.language,
                      ),

                      // Questions Count Badge
                      _buildBadge(
                        context,
                        '${quiz.totalQuestions} Qs',
                        Colors.purple,
                        Icons.quiz_outlined,
                      ),

                      // Access Level Badge
                      if (quiz.accessLevel == 'premium')
                        _buildBadge(
                          context,
                          'Premium',
                          Colors.amber,
                          Icons.star,
                        ),

                      // Verified Badge
                      if (quiz.verified)
                        _buildBadge(
                          context,
                          'Verified',
                          Colors.teal,
                          Icons.verified,
                        ),

                      // Visibility Badge
                      if (quiz.visibility == 'private')
                        _buildBadge(
                          context,
                          'Private',
                          Colors.grey,
                          Icons.lock_outline,
                        ),
                    ],
                  ),

                  // Exam Badge (if available)
                  if (quiz.exam != null && quiz.exam!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildBadge(
                      context,
                      quiz.exam!,
                      Colors.orange,
                      Icons.school_outlined,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Creator and Stats Row
                  Row(
                    children: [
                      // Creator
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          quiz.createdByName.isNotEmpty
                              ? quiz.createdByName
                              : quiz.createdByEmail,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Test Sessions Taken
                      Icon(Icons.play_circle_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${quiz.testSessionsTaken}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),

                  // Mode Badge (Practice/Exam)
                  if (quiz.mode == 'exam' && quiz.timeDuration != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${quiz.timeDuration} min',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '• Exam Mode',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
