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
              const _ArchitectureCard(),
            ],
          );
        },
      ),
    );
  }
}

class _ArchitectureCard extends StatelessWidget {
  const _ArchitectureCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Architecture', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            const _ArchitectureRow(
              icon: Icons.layers_outlined,
              title: 'Presentation',
              body: 'Screens, reusable widgets, Material 3 theme, navigation.',
            ),
            const _ArchitectureRow(
              icon: Icons.account_tree_outlined,
              title: 'State',
              body: 'AuthCubit, LibraryCubit, ReaderCubit with async states.',
            ),
            const _ArchitectureRow(
              icon: Icons.storage_outlined,
              title: 'Data',
              body:
                  'Repository plus mock API client, local cache, offline queue.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchitectureRow extends StatelessWidget {
  const _ArchitectureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
