import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/auth_controller.dart';
import '../utils/adaptive_navigation.dart';
import '../utils/responsive.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _codeController = TextEditingController();
  String? _secret;
  String? _otpauthUrl;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadSetup() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await context.read<AuthController>().beginTwoFactorSetup();
      setState(() {
        _secret = result['secret'] as String?;
        _otpauthUrl = result['otpauthUrl'] as String?;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your authenticator app.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await context.read<AuthController>().confirmTwoFactorSetup(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Set up authenticator')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdaptiveBody(
              maxWidth: 520,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Text(
                    'Scan this QR code with Google Authenticator, Authy, or another TOTP app.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_otpauthUrl != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: QrImageView(
                          data: _otpauthUrl!,
                          size: context.isDesktop ? 220 : 180,
                        ),
                      ),
                    ),
                  if (_secret != null) ...[
                    const SizedBox(height: 16),
                    SelectableText(
                      'Manual key: $_secret',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _confirm,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enable authenticator'),
                  ),
                ],
              ),
            ),
    );
  }
}

Future<bool?> openTwoFactorSetup(BuildContext context) {
  return pushAdaptivePage<bool>(
    context,
    const TwoFactorSetupScreen(),
    maxWidth: 560,
    maxHeight: 760,
  );
}
