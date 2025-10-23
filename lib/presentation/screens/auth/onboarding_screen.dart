import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _subjectController = TextEditingController();
  final _examController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _subjectController.dispose();
    _examController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    // Skip validation if all fields are empty (user wants to skip)
    final hasAnyData = _nameController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _countryController.text.isNotEmpty ||
        _subjectController.text.isNotEmpty ||
        _examController.text.isNotEmpty;

    if (!hasAnyData) {
      _skipOnboarding();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        goal: _examController.text.isEmpty ? null : _examController.text,
        about: _subjectController.text.isEmpty ? null : _subjectController.text,
        mobileNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        country: _countryController.text.isEmpty ? null : _countryController.text,
      );

      setState(() => _loading = false);

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  error?.replaceAll('Exception: ', '') ?? 'Failed to update profile')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _skipOnboarding() {
    // Navigate to home screen without filling details
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: Row(
              children: [
                const Text('Skip'),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome to Synapticz!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0891B2),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s personalize your learning experience',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Profile icon
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(
                                color: const Color(0xFF0891B2),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0891B2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your full name',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 3) {
                          return 'Name should be at least 3 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Country Field
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public_outlined),
                        hintText: 'e.g., United States, India',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Phone Number Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+1234567890',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final phoneRegex = RegExp(r'^[0-9+\-\s()]{7,20}$');
                          if (!phoneRegex.hasMatch(value)) {
                            return 'Invalid phone number';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Subject Field
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Area of Interest',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book_outlined),
                        hintText: 'e.g., Mathematics, Computer Science',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Exam Field
                    TextFormField(
                      controller: _examController,
                      decoration: const InputDecoration(
                        labelText: 'Exam You\'re Preparing For',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school_outlined),
                        hintText: 'e.g., SAT, NEET, JEE, UPSC',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Helper text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'All fields are optional. You can skip and add this information later.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _loading ? null : _submitOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0891B2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: const Color(0xFF67E8F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Complete Setup',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This information helps us personalize your quizzes and learning materials',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
