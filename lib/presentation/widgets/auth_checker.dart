import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../../core/services/storage_service.dart';
import '../../core/services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import 'main_scaffold.dart';

// Provider to store the initial route determination
final initialRouteProvider = StateProvider<Widget?>((ref) => null);

class AuthChecker extends ConsumerStatefulWidget {
  const AuthChecker({super.key});

  @override
  ConsumerState<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends ConsumerState<AuthChecker> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    developer.log('AuthChecker initState called.', name: 'AuthChecker');
    // Only check auth if we haven't determined the route yet
    final existingRoute = ref.read(initialRouteProvider);
    if (existingRoute == null) {
      _checkAuth();
    } else {
      // Route already determined, use it immediately
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAuth() async {
    developer.log('_checkAuth called.', name: 'AuthChecker');
    // Small delay to ensure everything is initialized
    await Future.delayed(const Duration(milliseconds: 200));

    final isLoggedIn = StorageService.isLoggedIn();
    developer.log('AuthChecker: isLoggedIn = $isLoggedIn', name: 'AuthChecker');

    Widget screenToShow;

    if (!isLoggedIn) {
      screenToShow = const LoginScreen();
      developer.log('AuthChecker: User not logged in, showing LoginScreen.', name: 'AuthChecker');
    } else {
      // User has a token, try to fetch user data
      try {
        final user = await AuthService.getCurrentUser();
        developer.log('AuthChecker: User logged in, fetched user data.', name: 'AuthChecker');

        // Update auth provider with user data
        if (mounted) {
          ref.read(authProvider.notifier).setUser(user);
        }

        // Check if profile is complete
        if (user.name == null || user.name!.isEmpty) {
          screenToShow = const OnboardingScreen();
          developer.log('AuthChecker: Profile incomplete, showing OnboardingScreen.', name: 'AuthChecker');
        } else {
          screenToShow = const MainScaffold();
          developer.log('AuthChecker: Profile complete, showing MainScaffold.', name: 'AuthChecker');
        }
      } catch (e) {
        // Token is invalid, clear and go to login
        developer.log('AuthChecker: Error fetching user data: $e. Clearing storage and showing LoginScreen.', name: 'AuthChecker');
        await StorageService.clearAll();
        screenToShow = const LoginScreen();
      }
    }

    if (mounted) {
      ref.read(initialRouteProvider.notifier).state = screenToShow;
      developer.log('AuthChecker: initialRouteProvider set to $screenToShow', name: 'AuthChecker');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AuthChecker build method called.'); // Added print statement
    final authState = ref.watch(authProvider);
    developer.log('AuthChecker build: authState.user != null = ${authState.user != null}', name: 'AuthChecker');

    if (authState.user == null) {
      developer.log('AuthChecker build: User not authenticated, returning LoginScreen.', name: 'AuthChecker');
      return const LoginScreen();
    }

    final initialScreen = ref.watch(initialRouteProvider);
    developer.log('AuthChecker build: initialScreen = $initialScreen', name: 'AuthChecker');

    if (_isLoading || initialScreen == null) {
      // Show splash screen while checking
      developer.log('AuthChecker build: Showing splash screen (isLoading: $_isLoading, initialScreen: $initialScreen).', name: 'AuthChecker');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or app icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0891B2), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Synapticz',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0891B2),
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    developer.log('AuthChecker build: Returning initialScreen.', name: 'AuthChecker');
    return initialScreen;
  }
}
