import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import 'auth_checker.dart';

String _getInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
}

void _showLogoutDialog(BuildContext context, WidgetRef ref) {
  // Capture the notifiers before showing the dialog
  final authNotifier = ref.read(authProvider.notifier);
  final initialRouteNotifier = ref.read(initialRouteProvider.notifier);

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Close dialog first
            Navigator.pop(dialogContext);

            // Logout using auth provider (clears storage and state)
            developer.log('Attempting to logout...', name: 'NavigationDrawer');
            await authNotifier.logout();
            developer.log('Logout successful.', name: 'NavigationDrawer');

            // Set the initial route to LoginScreen immediately
            // This prevents AuthChecker from showing loading state during logout
            developer.log('Setting initialRouteProvider to LoginScreen', name: 'NavigationDrawer');
            initialRouteNotifier.state = const LoginScreen();

            if (context.mounted) {
              developer.log('Context is mounted, navigating...', name: 'NavigationDrawer');
              // Navigate back to root (AuthChecker) and remove all routes
              // AuthChecker will now show LoginScreen since we set initialRouteProvider
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthChecker()),
                (route) => false,
              );
              developer.log('Navigation complete', name: 'NavigationDrawer');
            } else {
              developer.log('Context is NOT mounted!', name: 'NavigationDrawer');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

class AppNavigationDrawer extends ConsumerWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: ref.watch(authProvider).user?.profilePic != null
                      ? NetworkImage(ref.watch(authProvider).user!.profilePic!)
                      : null,
                  child: ref.watch(authProvider).user?.profilePic == null
                      ? Text(
                          _getInitials(ref.watch(authProvider).user?.name ?? 'U'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  ref.watch(authProvider).user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  ref.watch(authProvider).user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _DrawerTile(
            icon: Icons.emoji_events_outlined,
            title: 'My Achievements',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Achievements - Coming Soon')),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.bar_chart_outlined,
            title: 'Reports & Analytics',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reports - Coming Soon')),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Referrals',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Referrals - Coming Soon')),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.create_outlined,
            title: 'Creator Dashboard',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Creator Dashboard - Coming Soon')),
              );
            },
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings - Coming Soon')),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.info_outline,
            title: 'About & Help',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('About - Coming Soon')),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.mail_outline,
            title: 'Contact',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact - Coming Soon')),
              );
            },
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              _showLogoutDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
