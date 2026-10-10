DateTime keepTimeOfDay(DateTime date, DateTime timeSource) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    timeSource.hour,
    timeSource.minute,
    timeSource.second,
  );
}
