// path: lib/src/ui/screens/workspace_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/workspace_providers.dart';
import '../../providers/auth_providers.dart';

/// Screen to select or create a workspace after authentication
class WorkspaceSelectionScreen extends ConsumerWidget {
  const WorkspaceSelectionScreen({super.key});

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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No workspaces found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first workspace to get started'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showCreateWorkspaceDialog(context, ref);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Workspace'),
                  ),
                ],
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
      floatingActionButton: workspacesAsync.maybeWhen(
        data: (workspaces) => workspaces.isNotEmpty
            ? FloatingActionButton(
                onPressed: () {
                  _showCreateWorkspaceDialog(context, ref);
                },
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _showCreateWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Workspace Name',
                hintText: 'My Workspace',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a workspace name')),
                );
                return;
              }

              try {
                final supabase = ref.read(supabaseClientProvider);
                final session = ref.read(currentSessionProvider);

                final response = await supabase.from('workspaces').insert({
                  'name': name,
                  'type': 'personal',
                  'owner_user_id': session!.user.id,
                }).select('id').single();

                final workspaceId = response['id'] as String;

                // Refresh workspace list
                ref.invalidate(workspaceListProvider);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Set active workspace
                  ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;
                  
                  // Navigate to home immediately
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating workspace: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
