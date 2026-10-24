String? validateHabitName(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Enter a name';
  if (text.length > 100) return 'Keep it under 100 characters';
  return null;
}

/// Goal for a counted habit. A goal of 1 is just a Check habit.
String? validateCountedTarget(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a number';
  if (n < 2) return 'Use 2 or more (or choose Check)';
  if (n > 100000) return 'That is too large';
  return null;
}

String? validateStep(String? value, {required int? target}) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null) return 'Enter a number';
  if (n < 1) return 'Must be at least 1';
  if (target != null && n > target) return 'Cannot exceed the goal';
  return null;
}
