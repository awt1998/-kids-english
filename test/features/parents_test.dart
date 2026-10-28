import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_english/app.dart';
import 'package:kids_english/audio/audio_service.dart';
import 'package:kids_english/content/content_repository.dart';
import 'package:kids_english/content/models.dart';
import 'package:kids_english/features/parents/child_report_screen.dart';
import 'package:kids_english/features/parents/parent_zone_screen.dart';
import 'package:kids_english/features/parents/parental_gate.dart';
import 'package:kids_english/features/parents/time_up_screen.dart';
import 'package:kids_english/features/lesson/lesson_screen.dart';
import 'package:kids_english/progress/app_settings.dart';
import 'package:kids_english/progress/child_profile.dart';
import 'package:kids_english/progress/profiles_store.dart';
import 'package:kids_english/progress/srs.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _numbers = {
  'اثنان': 2,
  'ثلاثة': 3,
  'أربعة': 4,
  'خمسة': 5,
  'ستة': 6,
  'سبعة': 7,
  'ثمانية': 8,
  'تسعة': 9, //
};

/// Reads the gate's question the way a parent would and returns the answer.
int answerOnScreen(WidgetTester tester) {
  final text = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((t) => t.contains('ضرب'));
  final factors = _numbers.entries
      .where((e) => text.contains(' ${e.key}'))
      .map((e) => e.value)
      .toList();
  // Same number twice ("ستة في ستة") appears once in the list.
  return factors.length == 1
      ? factors.first * factors.first
      : factors[0] * factors[1];
}

Future<void> typeOnGate(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.byKey(ValueKey('gate-$d')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const ValueKey('gate-ok')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('parental gate question', () {
    test('is a multiplication written only in words', () {
      for (var seed = 0; seed < 50; seed++) {
        final q = GateQuestion(Random(seed));
        expect(q.answer, q.a * q.b);
        expect(q.a, inInclusiveRange(3, 9));
        expect(
          q.text,
          isNot(matches(RegExp(r'[0-9٠-٩]'))),
          reason: 'digits would let children copy them',
        );
        expect(q.accepts('${q.answer}'), isTrue);
        expect(q.accepts('${q.answer + 1}'), isFalse);
        expect(q.accepts(''), isFalse);
      }
    });
  });

  group('the app', () {
    late ContentRepository content;
    late ProfilesStore profiles;
    late AppSettings settings;
    late SilentAudioService audio;
    var now = DateTime(2026, 5, 3, 10);

    Future<void> start(
      WidgetTester tester, {
      int minutesPlayedToday = 0,
    }) async {
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      content = (await tester.runAsync(ContentRepository.load))!;
      profiles = (await tester.runAsync(
        () => ProfilesStore.load(now: () => now),
      ))!;
      settings = (await tester.runAsync(AppSettings.load))!;
      audio = SilentAudioService();
      final child = (await tester.runAsync(
        () => profiles.addChild(
          avatar: 'cat',
          level: AgeLevel.middle,
          name: 'سارة',
        ),
      ))!;
      child.secondsByDay[dayNumber(now)] = minutesPlayedToday * 60;
      child.words['apple'] = const WordStats(box: 1, wrong: 4);
      child.words['banana'] = const WordStats(box: 4, correct: 4);
      await tester.pumpWidget(
        KidsEnglishApp(
          content: content,
          profiles: profiles,
          audio: audio,
          settings: settings,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
    }

    Future<void> openParentZone(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('open-parents')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ParentalGateScreen), findsOneWidget);
      await typeOnGate(tester, '${answerOnScreen(tester)}');
      expect(find.byType(ParentZoneScreen), findsOneWidget);
    }

    testWidgets('a wrong answer keeps the gate shut and asks a new question', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.byKey(const ValueKey('open-parents')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final right = answerOnScreen(tester);
      await typeOnGate(tester, '${right == 1 ? 2 : 1}');
      expect(find.byType(ParentalGateScreen), findsOneWidget);
      expect(find.byType(ParentZoneScreen), findsNothing);
      await typeOnGate(tester, '${answerOnScreen(tester)}');
      expect(find.byType(ParentZoneScreen), findsOneWidget);
    });

    testWidgets('settings: sound effects and music can be switched off', (
      tester,
    ) async {
      await start(tester);
      await openParentZone(tester);
      await tester.tap(find.byKey(const ValueKey('setting-sfx')));
      await tester.tap(find.byKey(const ValueKey('setting-music')));
      await tester.pump();
      expect(settings.soundEffects, isFalse);
      expect(settings.music, isFalse);
      expect(audio.musicPlaying, isFalse);
      audio.playSfx(Sfx.tap);
      expect(audio.played, isNot(contains('sfx:tap')));
    });

    testWidgets(
      'report shows hard words; deleting a child needs a second tap',
      (tester) async {
        await start(tester);
        await openParentZone(tester);
        await tester.tap(
          find.byKey(ValueKey('parents-child-${profiles.children.single.id}')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ChildReportScreen), findsOneWidget);
        expect(
          find.text('apple'),
          findsOneWidget,
          reason: 'four mistakes: a hard word',
        );
        expect(find.text('banana'), findsNothing, reason: 'mastered, not hard');

        await tester.tap(find.byKey(const ValueKey('report-level-big')));
        await tester.pump();
        expect(profiles.children.single.level, AgeLevel.big);

        await tester.ensureVisible(find.byKey(const ValueKey('report-delete')));
        await tester.tap(find.byKey(const ValueKey('report-delete')));
        await tester.pump();
        expect(
          profiles.children,
          hasLength(1),
          reason: 'first tap only asks to confirm',
        );
        await tester.tap(find.byKey(const ValueKey('report-delete')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(profiles.children, isEmpty);
      },
    );

    testWidgets('after the daily limit, a lesson shows sleepy Labeeb instead', (
      tester,
    ) async {
      await start(tester, minutesPlayedToday: 20);
      await settings.setDailyLimitMinutes(15);
      await tester.tap(find.byKey(ValueKey(profiles.children.single.id)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('stop-fruits:0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TimeUpScreen), findsOneWidget);
      expect(find.byType(LessonScreen), findsNothing);
      expect(audio.played, contains('prompt:timeUp'));
    });

    testWidgets(
      'below the limit lessons start normally, and play time is counted',
      (tester) async {
        await start(tester, minutesPlayedToday: 5);
        await settings.setDailyLimitMinutes(15);
        await tester.tap(find.byKey(ValueKey(profiles.children.single.id)));
        await tester.pump();
        await tester.pump(
          const Duration(seconds: 31),
        ); // a few ticks on the map
        final child = profiles.children.single;
        expect(
          child.secondsOn(dayNumber(now)),
          greaterThanOrEqualTo(5 * 60 + 30),
        );
        await tester.tap(find.byKey(const ValueKey('stop-fruits:0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(LessonScreen), findsOneWidget);
      },
    );
  });
}
