import 'package:flutter/material.dart';

import 'package:flutter_money_management/src/theme/app_colors.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.income,
    required this.incomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.transfer,
    required this.transferContainer,
    required this.warning,
    required this.warningContainer,
    required this.textFaint,
    required this.calendarSelected,
    required this.calendarToday,
  });

  final Color income;
  final Color incomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color transfer;
  final Color transferContainer;
  final Color warning;
  final Color warningContainer;
  final Color textFaint;
  final Color calendarSelected;
  final Color calendarToday;

  static const AppSemanticColors light = AppSemanticColors(
    income: AppColors.income,
    incomeContainer: AppColors.incomeContainer,
    expense: AppColors.expense,
    expenseContainer: AppColors.expenseContainer,
    transfer: AppColors.info,
    transferContainer: AppColors.infoContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    textFaint: AppColors.textFaint,
    calendarSelected: AppColors.primarySoft,
    calendarToday: AppColors.surface2,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    income: AppColors.incomeDark,
    incomeContainer: AppColors.incomeContainerDark,
    expense: AppColors.expenseDark,
    expenseContainer: AppColors.expenseContainerDark,
    transfer: AppColors.infoDark,
    transferContainer: AppColors.infoContainerDark,
    warning: AppColors.warningDark,
    warningContainer: AppColors.warningContainerDark,
    textFaint: AppColors.textLightFaint,
    calendarSelected: AppColors.primarySoftDark,
    calendarToday: AppColors.surface2Dark,
  );

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? incomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? transfer,
    Color? transferContainer,
    Color? warning,
    Color? warningContainer,
    Color? textFaint,
    Color? calendarSelected,
    Color? calendarToday,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      transfer: transfer ?? this.transfer,
      transferContainer: transferContainer ?? this.transferContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      textFaint: textFaint ?? this.textFaint,
      calendarSelected: calendarSelected ?? this.calendarSelected,
      calendarToday: calendarToday ?? this.calendarToday,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer:
          Color.lerp(expenseContainer, other.expenseContainer, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      transferContainer:
          Color.lerp(transferContainer, other.transferContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      calendarSelected:
          Color.lerp(calendarSelected, other.calendarSelected, t)!,
      calendarToday: Color.lerp(calendarToday, other.calendarToday, t)!,
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppSemanticColors.dark
          : AppSemanticColors.light);
}
