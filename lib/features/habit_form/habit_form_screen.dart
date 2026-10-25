import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/date_utils.dart';
import '../../core/habit_icons.dart';
import '../../domain/models/habit.dart';
import 'habit_form_validators.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  const HabitFormScreen({super.key, this.habitId});

  /// null = create a new habit.
  final String? habitId;

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _target = TextEditingController(text: '8');
  final _step = TextEditingController(text: '1');

  String _iconKey = habitIcons.keys.first;
  int _color = habitColors.first;
  final Set<int> _days = {...Habit.everyDay};
  bool _counted = false;
  DateTime _startDate = dateOnly(DateTime.now());
  Habit? _existing;
  bool _loading = false;
  bool _saving = false;
  String? _daysError;

  bool get _isEditing => widget.habitId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loading = true;
      _load();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _target.dispose();
    _step.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final habit =
        await ref.read(habitRepositoryProvider).getById(widget.habitId!);
    if (!mounted) return;
    if (habit == null || habit.isDeleted) {
      context.pop();
      return;
    }
    setState(() {
      _existing = habit;
      _name.text = habit.name;
      _iconKey = habit.iconKey;
      _color = habit.colorValue;
      _days
        ..clear()
        ..addAll(habit.scheduleDays);
      _startDate = dateOnly(habit.createdAt);
      _counted = habit.targetValue > 1;
      if (_counted) {
        _target.text = '${habit.targetValue}';
        _step.text = '${habit.step}';
        _unit.text = habit.unit ?? '';
      }
      _loading = false;
    });
  }

  Future<void> _pickStartDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isAfter(today) ? today : _startDate,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      helpText: 'Habit start date',
    );
    if (picked != null) setState(() => _startDate = dateOnly(picked));
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _daysError = _days.isEmpty ? 'Pick at least one day' : null);
    if (!valid || _days.isEmpty) return;

    setState(() => _saving = true);
    final repo = ref.read(habitRepositoryProvider);
    final now = DateTime.now();
    final name = _name.text.trim();
    final target = _counted ? int.parse(_target.text.trim()) : 1;
    final step = _counted ? int.parse(_step.text.trim()) : 1;
    final unitText = _unit.text.trim();
    final unit = _counted && unitText.isNotEmpty ? unitText : null;

    if (_existing == null) {
      await repo.create(Habit(
        id: const Uuid().v4(),
        name: name,
        iconKey: _iconKey,
        colorValue: _color,
        scheduleDays: {..._days},
        targetValue: target,
        unit: unit,
        step: step,
        createdAt: _startDate,
        updatedAt: now,
      ));
    } else {
      await repo.update(_existing!.copyWith(
        name: name,
        iconKey: _iconKey,
        colorValue: _color,
        scheduleDays: {..._days},
        targetValue: target,
        unit: () => unit,
        step: step,
        createdAt: _startDate,
      ));
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final habit = _existing!;
    final repo = ref.read(habitRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(habit.id);
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(SnackBar(
      content: Text('"${habit.name}" deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => repo.restore(habit.id),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: [
          if (_isEditing && _existing != null)
            IconButton(
              tooltip: 'Delete habit',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Drink water',
                      border: OutlineInputBorder(),
                    ),
                    validator: validateHabitName,
                  ),
                  const SizedBox(height: 24),
                  Text('Goal type', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.check_circle_outline),
                        label: Text('Check'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.numbers),
                        label: Text('Counted'),
                      ),
                    ],
                    selected: {_counted},
                    onSelectionChanged: (s) =>
                        setState(() => _counted = s.first),
                  ),
                  if (_counted) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _target,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Daily goal',
                              border: OutlineInputBorder(),
                            ),
                            validator: validateCountedTarget,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _unit,
                            decoration: const InputDecoration(
                              labelText: 'Unit (optional)',
                              hintText: 'glasses',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _step,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Amount per tap',
                        helperText: 'How much + and - change the count',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => validateStep(
                        v,
                        target: int.tryParse(_target.text.trim()),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Repeat on', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < 7; i++)
                        FilterChip(
                          label: Text(_dayLetters[i]),
                          tooltip: _dayNames[i],
                          selected: _days.contains(i + 1),
                          onSelected: (on) => setState(() {
                            on ? _days.add(i + 1) : _days.remove(i + 1);
                            _daysError = null;
                          }),
                        ),
                    ],
                  ),
                  if (_daysError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _daysError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text('Start date', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.event),
                    label: Text(DateFormat.yMMMd().format(_startDate)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick an earlier date to log days from before you '
                    'created the habit.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Text('Icon', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in habitIcons.entries)
                        ChoiceChip(
                          label: Icon(entry.value, size: 20),
                          tooltip: entry.key,
                          selected: _iconKey == entry.key,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _iconKey = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Color', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final c in habitColors)
                        Semantics(
                          button: true,
                          selected: _color == c,
                          label: 'Color option',
                          child: InkResponse(
                            onTap: () => setState(() => _color = c),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: _color == c
                                    ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 3,
                                      )
                                    : null,
                              ),
                              child: _color == c
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_isEditing ? 'Save changes' : 'Create habit'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
