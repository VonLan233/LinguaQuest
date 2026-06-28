import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/email_validation.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/mascot_image.dart';
import '../../l10n/generated/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
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
                  l10n.authCreateProfile,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  l10n.authCreateProfileSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                Center(
                  child: AppPill(
                    label: l10n.authStep1of2,
                    variant: PillVariant.primary,
                    icon: AppIcons.personAdd,
                  ),
                ),
                const SizedBox(height: AppTokens.s32),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.authNickname,
                    hintText: l10n.authNicknameHint,
                    prefixIcon: const Icon(AppIcons.badge),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.authNameRequired
                      : null,
                ),
                const SizedBox(height: AppTokens.s16),
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
                      label: l10n.authContinueToGoal,
                      icon: AppIcons.arrowForward,
                      onPressed: state.isLoading ? null : _submit,
                    ),
                    if (state.isLoading)
                      Positioned(
                        right: AppTokens.s20,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.s8),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l10n.authHaveAccount),
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
    final step = await ref.read(appControllerProvider.notifier).register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    switch (step) {
      case AuthStep.needsVerification:
        context.go(
          '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}',
        );
      case AuthStep.authenticated:
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.authAccountCreated)),
        );
        context.go('/goal-setup');
      case AuthStep.failed:
        break;
    }
  }
}

String? _emailValidator(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return l10n.authEmailRequired;
  if (!isValidEmail(value)) return l10n.authEmailInvalid;
  return null;
}

String? _passwordValidator(String? value, AppLocalizations l10n) {
  if (value == null || value.length < 6) return l10n.authPasswordRequired;
  return null;
}
