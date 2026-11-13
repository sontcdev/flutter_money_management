import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
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
    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> submit() async {
      if (isLoading.value) {
        return;
      }
      if (!(formKey.currentState?.validate() ?? false)) {
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
      appBar: AppBar(title: Text(l10n.createWorkspaceTitle)),
      body: Form(
        key: formKey,
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            l10n.createWorkspaceDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.semanticColors.textFaint,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: l10n.workspaceNameLabel,
            controller: nameController,
            textInputAction: TextInputAction.next,
            validator: (value) => (value ?? '').trim().isEmpty
                ? l10n.workspaceNameRequired
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: l10n.note,
            controller: descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: l10n.createWorkspaceAction,
            onPressed: submit,
            isLoading: isLoading.value,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.invitedUserJoinHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.semanticColors.textFaint,
                ),
          ),
        ],
        ),
      ),
    );
  }
}
