import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../date_utils.dart';

/// A tappable field that looks like the app's text inputs and opens
/// a date picker followed by a time picker.
class DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await pickDateTime(context, initial: value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(
          value == null ? 'Select date & time' : formatDateTime(value!),
          style: TextStyle(
            color: value == null ? AppColors.textMuted : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}