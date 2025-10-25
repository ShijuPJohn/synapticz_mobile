import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/test_history_model.dart';
import '../../../core/services/test_session_service.dart';
import '../../widgets/action_card.dart';
import '../../widgets/main_scaffold.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<TestHistoryModel> _recentTests = [];

  @override
  void initState() {
    super.initState();
    _loadRecentTests();
  }

  Future<void> _loadRecentTests() async {
    try {
      final result = await TestSessionService.getTestHistory(
        page: 1,
        limit: 5, // Get 5 most recent tests
      );

      if (mounted) {
        setState(() {
          _recentTests = List<TestHistoryModel>.from(result['history']);
        });
      }
    } catch (e) {
      // Silently fail - just don't show recent tests section
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Synapticz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming Soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroDark,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Synapticz',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Supercharge your learning with active recall, spaced repetition, and personalized quizzes powered by science and AI.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get Started',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // SynLearn Card
                  ActionCard(
                    icon: Icons.auto_fix_high,
                    title: 'SynLearn',
                    description: 'AI-powered personalized learning paths that adapt to your progress and learning style',
                    gradient: AppColors.synlearnGradient,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SynLearn - Coming Soon')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // QuizGen Card
                  ActionCard(
                    icon: Icons.auto_awesome,
                    title: 'QuizGen',
                    description: 'Generate custom quizzes instantly on any topic using advanced AI technology',
                    gradient: AppColors.quizgenGradient,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QuizGen - Coming Soon')),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ArticleGen Card
                  ActionCard(
                    icon: Icons.menu_book,
                    title: 'ArticleGen',
                    description: 'Create comprehensive study materials and articles with AI-powered content generation',
                    gradient: AppColors.articlegenGradient,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ArticleGen - Coming Soon')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recent Tests Section
            if (_recentTests.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Tests',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/test-history');
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._recentTests.take(3).map((test) => _RecentTestCard(test: test)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RecentTestCard extends StatelessWidget {
  final TestHistoryModel test;

  const _RecentTestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final statusColor = test.finished
        ? Colors.green
        : test.started
            ? Colors.orange
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (test.finished) {
            Navigator.pushNamed(
              context,
              '/test-results',
              arguments: {
                'sessionId': test.id,
              },
            );
          } else {
            Navigator.pushNamed(
              context,
              '/test-session',
              arguments: {
                'sessionId': test.id,
              },
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  test.finished ? Icons.check_circle : Icons.play_circle_outline,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.qSetName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (test.finished) ...[
                          Icon(Icons.assessment, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${test.scoredMarks.toStringAsFixed(0)}/${test.totalMarks.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${test.percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ] else ...[
                          Icon(Icons.play_arrow, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            test.started ? 'Resume' : 'Start',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          DateFormat('MMM dd').format(test.startedTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
