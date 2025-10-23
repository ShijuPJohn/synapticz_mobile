import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/profile/edit_profile_screen.dart';
import 'presentation/screens/quizzes/quiz_detail_screen.dart';
import 'presentation/screens/learn/quizbook_detail_screen.dart';
import 'presentation/screens/test/test_session_screen.dart';
import 'presentation/screens/test/test_results_screen.dart';
import 'presentation/widgets/main_scaffold.dart';
import 'presentation/widgets/auth_checker.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SynapticzApp(),
    ),
  );
}

class SynapticzApp extends ConsumerWidget {
  const SynapticzApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Synapticz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: AuthChecker(),
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        if (settings.name == '/quiz-detail') {
          final quizId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => QuizDetailScreen(quizId: quizId),
          );
        } else if (settings.name == '/quizbook-detail') {
          final quizBookId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => QuizBookDetailScreen(quizBookId: quizBookId),
          );
        } else if (settings.name == '/test-session') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TestSessionScreen(
              sessionId: args['sessionId'] as String,
            ),
          );
        } else if (settings.name == '/test-results') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => TestResultsScreen(
              sessionId: args['sessionId'] as String,
              initialResults: args['results'] as Map<String, dynamic>?,
            ),
          );
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const MainScaffold(),
        '/edit-profile': (context) => const EditProfileScreen(),
      },
    );
  }
}
