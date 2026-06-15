import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand_hero_card.dart';
import '../../core/widgets/quest_panel.dart';
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
      appBar: AppBar(title: Text(l10n.authLoginTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s8,
            AppTokens.s20,
            AppTokens.s20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrandHeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.authWelcomeBack,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s8),
                      Text(
                        l10n.authWelcomeBackSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s20),
                QuestPanel(
                  padding: const EdgeInsets.all(AppTokens.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.authEmail,
                          hintText: l10n.authEmailHint,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => _emailValidator(value, l10n),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l10n.authPassword,
                          hintText: l10n.authPasswordHint,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) => _passwordValidator(value, l10n),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: AppTokens.s12),
                        Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTokens.s20),
                      FilledButton.icon(
                        onPressed: state.isLoading ? null : _submit,
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: Text(l10n.commonLogin),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s4),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(l10n.authRegisterNew),
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
