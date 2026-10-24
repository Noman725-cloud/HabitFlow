import 'package:flutter/material.dart';

/// Icons a habit can use. Stored by key so the database never depends on
/// Flutter's icon code points.
const Map<String, IconData> habitIcons = {
  'water': Icons.water_drop,
  'run': Icons.directions_run,
  'fitness': Icons.fitness_center,
  'book': Icons.menu_book,
  'meditate': Icons.self_improvement,
  'sleep': Icons.bedtime,
  'food': Icons.restaurant,
  'code': Icons.code,
  'music': Icons.music_note,
  'pencil': Icons.edit,
  'heart': Icons.favorite,
  'star': Icons.star,
};

IconData iconFor(String key) => habitIcons[key] ?? Icons.star;

const List<int> habitColors = [
  0xFF4F46E5,
  0xFF0EA5E9,
  0xFF10B981,
  0xFF84CC16,
  0xFFF59E0B,
  0xFFEF4444,
  0xFFEC4899,
  0xFF8B5CF6,
];
