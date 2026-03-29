import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/set.dart' as gym;
import '../../theme/app_theme.dart';
import 'arrow_button.dart';

class SetRow extends StatelessWidget {
  final int setIndex;
  final gym.Set set;
  final int exerciseIndex;
  final Color accent;
  final VoidCallback onDecrementReps;
  final VoidCallback onIncrementReps;
  final VoidCallback onDecrementWeight;
  final VoidCallback onIncrementWeight;
  final VoidCallback onEdit;

  const SetRow({
    super.key,
    required this.setIndex,
    required this.set,
    required this.exerciseIndex,
    required this.accent,
    required this.onDecrementReps,
    required this.onIncrementReps,
    required this.onDecrementWeight,
    required this.onIncrementWeight,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: terminalBorder),
            ),
            child: Text(
              '${setIndex + 1}',
              style: GoogleFonts.jetBrainsMono(fontSize: 9),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${set.weight}kg x ${set.reps}${set.rpe != null ? ' @${set.rpe}' : ''}',
              style: GoogleFonts.jetBrainsMono(fontSize: 11),
            ),
          ),
          ArrowButton(
            icon: Icons.keyboard_arrow_down,
            onTap: onDecrementReps,
            accent: accent,
          ),
          ArrowButton(
            icon: Icons.keyboard_arrow_up,
            onTap: onIncrementReps,
            accent: accent,
          ),
          const SizedBox(width: 4),
          ArrowButton(
            icon: Icons.keyboard_arrow_down,
            onTap: onDecrementWeight,
            accent: accent,
          ),
          ArrowButton(
            icon: Icons.keyboard_arrow_up,
            onTap: onIncrementWeight,
            accent: accent,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onEdit,
            child: Container(
              width: 36,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: accent),
              ),
              child: Text(
                'EDIT',
                style: GoogleFonts.jetBrainsMono(fontSize: 7, color: accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
