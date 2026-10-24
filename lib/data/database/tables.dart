import 'package:drift/drift.dart';

@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get iconKey => text()();
  IntColumn get colorValue => integer()();

  /// Bitmask: bit (weekday - 1) set => scheduled. Mon = bit 0 .. Sun = bit 6.
  IntColumn get scheduleMask => integer()();
  IntColumn get targetValue => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().nullable()();
  IntColumn get step => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EntryRow')
class HabitEntries extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().references(Habits, #id)();

  /// Local calendar date, 'yyyy-MM-dd'.
  TextColumn get date => text().withLength(min: 10, max: 10)();
  IntColumn get value => integer()();
  IntColumn get target => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}
