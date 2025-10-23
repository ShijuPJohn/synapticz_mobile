import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _goalController = TextEditingController();
  final _mobileController = TextEditingController();
  final _countryController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Populate form with current user data
    final user = ref.read(authProvider).user;
    _nameController.text = user?.name ?? '';
    _aboutController.text = user?.about ?? '';
    _goalController.text = user?.goal ?? '';
    _mobileController.text = user?.mobileNumber ?? '';
    _countryController.text = user?.country ?? '';
    _countryCodeController.text = user?.countryCode ?? '';
    _linkedinController.text = user?.linkedin ?? '';
    _facebookController.text = user?.facebook ?? '';
    _instagramController.text = user?.instagram ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _goalController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    _countryCodeController.dispose();
    _linkedinController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).updateProfile(
          name: _nameController.text.trim(),
          about: _aboutController.text.trim().isNotEmpty ? _aboutController.text.trim() : null,
          goal: _goalController.text.trim().isNotEmpty ? _goalController.text.trim() : null,
          mobileNumber: _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
          country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
          countryCode: _countryCodeController.text.trim().isNotEmpty ? _countryCodeController.text.trim() : null,
          linkedin: _linkedinController.text.trim().isNotEmpty ? _linkedinController.text.trim() : null,
          facebook: _facebookController.text.trim().isNotEmpty ? _facebookController.text.trim() : null,
          instagram: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(authProvider).error ?? 'Failed to update profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final oldPassword = oldPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }

                Navigator.pop(context);

                // Call change password API
                final success = await ref.read(profileProvider.notifier).changePassword(
                      oldPassword: oldPassword,
                      newPassword: newPassword,
                    );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  final error = ref.read(profileProvider).error ?? 'Failed to change password';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            backgroundImage: user?.profilePic?.isNotEmpty == true
                                ? NetworkImage(user!.profilePic!)
                                : null,
                            child: user?.profilePic?.isEmpty != false
                                ? Text(
                                    user?.name?.isNotEmpty == true
                                        ? user!.name![0].toUpperCase()
                                        : 'U',
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                onPressed: () {
                                  // TODO: Implement image picker
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Image upload will be implemented'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email (read-only)
                    TextFormField(
                      initialValue: user?.email ?? '',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // About
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'About',
                        hintText: 'Tell us about yourself',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Goal
                    TextFormField(
                      controller: _goalController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Goal',
                        hintText: 'What are you learning for?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Country
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'e.g., India, USA, UK',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.public),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number with Country Code
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _countryCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Code',
                              hintText: '+91',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.add),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: _mobileController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number',
                              hintText: '1234567890',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social Media Section
                    Text(
                      'Social Media',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // LinkedIn
                    TextFormField(
                      controller: _linkedinController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn',
                        hintText: 'linkedin.com/in/username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // Facebook
                    TextFormField(
                      controller: _facebookController,
                      decoration: const InputDecoration(
                        labelText: 'Facebook',
                        hintText: 'facebook.com/username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.facebook),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // Instagram
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        hintText: 'instagram.com/username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.camera_alt_outlined),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 24),

                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
