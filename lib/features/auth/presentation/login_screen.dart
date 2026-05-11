import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(
    text: 'reader@insightshelf.dev',
  );
  final _passwordController = TextEditingController(text: 'demo1234');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: theme.colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'InsightShelf Mobile',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Read purchased books offline, keep notes in sync, and generate focused AI reading support.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                if (value == null || !value.contains('@')) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 4) {
                                  return 'Use at least 4 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                final loading =
                                    state.status == AuthStatus.loading;
                                return SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: loading
                                        ? null
                                        : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              context.read<AuthCubit>().login(
                                                _emailController.text,
                                                _passwordController.text,
                                              );
                                            }
                                          },
                                    icon: loading
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.login),
                                    label: const Text('Sign in'),
                                  ),
                                );
                              },
                            ),
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                if (state.status != AuthStatus.failure) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    state.errorMessage ?? 'Login failed.',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _FeatureChip(
                        icon: Icons.cloud_sync_outlined,
                        label: 'API sync',
                      ),
                      _FeatureChip(
                        icon: Icons.offline_bolt_outlined,
                        label: 'Offline reading',
                      ),
                      _FeatureChip(
                        icon: Icons.psychology_outlined,
                        label: 'AI insights',
                      ),
                      _FeatureChip(
                        icon: Icons.edit_note_outlined,
                        label: 'Notes and highlights',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}
