import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/auth_cubit.dart';
import 'library_cubit.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Account')),
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, libraryState) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  value: libraryState.isOnline,
                  onChanged: (value) =>
                      context.read<LibraryCubit>().setOnline(value),
                  secondary: Icon(
                    libraryState.isOnline ? Icons.wifi : Icons.wifi_off,
                  ),
                  title: Text(
                    libraryState.isOnline ? 'Online mode' : 'Offline mode',
                  ),
                  subtitle: const Text(
                    'Downloaded books and local edits still work offline.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending changes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${libraryState.pendingSyncCount} local actions waiting to sync',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: libraryState.isOnline
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final count = await context
                                      .read<LibraryCubit>()
                                      .syncPendingActions();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Synced $count changes.'),
                                    ),
                                  );
                                } catch (error) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('$error')),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.cloud_sync_outlined),
                        label: const Text('Sync now'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(authState.user?.name ?? 'Reader'),
                      subtitle: Text(authState.user?.email ?? 'No email'),
                      trailing: IconButton(
                        tooltip: 'Sign out',
                        onPressed: () => context.read<AuthCubit>().logout(),
                        icon: const Icon(Icons.logout),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const _OllamaSettingsCard(),
            ],
          );
        },
      ),
    );
  }
}

class _OllamaSettingsCard extends StatefulWidget {
  const _OllamaSettingsCard();

  @override
  State<_OllamaSettingsCard> createState() => _OllamaSettingsCardState();
}

class _OllamaSettingsCardState extends State<_OllamaSettingsCard> {
  late final TextEditingController _endpointController;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final state = context.read<LibraryCubit>().state;
    _endpointController = TextEditingController(text: state.ollamaEndpoint);
    _modelController = TextEditingController(text: state.ollamaModel);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Local AI via Ollama', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _endpointController,
                  decoration: const InputDecoration(
                    labelText: 'Ollama generate endpoint',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    prefixIcon: Icon(Icons.memory),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<LibraryCubit>().updateOllamaSettings(
                            endpoint: _endpointController.text,
                            model: _modelController.text,
                          ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.isTestingOllama
                          ? null
                          : () => context.read<LibraryCubit>().testOllama(),
                      icon: state.isTestingOllama
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bolt_outlined),
                      label: const Text('Test'),
                    ),
                  ],
                ),
                if (state.ollamaMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(state.ollamaMessage!),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
