import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';

String? validateTransactionAmount(String? value, AppLocalizations l10n) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return l10n.amountRequiredError;
  final amount = CurrencyFormatter.parseVND(text);
  if (amount == null || amount <= 0) return l10n.invalidAmount;
  return null;
}

String lastUsedCategoryPreferenceKey(String workspaceId, String type) =>
    'last_used_category_${workspaceId}_$type';

class TransactionCategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;

  const TransactionCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: categories.map((category) {
        final isSelected = selectedCategoryId == category.id;
        final categoryColor = getCategoryColor(category.colorValue);
        return Semantics(
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: () => onSelected(category.id),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                border: Border.all(
                  color: categoryColor,
                  width: isSelected ? 3 : 1.5,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check,
                      size: AppSpacing.iconSizeXs,
                      color: categoryColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  CategoryIconWidget(
                    iconName: category.iconName,
                    size: 18,
                    color: categoryColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: categoryColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ReceiptNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;

  const ReceiptNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderHeight = height ?? 120;
    return Image.network(
      imageUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final expected = progress.expectedTotalBytes;
        return SizedBox(
          height: placeholderHeight,
          width: width,
          child: Center(
            child: CircularProgressIndicator(
              value: expected == null
                  ? null
                  : progress.cumulativeBytesLoaded / expected,
            ),
          ),
        );
      },
      errorBuilder: (context, _, __) => SizedBox(
        height: placeholderHeight,
        width: width,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            semanticLabel: AppLocalizations.of(context)!.imageLoadFailed,
          ),
        ),
      ),
    );
  }
}

Future<ImageSource?> showReceiptSourcePicker(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.chooseFromGallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmDiscardChanges(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.discardChangesTitle),
      content: Text(l10n.discardChangesMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.keepEditing),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.discard),
        ),
      ],
    ),
  );
  return discard == true;
}

class TransactionDiscardGuard extends StatelessWidget {
  final bool isDirty;
  final Widget child;

  const TransactionDiscardGuard({
    super.key,
    required this.isDirty,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (result == true || await confirmDiscardChanges(context)) {
          navigator.pop(result);
        }
      },
      child: child,
    );
  }
}

class TransactionSaveBar extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const TransactionSaveBar({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.md,
        ),
        child: AppButton.prominent(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          fullWidth: true,
        ),
      ),
    );
  }
}
