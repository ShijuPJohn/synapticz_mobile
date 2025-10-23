import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/home/home_screen.dart';
import '../screens/quizzes/quizzes_screen.dart';
import '../screens/learn/learn_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'navigation_drawer.dart';

// Provider for current tab index
final currentTabProvider = StateProvider<int>((ref) => 0);

// Global key for accessing the scaffold
final scaffoldKey = GlobalKey<ScaffoldState>();

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    QuizzesScreen(),
    LearnScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz),
      label: 'Quizzes',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: 'Learn',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Move app to background when back button is pressed
        SystemNavigator.pop();
      },
      child: Scaffold(
        key: scaffoldKey,
        drawer: const AppNavigationDrawer(),
        body: _screens[currentIndex],
        bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        destinations: _destinations,
        animationDuration: const Duration(milliseconds: 300),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Create New',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                _CreateOption(
                  icon: Icons.auto_awesome,
                  title: 'Generate Quiz',
                  subtitle: 'AI-powered quiz from any topic',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to quiz generator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quiz Generator - Coming Soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _CreateOption(
                  icon: Icons.menu_book,
                  title: 'Generate Article',
                  subtitle: 'Create study materials with AI',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to article generator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Article Generator - Coming Soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _CreateOption(
                  icon: Icons.auto_fix_high,
                  title: 'Start SynLearn',
                  subtitle: 'Personalized learning path',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to SynLearn
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SynLearn - Coming Soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient.scale(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// Extension to scale gradient opacity
extension GradientExtension on Gradient {
  Gradient scale(double opacity) {
    if (this is LinearGradient) {
      final lg = this as LinearGradient;
      return LinearGradient(
        colors: lg.colors.map((c) => c.withValues(alpha: opacity)).toList(),
        begin: lg.begin,
        end: lg.end,
      );
    }
    return this;
  }
}
