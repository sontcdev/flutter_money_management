// path: lib/src/ui/screens/workspace_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/workspace_providers.dart';
import '../../providers/auth_providers.dart';

/// Screen to select or create a workspace after authentication
class WorkspaceSelectionScreen extends ConsumerWidget {
  const WorkspaceSelectionScreen({super.key});

  static const _backendMisconfigurationMessage =
      'No workspace was created for this account.\n\n'
      'This usually means the Supabase auth trigger `on_auth_user_created` '
      'is missing or misconfigured.\n\n'
      'Please contact the administrator and ask them to verify:\n'
      '- trigger `on_auth_user_created`\n'
      '- function `public.handle_new_user()`\n'
      '- rows were created in `profiles`, `workspaces`, and `workspace_members`';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(workspaceListProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final supabaseAuth = ref.read(supabaseAuthServiceProvider);
              await supabaseAuth.signOut();
              // Clear active workspace
              clearActiveWorkspace(ref);
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/sign-in');
              }
            },
          ),
        ],
      ),
      body: workspacesAsync.when(
        data: (workspaces) {
          if (workspaces.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 72,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Workspace setup is incomplete',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        _backendMisconfigurationMessage,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              ref.invalidate(workspaceListProvider);
                            },
                            child: const Text('Retry'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              final supabaseAuth = ref.read(supabaseAuthServiceProvider);
                              await supabaseAuth.signOut();
                              clearActiveWorkspace(ref);
                              if (context.mounted) {
                                Navigator.of(context).pushReplacementNamed('/sign-in');
                              }
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workspaces.length,
            itemBuilder: (context, index) {
              final workspace = workspaces[index];
              final isOwner = workspace.ownerId == currentUser?.id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(workspace.name[0].toUpperCase()),
                  ),
                  title: Text(workspace.name),
                  subtitle: Text(
                    isOwner ? 'Owner' : 'Role: ${workspace.role}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOwner ? Colors.green : Colors.blue,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Set active workspace and navigate to home
                    ref.read(activeWorkspaceIdProvider.notifier).state =
                        workspace.id;
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading workspaces: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(workspaceListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }
}
