import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../monetization/data/consent_service.dart';

/// MVP-04 / #27: reachable from a small info button on the home screen.
/// Carries the three things CLAUDE.md and PRD v3 §3/§9 require in the app
/// itself, permanently (not just once-per-session in voice): the AI-avatar
/// disclaimer, CC BY 4.0 attribution for the KrishnaJI Rive character, and a
/// link to the published privacy policy.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _privacyPolicyUrl =
      'https://vageshwar.github.io/chibi-krishna/legal/privacy-policy.html';
  static const _termsOfServiceUrl =
      'https://vageshwar.github.io/chibi-krishna/legal/terms-of-service.html';
  static const _riveMarketplaceUrl =
      'https://rive.app/marketplace/27686-52286-krishnaji/';
  static const _ccByLicenseUrl = 'https://creativecommons.org/licenses/by/4.0/';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chibi Krishna AI',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Verbatim, PRD v3 §3 — permanent About-screen statement of the
          // AI-avatar disclaimer (voice only carries a once-per-session cue).
          const Text(
            'AI avatar of Krishna, created to share joy and Gita-inspired '
            'wisdom. Not a living guru, not a replacement for temple, '
            'family, or clinicians.',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Character credit'),
          const SizedBox(height: 8),
          const Text(
            'The Krishna character rig ("KrishnaJI") is by creator ar.akash, '
            'from the Rive marketplace, used under a Creative Commons '
            'Attribution 4.0 license.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 8),
          _LinkRow(label: 'View on Rive marketplace', url: _riveMarketplaceUrl, onTap: _openUrl),
          _LinkRow(label: 'CC BY 4.0 license', url: _ccByLicenseUrl, onTap: _openUrl),
          const SizedBox(height: 28),
          const _SectionTitle('Legal'),
          const SizedBox(height: 8),
          _LinkRow(label: 'Privacy Policy', url: _privacyPolicyUrl, onTap: _openUrl),
          _LinkRow(label: 'Terms of Service', url: _termsOfServiceUrl, onTap: _openUrl),
          // GDPR requires this stay reachable after first launch, not just
          // shown once — only rendered where Google's own geography check
          // (EEA/UK/CH) says a privacy-options entry point is required.
          FutureBuilder<bool>(
            future: ConsentService().isPrivacyOptionsRequired(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return _ActionRow(
                label: 'Manage ad privacy choices',
                onTap: () => ConsentService().showPrivacyOptionsForm((error) {
                  if (error != null) {
                    debugPrint('AboutScreen: privacy options form note: $error');
                  }
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.tune, color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String url;
  final Future<void> Function(String url) onTap;

  const _LinkRow({required this.label, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.open_in_new, color: Color(0xFFFFD700), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
