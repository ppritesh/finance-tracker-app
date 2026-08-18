import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/auth_controller.dart';
import '../utils/responsive.dart';
import 'two_factor_setup_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().refreshUser();
    });
  }

  Future<void> _enableTwoFactor() async {
    final enabled = await openTwoFactorSetup(context);
    if (enabled == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authenticator enabled')),
      );
    }
  }

  Future<void> _disableTwoFactor() async {
    final passwordController = TextEditingController();
    final codeController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable authenticator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password and a current authenticator code.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Authenticator code',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      passwordController.dispose();
      codeController.dispose();
      return;
    }

    try {
      await context.read<AuthController>().disableTwoFactor(
        password: passwordController.text,
        code: codeController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authenticator disabled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      passwordController.dispose();
      codeController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return AdaptiveBody(
      maxWidth: 520,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      (auth.userName?.isNotEmpty == true
                              ? auth.userName![0]
                              : 'U')
                          .toUpperCase(),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName ?? 'User',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.userEmail ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Security'),
                  subtitle: const Text(
                    'Encrypted notes and phone numbers on the server',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.phonelink_lock_outlined),
                  title: const Text('Authenticator app'),
                  subtitle: Text(
                    auth.twoFactorEnabled
                        ? 'Required after sign in'
                        : 'Add an extra layer of protection',
                  ),
                  value: auth.twoFactorEnabled,
                  onChanged: (enabled) {
                    if (enabled) {
                      _enableTwoFactor();
                    } else {
                      _disableTwoFactor();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              await auth.signOut();
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
