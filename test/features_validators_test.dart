import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/features/habit_form/habit_form_validators.dart';

void main() {
  group('validateHabitName', () {
    test('rejects empty and whitespace', () {
      expect(validateHabitName(null), isNotNull);
      expect(validateHabitName('   '), isNotNull);
    });
    test('rejects names over 100 characters', () {
      expect(validateHabitName('a' * 101), isNotNull);
      expect(validateHabitName('a' * 100), isNull);
    });
    test('accepts a normal name', () {
      expect(validateHabitName('Drink water'), isNull);
    });
  });

  group('validateCountedTarget', () {
    test('requires a number of at least 2', () {
      expect(validateCountedTarget(''), isNotNull);
      expect(validateCountedTarget('abc'), isNotNull);
      expect(validateCountedTarget('1'), isNotNull);
      expect(validateCountedTarget('2'), isNull);
      expect(validateCountedTarget('8'), isNull);
    });
    test('has an upper bound', () {
      expect(validateCountedTarget('100001'), isNotNull);
    });
  });

  group('validateStep', () {
    test('must be a positive number', () {
      expect(validateStep('', target: 8), isNotNull);
      expect(validateStep('0', target: 8), isNotNull);
      expect(validateStep('1', target: 8), isNull);
    });
    test('cannot exceed the goal', () {
      expect(validateStep('9', target: 8), isNotNull);
      expect(validateStep('8', target: 8), isNull);
    });
    test('skips the upper check when the goal is unknown', () {
      expect(validateStep('500', target: null), isNull);
    });
  });
}
