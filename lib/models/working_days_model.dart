import 'package:flutter/material.dart';

/// Data model for each day
class WorkingDays {
  final String label;
  bool selected;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  WorkingDays({
    required this.label,
    this.selected = false,
    this.startTime,
    this.endTime,
  });

  WorkingDays copyWith({
    bool? selected,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return WorkingDays(
      label: label,
      selected: selected ?? this.selected,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
