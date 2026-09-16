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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              // Three short lines rather than one run-on sentence — now that
              // there are two helplines plus the family prompt, cramming
              // everything into a single Text overflowed on narrow screens.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Helplines.familyPrompt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      '${Helplines.indiaEmergencyLabel} · ${Helplines.kiranLabel}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                    Text(
                      Helplines.counselingLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
