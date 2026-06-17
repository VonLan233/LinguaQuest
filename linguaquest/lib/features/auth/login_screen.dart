import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/mascot_image.dart';
import '../../l10n/generated/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s24,
            vertical: AppTokens.s32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.s24),
                const Center(child: MascotImage(size: 96)),
                const SizedBox(height: AppTokens.s20),
                Text(
                  l10n.authWelcomeBack,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  'LinguaQuest',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  l10n.authWelcomeBackSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppTokens.s32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.authEmail,
                    hintText: l10n.authEmailHint,
                    prefixIcon: const Icon(AppIcons.mail),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => _emailValidator(value, l10n),
                ),
                const SizedBox(height: AppTokens.s16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.authPassword,
                    hintText: l10n.authPasswordHint,
                    prefixIcon: const Icon(AppIcons.lock),
                  ),
                  obscureText: true,
                  validator: (value) => _passwordValidator(value, l10n),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppTokens.s12),
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppTokens.s24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AppPrimaryButton(
                      label: l10n.commonLogin,
                      icon: AppIcons.login,
                      onPressed: state.isLoading ? null : _submit,
                    ),
                    if (state.isLoading)
                      const Positioned(
                        right: AppTokens.s20,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTokens.textHintLight,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.s12),
                AppSecondaryButton(
                  label: l10n.goalSetupEnterApp,
                  icon: AppIcons.bolt,
                  onPressed: state.isLoading ? null : _enterDemo,
                ),
                const SizedBox(height: AppTokens.s8),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(l10n.authRegisterNew),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);
    if (!mounted) return;
    if (!succeeded) return;
    context.go('/home');
  }

  Future<void> _enterDemo() async {
    final ok = await ref.read(appControllerProvider.notifier).enterDemo();
    if (!mounted || !ok) return;
    context.go('/home');
  }
}

String? _emailValidator(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return l10n.authEmailRequired;
  if (!value.contains('@')) return l10n.authEmailInvalid;
  return null;
}

String? _passwordValidator(String? value, AppLocalizations l10n) {
  if (value == null || value.length < 6) return l10n.authPasswordRequired;
  return null;
}
