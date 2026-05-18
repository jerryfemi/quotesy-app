import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:quotesy/models/streak_model.dart';
import 'package:quotesy/providers/database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const boxName = 'settings_box';
  late Directory hiveDir;
  late Box box;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('quotesy_streak_test_');
    Hive.init(hiveDir.path);
    box = await Hive.openBox(boxName);
  });

  tearDown(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(boxName);
    await hiveDir.delete(recursive: true);
  });

  group('StreakNotifier', () {
    test('build hydrates stored state without rollover side effects', () async {
      final lastOpened = DateTime.now().subtract(const Duration(days: 3));
      await box.putAll(<String, Object?>{
        'streak_current': 7,
        'streak_best': 10,
        'streak_last_opened': lastOpened.toIso8601String(),
        'streak_previous': 2,
        'streak_broken_from': lastOpened
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      });

      final container = ProviderContainer(
        overrides: [
          databaseInitProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      await container.read(databaseInitProvider.future);
      final streak = container.read(streakProvider);

      expect(streak.currentStreak, 7);
      expect(streak.bestStreak, 10);
      expect(streak.lastOpenedDate, DateTime.parse(lastOpened.toIso8601String()));
      expect(streak.previousStreak, 2);
      expect(streak.brokenFromDate, isNotNull);
    });

    test('reconcileOnAppOpen rolls streak and persists changes explicitly', () async {
      final yesterday = StreakData.dateOnly(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      await box.putAll(<String, Object?>{
        'streak_current': 3,
        'streak_best': 3,
        'streak_last_opened': yesterday.toIso8601String(),
        'streak_previous': 0,
        'streak_broken_from': null,
      });

      final container = ProviderContainer(
        overrides: [
          databaseInitProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      await container.read(databaseInitProvider.future);

      final notifier = container.read(streakProvider.notifier);
      final next = notifier.reconcileOnAppOpen();

      expect(next.currentStreak, 4);
      expect(next.bestStreak, 4);
      expect(next.lastOpenedDate, StreakData.dateOnly(DateTime.now()));

      expect(box.get('streak_current'), 4);
      expect(box.get('streak_best'), 4);
      expect(
        box.get('streak_last_opened'),
        StreakData.dateOnly(DateTime.now()).toIso8601String(),
      );
    });

    test('reconcileOnAppOpen is a no-op while database init is loading', () {
      final container = ProviderContainer(
        overrides: [
          databaseInitProvider.overrideWith((ref) async {
            await Future<void>.delayed(const Duration(seconds: 10));
          }),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(streakProvider);
      final next = container.read(streakProvider.notifier).reconcileOnAppOpen();

      expect(initial.currentStreak, 0);
      expect(initial.bestStreak, 0);
      expect(next.currentStreak, 0);
      expect(next.bestStreak, 0);
      expect(next.lastOpenedDate, isNull);
    });
  });
}
