import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/models.dart';
import 'child_profile.dart';

/// All children on this device and their progress, saved locally only.
class ProfilesStore extends ChangeNotifier {
  ProfilesStore._(this._prefs, this._children);

  static const maxChildren = 4;
  static const _key = 'children.v1';

  final SharedPreferences _prefs;
  final List<ChildProfile> _children;
  ChildProfile? _current;

  static Future<ProfilesStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final children = raw == null
        ? <ChildProfile>[]
        : (jsonDecode(raw) as List)
              .cast<Map<String, dynamic>>()
              .map(ChildProfile.fromJson)
              .toList();
    return ProfilesStore._(prefs, children);
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

  /// Records a finished lesson. Keeps the best star count ever earned.
  Future<void> recordLesson({
    required Lesson lesson,
    required int stars,
    required Map<String, int> correctByWord,
    required Map<String, int> wrongByWord,
  }) async {
    final child = _current;
    if (child == null) return;
    final best = child.lessonStars[lesson.key] ?? 0;
    if (stars > best) child.lessonStars[lesson.key] = stars;
    for (final word in lesson.words) {
      final stats = child.words[word.id] ?? const WordStats();
      child.words[word.id] = stats.add(
        correct: correctByWord[word.id] ?? 0,
        wrong: wrongByWord[word.id] ?? 0,
      );
    }
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setString(
      _key,
      jsonEncode(_children.map((c) => c.toJson()).toList()),
    );
    notifyListeners();
  }
}
