import '../../core/date_utils.dart';
import '../models/entry.dart';

/// Fast lookup of live (non-deleted) entries by habit + date.
class EntryIndex {
  EntryIndex(Iterable<Entry> entries) {
    for (final e in entries) {
      if (e.isDeleted) continue;
      final key = _key(e.habitId, e.date);
      final existing = _byKey[key];
      // UNIQUE(habitId, date) should prevent duplicates; if sync ever
      // produces one, the most recently updated wins.
      if (existing == null || e.updatedAt.isAfter(existing.updatedAt)) {
        _byKey[key] = e;
      }
    }
    for (final e in _byKey.values) {
      final d = fromDateKey(e.date);
      final current = _earliest[e.habitId];
      if (current == null || d.isBefore(current)) _earliest[e.habitId] = d;
    }
  }

  final Map<String, Entry> _byKey = {};
  final Map<String, DateTime> _earliest = {};

  static String _key(String habitId, String date) => '$habitId|$date';

  Entry? find(String habitId, String dateKey) => _byKey[_key(habitId, dateKey)];

  DateTime? earliestDate(String habitId) => _earliest[habitId];
}
