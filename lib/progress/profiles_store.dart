import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/models.dart';
import 'child_profile.dart';
import 'srs.dart';

/// All children on this device and their progress, saved locally only.
class ProfilesStore extends ChangeNotifier {
  ProfilesStore._(this._prefs, this._children, this.now);

  static const maxChildren = 4;
  static const _key = 'children.v1';

  final SharedPreferences _prefs;
  final List<ChildProfile> _children;
  ChildProfile? _current;

  /// The clock; tests replace it to move between days.
  final DateTime Function() now;

  static Future<ProfilesStore> load({
    DateTime Function() now = DateTime.now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final children = raw == null
        ? <ChildProfile>[]
        : (jsonDecode(raw) as List)
              .cast<Map<String, dynamic>>()
              .map(ChildProfile.fromJson)
              .toList();
    return ProfilesStore._(prefs, children, now);
  }

  List<ChildProfile> get children => List.unmodifiable(_children);
  ChildProfile? get current => _current;
  bool get canAddChild => _children.length < maxChildren;

  void select(ChildProfile child) {
    _current = child;
    notifyListeners();
  }

  Future<ChildProfile> addChild({
    required String avatar,
    required AgeLevel level,
    String name = '',
  }) async {
    if (!canAddChild) {
      throw StateError('At most $maxChildren children per device');
    }
    final child = ChildProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      avatar: avatar,
      level: level,
      name: name.trim(),
    );
    _children.add(child);
    _current = child;
    await _save();
    return child;
  }

  /// Records a finished lesson: best stars, spaced-repetition boxes for every
  /// word practised, new stickers, and today's flower in the garden.
  ///
  /// [mistakesByWord] holds every word that was quizzed (0 = right first time).
  Future<LessonReward> recordLesson({
    required Lesson lesson,
    required int stars,
    required Map<String, int> mistakesByWord,
  }) async {
    final child = _current;
    if (child == null) return const LessonReward();
    final today = dayNumber(now());
    final best = child.lessonStars[lesson.key] ?? 0;
    if (stars > best) child.lessonStars[lesson.key] = stars;
    for (final MapEntry(key: id, value: mistakes) in mistakesByWord.entries) {
      final stats = child.words[id] ?? const WordStats();
      child.words[id] = stats.practised(
        firstTry: mistakes == 0,
        mistakes: mistakes,
        today: today,
      );
    }
    final newStickers = [
      for (final w in lesson.words)
        if (child.stickers.add(w.id)) w.id,
    ];
    final newFlower = child.playDays.add(today);
    await _save();
    return LessonReward(newStickers: newStickers, newFlower: newFlower);
  }

  Future<void> _save() async {
    await _prefs.setString(
      _key,
      jsonEncode(_children.map((c) => c.toJson()).toList()),
    );
    notifyListeners();
  }
}

/// What a finished lesson earned, for the celebration screen.
class LessonReward {
  const LessonReward({this.newStickers = const [], this.newFlower = false});

  final List<String> newStickers;
  final bool newFlower;
}
