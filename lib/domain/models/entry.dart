/// Progress for one habit on one local calendar day.
class Entry {
  const Entry({
    required this.id,
    required this.habitId,
    required this.date,
    required this.value,
    required this.target,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String habitId;

  /// Local calendar date, 'yyyy-MM-dd'.
  final String date;
  final int value;

  /// Snapshot of the habit's target for this day. Editing a habit's goal later
  /// must not rewrite history, so "met" is judged against this, not the
  /// habit's current target.
  final int target;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isMet => target > 0 && value >= target;

  /// 0.0 .. 1.0 (over-achievement is clamped; show 100%+ in the UI from
  /// [value]/[target] directly if desired).
  double get progress =>
      target <= 0 ? 0 : (value / target).clamp(0.0, 1.0).toDouble();
}
