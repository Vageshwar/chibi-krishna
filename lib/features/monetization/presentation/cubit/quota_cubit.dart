import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/quota_repository.dart';
import 'quota_state.dart';

/// FF-04 orchestration: holds today's quota snapshot and lets
/// ConversationCubit check/consume a voice turn before deciding whether to
/// answer normally or prompt for a rewarded ad.
class QuotaCubit extends Cubit<QuotaState> {
  QuotaCubit({required QuotaRepository quotaRepository})
      : _quotaRepository = quotaRepository,
        super(const QuotaState());

  final QuotaRepository _quotaRepository;

  Future<void> initialize() async {
    await _quotaRepository.initialize();
    final snapshot = await _quotaRepository.currentStatus();
    emit(_stateFrom(snapshot));
  }

  /// Returns true and consumes a turn if one was available; returns false
  /// without consuming anything if the caller should prompt for an ad.
  Future<bool> tryConsumeVoiceTurn() async {
    final snapshot = await _quotaRepository.tryConsumeVoiceTurn();
    if (snapshot == null) return false;
    emit(_stateFrom(snapshot));
    return true;
  }

  Future<void> grantRewardTurns() async {
    final snapshot = await _quotaRepository.grantRewardTurns();
    emit(_stateFrom(snapshot));
  }

  QuotaState _stateFrom(QuotaSnapshot snapshot) => QuotaState(
        voiceTurnsUsed: snapshot.voiceTurnsUsed,
        rewardTurnsRemaining: snapshot.rewardTurnsRemaining,
        referralTurnsRemaining: snapshot.referralTurnsRemaining,
        isInitialized: true,
      );
}
