import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category_icon_registry.dart';
import 'package:flutter_money_management/src/features/categories/providers/custom_icons_provider.dart';

class IconManagementScreen extends HookConsumerWidget {
  const IconManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final customIcons = ref.watch(customIconsProvider);
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final searchResults = SearchableIcons.search(searchQuery.value);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.iconManagement),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: l10n.searchIconHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),

          // My Icons section
          if (customIcons.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.star,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.myIcons,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: customIcons.length,
                itemBuilder: (context, index) {
                  final iconKey = customIcons[index];
                  final iconData =
                      SearchableIcons.allIcons[iconKey] ?? Icons.category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _IconTile(
                      iconKey: iconKey,
                      iconData: iconData,
                      isAdded: true,
                      onTap: () async {
                        await ref
                            .read(customIconsProvider.notifier)
                            .removeIcon(iconKey);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.iconRemoved)),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
          ],

          // Available icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.apps, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.availableIcons,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${searchResults.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search results grid
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(l10n.noIconsFound),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final entry = searchResults[index];
                      final isAdded = customIcons.contains(entry.key);
                      return _IconTile(
                        iconKey: entry.key,
                        iconData: entry.value,
                        isAdded: isAdded,
                        onTap: () async {
                          if (isAdded) {
                            await ref
                                .read(customIconsProvider.notifier)
                                .removeIcon(entry.key);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.iconRemoved)),
                              );
                            }
                          } else {
                            final added = await ref
                                .read(customIconsProvider.notifier)
                                .addIcon(entry.key);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(added
                                      ? l10n.iconAdded
                                      : l10n.iconAlreadyAdded),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final String iconKey;
  final IconData iconData;
  final bool isAdded;
  final VoidCallback onTap;

  const _IconTile({
    required this.iconKey,
    required this.iconData,
    required this.isAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: iconKey,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isAdded
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAdded
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
              width: isAdded ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  iconData,
                  size: 28,
                  color: isAdded
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                ),
              ),
              if (isAdded)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
