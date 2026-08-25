import 'package:equatable/equatable.dart';
import '../../data/quota_repository.dart';

class QuotaState extends Equatable {
  final int voiceTurnsUsed;
  final int rewardTurnsRemaining;
  final int referralTurnsRemaining;
  final bool isInitialized;

  const QuotaState({
    this.voiceTurnsUsed = 0,
    this.rewardTurnsRemaining = 0,
    this.referralTurnsRemaining = 0,
    this.isInitialized = false,
  });

  bool get hasTurnAvailable =>
      voiceTurnsUsed < QuotaRepository.freeTurnsPerDay ||
      rewardTurnsRemaining > 0 ||
      referralTurnsRemaining > 0;

  QuotaState copyWith({
    int? voiceTurnsUsed,
    int? rewardTurnsRemaining,
    int? referralTurnsRemaining,
    bool? isInitialized,
  }) {
    return QuotaState(
      voiceTurnsUsed: voiceTurnsUsed ?? this.voiceTurnsUsed,
      rewardTurnsRemaining: rewardTurnsRemaining ?? this.rewardTurnsRemaining,
      referralTurnsRemaining: referralTurnsRemaining ?? this.referralTurnsRemaining,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => [voiceTurnsUsed, rewardTurnsRemaining, referralTurnsRemaining, isInitialized];
}
