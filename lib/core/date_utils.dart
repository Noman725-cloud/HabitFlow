// All habit dates are LOCAL calendar dates stored as 'yyyy-MM-dd' strings.
// Never store UTC timestamps for "which day did this count toward".

String toDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime fromDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) throw FormatException('Invalid date key', key);
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Strips the time component (local midnight).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// DST-safe day arithmetic (adding Duration(days: n) can land on 23h/25h days).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// First day of the week containing [d]. [weekStartDay]: 1 = Mon .. 7 = Sun.
DateTime startOfWeek(DateTime d, {int weekStartDay = DateTime.monday}) {
  final offset = (d.weekday - weekStartDay + 7) % 7;
  return addDays(dateOnly(d), -offset);
}
