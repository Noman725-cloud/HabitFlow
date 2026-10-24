import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/core/date_utils.dart';

void main() {
  test('toDateKey pads and round-trips', () {
    expect(toDateKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    expect(fromDateKey('2026-03-05'), DateTime(2026, 3, 5));
  });

  test('fromDateKey rejects malformed input', () {
    expect(() => fromDateKey('2026/03/05'), throwsFormatException);
  });

  test('addDays crosses month and year boundaries', () {
    expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
  });

  test('startOfWeek respects week start day', () {
    final saturday = DateTime(2026, 10, 24);
    expect(startOfWeek(saturday), DateTime(2026, 10, 19)); // Monday
    expect(
      startOfWeek(saturday, weekStartDay: DateTime.sunday),
      DateTime(2026, 10, 18),
    );
    expect(startOfWeek(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
  });
}
