import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

class Quote {
  final String id;
  final String en;
  final String hi;

  const Quote({required this.id, required this.en, required this.hi});

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'] as String,
        en: json['en'] as String,
        hi: json['hi'] as String,
      );
}

/// Loads assets/gita/mvp_quotes.json (original short paraphrases, not scraped
/// scripture) and hands back a random pick that never immediately repeats.
/// No network, no cost — this is the MVP's canned-response path, replaced by
/// Gemini in the V1 milestone (see FF-01).
class QuoteRepository {
  List<Quote> _quotes = const [];
  String? _lastId;
  final Random _random = Random();

  Future<void> load() async {
    if (_quotes.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/gita/mvp_quotes.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _quotes = list.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Quote pickRandom() {
    if (_quotes.isEmpty) {
      throw StateError('QuoteRepository.load() must complete before pickRandom().');
    }
    if (_quotes.length == 1) return _quotes.first;
    Quote picked;
    do {
      picked = _quotes[_random.nextInt(_quotes.length)];
    } while (picked.id == _lastId);
    _lastId = picked.id;
    return picked;
  }

  String textFor(Quote quote, {required bool isHindi}) => isHindi ? quote.hi : quote.en;
}
