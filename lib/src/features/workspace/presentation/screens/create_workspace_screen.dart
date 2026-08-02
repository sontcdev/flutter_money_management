import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

class CreateWorkspaceScreen extends HookConsumerWidget {
  const CreateWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);

    Future<void> submit() async {
      if (isLoading.value) {
        return;
      }
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace name is required')),
        );
        return;
      }

      isLoading.value = true;
      try {
        final workspaceId =
            await ref.read(workspaceManagementServiceProvider).createWorkspace(
                  name: nameController.text,
                  description: descriptionController.text,
                );
        ref.invalidate(workspaceListProvider);
        ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;

        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/workspace-detail',
          (route) => route.settings.name == '/workspace-selection',
          arguments: workspaceId,
        );
      } catch (e, stackTrace) {
        if (!context.mounted) {
          return;
        }
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'workspace',
          action: 'create_workspace',
          screen: 'create_workspace_screen',
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Workspace')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Create a shared workspace for your household or group.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textFaint,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: 'Workspace name',
            controller: nameController,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: 'Description',
            controller: descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Create workspace',
            onPressed: submit,
            isLoading: isLoading.value,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.invitedUserJoinHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textFaint,
                ),
          ),
        ],
      ),
    );
  }
}
