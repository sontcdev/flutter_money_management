import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String localeNameOf(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return locale.countryCode?.isNotEmpty == true
      ? '${locale.languageCode}_${locale.countryCode}'
      : locale.languageCode;
}

String formatLocalizedDate(BuildContext context, DateTime date) {
  return DateFormat.yMd(localeNameOf(context)).format(date);
}

String formatLocalizedMonthDay(BuildContext context, DateTime date) {
  return DateFormat.Md(localeNameOf(context)).format(date);
}

String formatLocalizedTime(BuildContext context, DateTime date) {
  return DateFormat.Hm(localeNameOf(context)).format(date);
}

String formatLocalizedDateTime(BuildContext context, DateTime date) {
  return DateFormat.yMd(localeNameOf(context)).add_Hm().format(date);
}

String formatLocalizedFullDate(BuildContext context, DateTime date) {
  return DateFormat.yMMMMEEEEd(localeNameOf(context)).format(date);
}

String localizedWeekdayLabel(BuildContext context, DateTime date) {
  return DateFormat.E(localeNameOf(context)).format(date);
}

String formatLocalizedDateWithWeekday(BuildContext context, DateTime date) {
  return '${formatLocalizedDate(context, date)} (${localizedWeekdayLabel(context, date)})';
}

List<String> localizedWeekdayHeaders(BuildContext context) {
  final monday = DateTime(2024, 1, 1);
  return List<String>.generate(
    7,
    (index) =>
        localizedWeekdayLabel(context, monday.add(Duration(days: index))),
  );
}
