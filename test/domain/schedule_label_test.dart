import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/core/schedule_label.dart';

void main() {
  test('common patterns get friendly names', () {
    expect(scheduleLabel({1, 2, 3, 4, 5, 6, 7}), 'Every day');
    expect(scheduleLabel({1, 2, 3, 4, 5}), 'Weekdays');
    expect(scheduleLabel({6, 7}), 'Weekends');
  });

  test('other patterns list the days in order', () {
    expect(scheduleLabel({5, 1, 3}), 'Mon, Wed, Fri');
    expect(scheduleLabel({2}), 'Tue');
  });
}
