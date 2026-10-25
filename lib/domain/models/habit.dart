import '../../core/date_utils.dart';

/// A habit with a numeric daily target. A plain checkbox habit has
/// [targetValue] == 1 and no unit.
class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required Set<int> scheduleDays,
    this.targetValue = 1,
    this.unit,
    this.step = 1,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.deletedAt,
  })  : scheduleDays = Set.unmodifiable(scheduleDays),
        assert(targetValue >= 1, 'targetValue must be >= 1'),
        assert(step >= 1, 'step must be >= 1'),
        assert(scheduleDays.isNotEmpty, 'schedule cannot be empty'),
        assert(
          scheduleDays.every((d) => d >= 1 && d <= 7),
          'scheduleDays must be 1 (Mon) .. 7 (Sun)',
        );

  static const Set<int> everyDay = {1, 2, 3, 4, 5, 6, 7};

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;

  /// 1 = Monday .. 7 = Sunday (matches [DateTime.weekday]).
  final Set<int> scheduleDays;
  final int targetValue;
  final String? unit;

  /// Amount added per tap in the UI (e.g. 250 for ml).
  final int step;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// User-facing archive: hidden from Today, history preserved.
  final DateTime? archivedAt;

  /// Tombstone for future sync. Treated as deleted everywhere.
  final DateTime? deletedAt;

  bool get isCheckHabit => targetValue == 1;
  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;

  bool isScheduledOn(DateTime day) => scheduleDays.contains(day.weekday);

  /// Whether this habit counts on [day]: not deleted, on/after its creation
  /// date, before it was archived, and on a scheduled weekday.
  bool isTrackedOn(DateTime day) {
    final d = dateOnly(day);
    if (isDeleted) return false;
    if (d.isBefore(dateOnly(createdAt))) return false;
    if (archivedAt != null && !d.isBefore(dateOnly(archivedAt!))) return false;
    return isScheduledOn(d);
  }

  Habit copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    Set<int>? scheduleDays,
    int? targetValue,
    String? Function()? unit,
    int? step,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? Function()? archivedAt,
    DateTime? Function()? deletedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      targetValue: targetValue ?? this.targetValue,
      unit: unit != null ? unit() : this.unit,
      step: step ?? this.step,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt != null ? archivedAt() : this.archivedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }
}
