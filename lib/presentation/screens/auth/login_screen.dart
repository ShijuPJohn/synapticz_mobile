import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;
  bool _emailChecked = false;
  bool _userExists = false;
  bool _passwordExists = false;
  bool _otpSent = false;
  String? _loginMethod; // 'password' or 'otp'
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        if (_resendTimer > 0) {
          _startResendTimer();
        } else {
          setState(() => _canResend = true);
        }
      }
    });
  }

  Future<void> _checkEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await AuthService.checkEmail(_emailController.text);
      setState(() {
        _emailChecked = true;
        _userExists = result['user_exists'] as bool? ?? false;
        _passwordExists = result['has_password'] as bool? ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _loading = true);

    try {
      await AuthService.sendVerificationCode(_emailController.text);
      setState(() {
        _otpSent = true;
        _loading = false;
      });

      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('6-digit code sent to your email')),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_emailChecked) {
      await _checkEmail();
      return;
    }

    setState(() => _loading = true);

    try {
      bool success = false;

      if (_loginMethod == 'password') {
        // Login with password
        success = await ref.read(authProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else if (_loginMethod == 'otp' && _otpController.text.isNotEmpty) {
        // Verify OTP
        success = await ref.read(authProvider.notifier).verifyEmail(
          email: _emailController.text,
          code: _otpController.text,
        );
      }

      setState(() => _loading = false);

      if (success && mounted) {
        final user = ref.read(authProvider).user;
        // Navigate to onboarding if user has no name, otherwise go to home
        if (user?.name == null || user!.name!.isEmpty) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (mounted) {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error?.replaceAll('Exception: ', '') ?? 'Login failed')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFD97706),
                            decorationThickness: 2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Google Sign In Button (disabled for now)
                    OutlinedButton.icon(
                      onPressed: null, // Disabled until OAuth is implemented
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Login with Google (Coming Soon)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: const Color(0xFFD97706),
                    ),

                    const SizedBox(height: 24),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      enabled: !_emailChecked,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field (only shown if user chooses password login)
                    if (_loginMethod == 'password') ...[
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // OTP Field (only shown for OTP login)
                    if (_loginMethod == 'otp' && _otpSent) ...[
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (value.length != 6) {
                            return 'OTP must be 6 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Resend timer
                      if (!_canResend)
                        Text(
                          'Wait $_resendTimer seconds to resend',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),

                      if (_canResend)
                        TextButton(
                          onPressed: _sendOtp,
                          child: const Text('Resend Code'),
                        ),

                      const SizedBox(height: 8),
                    ],

                    // Login method selection
                    if (_passwordExists && _emailChecked && _userExists && _loginMethod == null) ...[
                      const Text(
                        'How would you like to login?',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _loginMethod = 'password');
                              },
                              child: const Text('Use Password'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                setState(() => _loginMethod = 'otp');
                                await _sendOtp();
                              },
                              child: const Text('Use Code'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New user verification
                    if (_emailChecked && (!_userExists || !_passwordExists) && _loginMethod == null) ...[
                      const Text(
                        'Verify your email with a 6-digit code?',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () async {
                          setState(() => _loginMethod = 'otp');
                          await _sendOtp();
                        },
                        child: const Text('Send 6-digit code'),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    ElevatedButton(
                      onPressed: _loading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0891B2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: const Color(0xFF67E8F9),
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
                          : Text(
                              _emailChecked
                                  ? (_loginMethod == 'otp' ? 'Verify Code' : 'Login')
                                  : 'Continue',
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('or'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/signup');
                      },
                      child: const Text(
                        'Create an account',
                        style: TextStyle(fontSize: 16),
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
