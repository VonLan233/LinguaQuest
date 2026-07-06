import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    final ok = await ref
        .read(appControllerProvider.notifier)
        .verifyEmail(email: widget.email, code: code);
    if (!mounted) return;
    if (ok) {
      context.go(
        ref.read(appControllerProvider).studyPlan == null
            ? '/goal-setup'
            : '/home',
      );
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    await ref.read(appControllerProvider.notifier).resendCode(widget.email);
    if (!mounted) return;
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = ref.watch(
      appControllerProvider.select((s) => s.errorMessage),
    );
    final loading = ref.watch(
      appControllerProvider.select((s) => s.isLoading),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter the 6-digit code',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppTokens.s8),
                  Text('We sent a code to ${widget.email}.',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppTokens.s16),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '------',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppTokens.s8),
                    Text(error,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            AppPrimaryButton(
              onPressed: loading ? null : _submit,
              label: 'Verify',
            ),
            const SizedBox(height: AppTokens.s8),
            TextButton(
              onPressed: _cooldown > 0 ? null : _resend,
              child: Text(
                _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
