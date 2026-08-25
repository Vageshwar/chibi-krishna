import 'package:flutter/material.dart';
import '../../data/ad_service.dart';

/// FF-06: publisher-voiced Support sheet — shown either when the daily voice
/// quota runs out, or voluntarily from the top-right "Dakshina" support
/// button (PRD v3 §7: same sheet, same mechanic, either entry point). Krishna
/// never speaks this copy — locked decision (PRD v3 §3, §7): monetization
/// language is always the publisher's, never in-character.
///
/// Pops `true` if the user watched to completion and earned the reward,
/// `false`/null on "Not now" or a dismiss — caller decides what happens next.
class SupportSheet extends StatefulWidget {
  final AdService adService;

  /// True when opened from the voluntary support button rather than because
  /// quota ran out — swaps the subtitle copy so it doesn't wrongly imply the
  /// user is blocked.
  final bool isVoluntary;

  const SupportSheet({
    super.key,
    required this.adService,
    this.isVoluntary = false,
  });

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  bool _showingAd = false;

  Future<void> _watchAd() async {
    if (_showingAd) return;
    setState(() => _showingAd = true);
    await widget.adService.showRewardedAd(
      onEarned: () {
        if (mounted) Navigator.of(context).pop(true);
      },
      onDismissedWithoutReward: () {
        if (mounted) setState(() => _showingAd = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adReady = widget.adService.isRewardedAdReady;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Support Chibi Krishna AI',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isVoluntary
                  ? 'Watch a short video to help keep Chibi Krishna AI free — and earn a few extra questions for today.'
                  : "You've used today's free questions. Watch a short video for more questions.",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: adReady && !_showingAd ? _watchAd : null,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(
                _showingAd
                    ? 'Loading…'
                    : (adReady ? 'Watch a short video' : 'Video not ready yet'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                disabledBackgroundColor: const Color(0xFF25293A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Not now',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
