import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/action_card.dart';
import '../../widgets/main_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

            // Featured Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Quizzes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to quizzes tab
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Placeholder for featured quizzes
                  _FeaturedQuizPlaceholder(),
                  const SizedBox(height: 12),
                  _FeaturedQuizPlaceholder(),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeaturedQuizPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.quiz, color: AppColors.primary),
        ),
        title: const Text(
          'Sample Quiz',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('10 Questions • 15 min'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz detail - Coming Soon')),
          );
        },
      ),
    );
  }
}
