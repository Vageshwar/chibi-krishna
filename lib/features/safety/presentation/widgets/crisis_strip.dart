import 'package:flutter/material.dart';

import '../../data/helplines.dart';

/// Persistent crisis safety strip (FF-03). Never a dismissible snackbar —
/// CLAUDE.md and PRD v3 §9 require it to stay visible for the rest of the
/// session once triggered. No close button, no auto-fade — do not reuse the
/// home screen's fading response-bubble pattern here.
class CrisisStrip extends StatelessWidget {
  const CrisisStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB00020),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${Helplines.familyPrompt} ${Helplines.indiaEmergencyLabel} · ${Helplines.counselingLabel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
