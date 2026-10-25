const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool _sameSet(Set<int> a, Set<int> b) =>
    a.length == b.length && a.containsAll(b);

/// Human-readable schedule, e.g. "Every day", "Weekdays", "Mon, Wed, Fri".
String scheduleLabel(Set<int> days) {
  if (days.length == 7) return 'Every day';
  if (_sameSet(days, {1, 2, 3, 4, 5})) return 'Weekdays';
  if (_sameSet(days, {6, 7})) return 'Weekends';
  final sorted = days.toList()..sort();
  return sorted.map((d) => _short[d - 1]).join(', ');
}
