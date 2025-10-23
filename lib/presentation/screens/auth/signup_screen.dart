import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _referralCodeController = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;
  bool _pendingVerification = false;
  bool _canResend = false;
  int _timer = 45;
  String? _referralValidationMessage;
  bool? _referralValid;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timer = 45;
      _canResend = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timer > 0) {
        setState(() => _timer--);
        if (_timer > 0) {
          _startTimer();
        } else {
          setState(() => _canResend = true);
        }
      }
    });
  }

  Future<void> _validateReferralCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        _referralValid = null;
        _referralValidationMessage = null;
      });
      return;
    }

    try {
      final result = await AuthService.validateReferralCode(code.trim());
      setState(() {
        _referralValid = result['valid'] as bool? ?? false;
        if (_referralValid!) {
          final referrerName = result['referrer_name'] as String?;
          _referralValidationMessage =
              'Valid! Referred by $referrerName. You\'ll get 10% off your subscription.';
        } else {
          _referralValidationMessage = 'Invalid referral code';
        }
      });
    } catch (e) {
      setState(() {
        _referralValid = false;
        _referralValidationMessage = 'Invalid referral code';
      });
    }
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService.createUser(
        email: _emailController.text,
        referralCode: _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim(),
      );

      setState(() {
        _loading = false;
        _pendingVerification = true;
      });

      _startTimer();

      if (mounted) {
        _showVerificationModal();
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

  void _showVerificationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 6-digit code sent to',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _emailController.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _verificationCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 8, fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            if (!_canResend)
              Text(
                'You can resend the code in ${_timer}s',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              OutlinedButton(
                onPressed: _resendCode,
                child: const Text('Resend Code'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _pendingVerification = false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0891B2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_verificationCodeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit code')),
      );
      return;
    }

    try {
      final success = await ref.read(authProvider.notifier).verifyEmail(
        email: _emailController.text,
        code: _verificationCodeController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pop(); // Close modal
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else if (mounted) {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  error?.replaceAll('Exception: ', '') ?? 'Verification failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    // TODO: Call resend API
    await Future.delayed(const Duration(seconds: 1));

    _startTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code sent successfully')),
      );
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
                      'Sign Up',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFFD97706),
                            decorationThickness: 2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Google Sign In Button (disabled for now)
                    OutlinedButton.icon(
                      onPressed: null, // Disabled until OAuth is implemented
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Sign up with Google (Coming Soon)'),
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

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      enabled: !_pendingVerification,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 3) {
                          return 'Username should be at least 3 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      enabled: !_pendingVerification,
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

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_pendingVerification,
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
                        if (value.length < 6) {
                          return 'Minimum 6 characters';
                        }
                        final passwordRegex = RegExp(
                          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
                        );
                        if (!passwordRegex.hasMatch(value)) {
                          return 'Must include uppercase, lowercase, number, symbol';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Referral Code Field
                    TextFormField(
                      controller: _referralCodeController,
                      enabled: !_pendingVerification,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Referral Code (Optional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.card_giftcard_outlined),
                        helperText: _referralValidationMessage,
                        helperMaxLines: 2,
                        helperStyle: TextStyle(
                          color: _referralValid == true
                              ? Colors.green
                              : _referralValid == false
                                  ? Colors.red
                                  : null,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length >= 6) {
                          _validateReferralCode(value.toUpperCase());
                        } else {
                          setState(() {
                            _referralValid = null;
                            _referralValidationMessage = null;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _loading || _pendingVerification ? null : _submitSignup,
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
                          : const Text('Submit'),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                    ),

                    const SizedBox(height: 16),

                    // Login link
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: const Text(
                        'Sign in with credentials',
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
