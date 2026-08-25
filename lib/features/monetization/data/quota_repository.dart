import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Immutable snapshot of today's quota row.
class QuotaSnapshot {
  final int voiceTurnsUsed;
  final int rewardTurnsRemaining;
  final int referralTurnsRemaining;

  const QuotaSnapshot({
    required this.voiceTurnsUsed,
    required this.rewardTurnsRemaining,
    required this.referralTurnsRemaining,
  });

  bool get hasTurnAvailable =>
      voiceTurnsUsed < QuotaRepository.freeTurnsPerDay ||
      rewardTurnsRemaining > 0 ||
      referralTurnsRemaining > 0;
}

/// FF-04: local daily voice-turn quota. SQLite via sqflite, which ships both
/// an Android and an iOS implementation — no cloud DB, matches CLAUDE.md's
/// no-backend rule. Schema matches the issue's spec exactly: date,
/// voice_turns_used, reward_turns_remaining, referral_turns_remaining.
///
/// Referral turns are tracked here but nothing grants them yet — that's
/// FF-07 (#19), not built as part of this pass. The column exists now so the
/// schema doesn't need a migration later.
class QuotaRepository {
  static const int freeTurnsPerDay = 10;
  static const int rewardTurnsGranted = 5;

  Database? _db;

  Future<void> initialize() async {
    if (_db != null) return;
    final dbPath = p.join(await getDatabasesPath(), 'chibi_krishna_quota.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE daily_usage (
          date TEXT PRIMARY KEY,
          voice_turns_used INTEGER NOT NULL DEFAULT 0,
          reward_turns_remaining INTEGER NOT NULL DEFAULT 0,
          referral_turns_remaining INTEGER NOT NULL DEFAULT 0
        )
      '''),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Database get _requireDb {
    final db = _db;
    if (db == null) throw StateError('QuotaRepository.initialize() not called yet');
    return db;
  }

  /// Local-midnight reset falls out naturally: each new date gets its own
  /// fresh row (bonus pools don't carry over from a previous day).
  Future<Map<String, Object?>> _todayRow() async {
    final today = _todayKey();
    final rows = await _requireDb.query('daily_usage', where: 'date = ?', whereArgs: [today]);
    if (rows.isNotEmpty) return rows.first;

    final fresh = <String, Object?>{
      'date': today,
      'voice_turns_used': 0,
      'reward_turns_remaining': 0,
      'referral_turns_remaining': 0,
    };
    await _requireDb.insert('daily_usage', fresh, conflictAlgorithm: ConflictAlgorithm.ignore);
    return fresh;
  }

  Future<QuotaSnapshot> currentStatus() async {
    final row = await _todayRow();
    return QuotaSnapshot(
      voiceTurnsUsed: row['voice_turns_used']! as int,
      rewardTurnsRemaining: row['reward_turns_remaining']! as int,
      referralTurnsRemaining: row['referral_turns_remaining']! as int,
    );
  }

  /// Consumes one voice turn — free daily allowance first, then reward
  /// turns, then referral turns — and returns the resulting snapshot.
  /// Returns null without consuming anything if none are left today.
  Future<QuotaSnapshot?> tryConsumeVoiceTurn() async {
    final row = await _todayRow();
    final today = row['date']! as String;
    var used = row['voice_turns_used']! as int;
    var reward = row['reward_turns_remaining']! as int;
    var referral = row['referral_turns_remaining']! as int;

    if (used < freeTurnsPerDay) {
      used += 1;
    } else if (reward > 0) {
      reward -= 1;
      used += 1;
    } else if (referral > 0) {
      referral -= 1;
      used += 1;
    } else {
      return null;
    }

    await _requireDb.update(
      'daily_usage',
      {'voice_turns_used': used, 'reward_turns_remaining': reward, 'referral_turns_remaining': referral},
      where: 'date = ?',
      whereArgs: [today],
    );
    return QuotaSnapshot(voiceTurnsUsed: used, rewardTurnsRemaining: reward, referralTurnsRemaining: referral);
  }

  /// FF-06: grant reward turns after a completed rewarded-ad view.
  Future<QuotaSnapshot> grantRewardTurns() async {
    final row = await _todayRow();
    final today = row['date']! as String;
    final reward = (row['reward_turns_remaining']! as int) + rewardTurnsGranted;

    await _requireDb.update(
      'daily_usage',
      {'reward_turns_remaining': reward},
      where: 'date = ?',
      whereArgs: [today],
    );
    return QuotaSnapshot(
      voiceTurnsUsed: row['voice_turns_used']! as int,
      rewardTurnsRemaining: reward,
      referralTurnsRemaining: row['referral_turns_remaining']! as int,
    );
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
