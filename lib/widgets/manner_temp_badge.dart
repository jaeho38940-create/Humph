import 'package:flutter/material.dart';

class MannerTempBadge extends StatelessWidget {
  final double temperature;
  final bool showLabel;

  const MannerTempBadge({
    super.key,
    required this.temperature,
    this.showLabel = true,
  });

  Color get _color {
    if (temperature >= 40) return Colors.red;
    if (temperature >= 37.5) return Colors.orange;
    if (temperature >= 36) return Colors.green;
    return Colors.blue;
  }

  String get _emoji {
    if (temperature >= 40) return '🔥';
    if (temperature >= 37.5) return '😊';
    if (temperature >= 36) return '😃';
    return '😐';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${temperature.toStringAsFixed(1)}°C',
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(_emoji, style: const TextStyle(fontSize: 16)),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            'Manner',
            style: TextStyle(
              color: _color,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
