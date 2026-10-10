part of 'settings_screen.dart';

/// Grouped-list section header (iOS style): a short, non-uppercase gray
/// footnote sitting above a group of settings rows.
class _SectionCaption extends StatelessWidget {
  const _SectionCaption({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.semanticColors.textFaint,
            ),
      ),
    );
  }
}

/// Card that hosts a tight vertical list of [_SettingsRow]s, separated by
/// hairline separators inset to align with the row's text.
class _SettingsListCard extends StatelessWidget {
  const _SettingsListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: AppSpacing.cellInset),
                color: Theme.of(context).dividerColor,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single settings row: a colored rounded-square icon tile, a title,
/// optional subtitle, and a trailing widget (defaults to a chevron when
/// [onTap] is set) — matching the iOS Settings cell.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tint,
    this.titleColor,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tint;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final tileColor = tint ?? Theme.of(context).colorScheme.primary;
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (icon != null)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          if (leading != null || icon != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: titleColor,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.semanticColors.textFaint,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              (onTap != null
                  ? Icon(
                      Icons.chevron_right,
                      size: AppSpacing.iconSizeSm,
                      color: context.semanticColors.textFaint,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.cellMinHeight),
      child: row,
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}

/// Circular avatar showing the first letter of [text].
class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.text, this.size = 44});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = text.trim().isNotEmpty ? text.trim()[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppColors.primaryStrongDark
                  : AppColors.primaryStrong,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

/// Rounded-square badge with the first 1-2 letters of a workspace name,
/// used to represent a workspace in list rows.
class _SquareBadge extends StatelessWidget {
  const _SquareBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final label = text.trim().isNotEmpty ? text.trim()[0].toUpperCase() : '?';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _InitialsAvatar(
            text: email ?? '?',
            size: 56,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email ?? l10n.notAvailable,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.accountSection,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: context.semanticColors.textFaint,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveWorkspaceCard extends StatelessWidget {
  const _LeaveWorkspaceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warningColor = context.semanticColors.warning;

    return _SettingsListCard(
      children: [
        _SettingsRow(
          icon: Icons.logout,
          tint: warningColor,
          title: l10n.leaveWorkspace,
          titleColor: warningColor,
          subtitle: l10n.leaveWorkspaceSubtitle,
          trailing: const SizedBox.shrink(),
          onTap: onTap,
        ),
      ],
    );
  }
}

class _AppearanceSettingsCard extends ConsumerWidget {
  const _AppearanceSettingsCard({
    required this.locale,
    required this.themeMode,
    required this.themeColor,
    required this.fontScaleLabel,
    required this.onThemeColorTap,
    required this.onFontScaleTap,
  });

  final Locale locale;
  final ThemeMode themeMode;
  final Color themeColor;
  final String fontScaleLabel;
  final VoidCallback onThemeColorTap;
  final VoidCallback onFontScaleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return _SettingsListCard(
      children: [
        _SettingsRow(
          icon: Icons.language,
          tint: AppColors.info,
          title: l10n.language,
          trailing: DropdownButton<String>(
            value: locale.languageCode,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                  value: 'en', child: Text(l10n.languageEnglish)),
              DropdownMenuItem(
                  value: 'ja', child: Text(l10n.languageJapanese)),
              DropdownMenuItem(
                  value: 'vi', child: Text(l10n.languageVietnamese)),
            ],
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(Locale(value));
              }
            },
          ),
        ),
        _SettingsRow(
          icon: Icons.brightness_6_outlined,
          tint: AppColors.tintSlate,
          title: l10n.theme,
          trailing: DropdownButton<ThemeMode>(
            value: themeMode,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                  value: ThemeMode.light, child: Text(l10n.light)),
              DropdownMenuItem(
                  value: ThemeMode.dark, child: Text(l10n.dark)),
              DropdownMenuItem(
                  value: ThemeMode.system, child: Text(l10n.system)),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
        ),
        _SettingsRow(
          icon: Icons.palette_outlined,
          tint: AppColors.tintPink,
          title: l10n.themeColor,
          subtitle: l10n.selectThemeColor,
          trailing: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          onTap: onThemeColorTap,
        ),
        _SettingsRow(
          icon: Icons.text_fields_outlined,
          tint: AppColors.tintOrange,
          title: l10n.fontSize,
          subtitle: fontScaleLabel,
          onTap: onFontScaleTap,
        ),
      ],
    );
  }
}

class _BudgetSettingsCard extends StatelessWidget {
  const _BudgetSettingsCard({
    required this.monthStartDay,
    required this.onMonthStartDayTap,
  });

  final int monthStartDay;
  final VoidCallback onMonthStartDayTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SettingsListCard(
      children: [
        _SettingsRow(
          icon: Icons.calendar_month_outlined,
          tint: AppColors.error,
          title: l10n.monthStartDay,
          subtitle: l10n.monthStartDayDesc(monthStartDay),
          onTap: onMonthStartDayTap,
        ),
        _SettingsRow(
          icon: Icons.pie_chart_outline,
          tint: AppColors.tintTeal,
          title: l10n.manageBudgets,
          subtitle: l10n.manageBudgetsDesc,
          onTap: () => Navigator.pushNamed(context, '/budgets'),
        ),
      ],
    );
  }
}

class _DataSettingsCard extends StatelessWidget {
  const _DataSettingsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SettingsListCard(
      children: [
        _SettingsRow(
          icon: Icons.account_balance_wallet_outlined,
          tint: AppColors.primary,
          title: l10n.manageWallets,
          subtitle: l10n.manageWalletsSubtitle,
          onTap: () => Navigator.pushNamed(context, '/wallets'),
        ),
        _SettingsRow(
          icon: Icons.category_outlined,
          tint: AppColors.tintViolet,
          title: l10n.manageCategories,
          subtitle: l10n.manageCategoriesDesc,
          onTap: () => Navigator.pushNamed(context, '/categories'),
        ),
        _SettingsRow(
          icon: Icons.receipt_long_outlined,
          tint: AppColors.info,
          title: l10n.manageTransactions,
          subtitle: l10n.manageTransactionsDesc,
          onTap: () =>
              Navigator.pushNamed(context, '/transaction-management'),
        ),
        _SettingsRow(
          icon: Icons.schedule_outlined,
          tint: AppColors.warning,
          title: l10n.recurringTransactions,
          subtitle: l10n.recurringTransactionsDesc,
          onTap: () =>
              Navigator.pushNamed(context, '/recurring-transactions'),
        ),
      ],
    );
  }
}

class _AboutSettingsCard extends StatelessWidget {
  const _AboutSettingsCard({required this.packageInfo});

  final PackageInfo packageInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SettingsListCard(
      children: [
        _SettingsRow(
          icon: Icons.info_outline,
          tint: AppColors.textFaint,
          title: packageInfo.appName,
          subtitle: l10n.versionLabel(
            packageInfo.version,
            packageInfo.buildNumber,
          ),
          trailing: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;

    return _SettingsListCard(
      children: [
        _SettingsRow(
          icon: Icons.delete_forever_outlined,
          tint: errorColor,
          title: l10n.deleteAccount,
          subtitle: l10n.deleteAccountDesc,
          titleColor: errorColor,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? AppColors.errorDark : AppColors.error;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: errorColor,
          side: BorderSide(color: errorColor),
        ),
        onPressed: onPressed,
        child: Text(l10n.logout),
      ),
    );
  }
}
