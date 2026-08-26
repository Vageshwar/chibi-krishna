import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// UMP consent gate — required before any AdMob request in the EEA/UK/CH;
/// Google enforces this at the account level, not just as a nicety, and the
/// published privacy policy already claims this flow exists
/// (docs/legal/privacy_policy.md). A no-op outside those regions —
/// [ConsentForm.loadAndShowConsentFormIfRequired] only shows a form when
/// Google's own geography check says one's required.
///
/// Called once per app launch, before [AdService.initialize] — ad requests
/// should not go out until [ConsentInformation.canRequestAds] is confirmed
/// true (Google's own recommended gating).
class ConsentService {
  static const _timeout = Duration(seconds: 8);

  /// Runs the full consent flow and returns whether ad requests may proceed
  /// this session. Never throws; any failure/timeout defaults to false —
  /// safer than assuming consent was given.
  Future<bool> requestConsentAndCheck() async {
    try {
      await _requestAndShowIfRequired().timeout(_timeout);
    } catch (e) {
      debugPrint('ConsentService: note: $e');
      return false;
    }
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('ConsentService: canRequestAds() note: $e');
      return false;
    }
  }

  Future<void> _requestAndShowIfRequired() {
    final completer = Completer<void>();
    final params = ConsentRequestParameters(
      // Debug-only: forces this device to be treated as EEA so the consent
      // form can actually be exercised from India during development.
      // Hashed ID is this project's physical test device (same one AdMob's
      // own test-ad logging already uses) — add more here if testing on a
      // different device; UMP logs the ID to add on first run without it.
      consentDebugSettings: kDebugMode
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: const ['1F2F1D92261FFE5C55441588DFF8DED7'],
            )
          : null,
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _loadAndShowIfRequired();
          }
        } catch (e) {
          debugPrint('ConsentService: form note: $e');
        }
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        debugPrint('ConsentService: requestConsentInfoUpdate failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  Future<void> _loadAndShowIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((formError) {
      if (formError != null) {
        debugPrint('ConsentService: form dismissed with error: ${formError.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  /// Whether a "privacy options" entry point must be reachable somewhere in
  /// the app — GDPR requires letting users revisit their choice later, not
  /// just see it once at first launch. Surfaced in the About screen.
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('ConsentService: getPrivacyOptionsRequirementStatus() note: $e');
      return false;
    }
  }

  void showPrivacyOptionsForm(void Function(String? errorMessage) onDismissed) {
    ConsentForm.showPrivacyOptionsForm((formError) => onDismissed(formError?.message));
  }
}
