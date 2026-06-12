import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
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
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authRegisterTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: l10n.authCreateProfile,
                  subtitle: l10n.authCreateProfileSubtitle,
                ),
                const SizedBox(height: 12),
                PillLabel(
                  label: l10n.authStep1of2,
                  icon: Icons.person_add_alt_1,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.authNickname,
                    hintText: l10n.authNicknameHint,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? l10n.authNameRequired
                          : null,
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: state.isLoading ? null : _submit,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(l10n.authContinueToGoal),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.authHaveAccount),
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
        .register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    if (!succeeded) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.authAccountCreated)));
    context.go('/goal-setup');
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
