import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models.dart';

class GameContent {
  const GameContent({
    required this.items,
    required this.goals,
    required this.quests,
    required this.lessons,
    required this.bodies,
    required this.colors,
    required this.accessories,
  });

  final List<ShopItem> items;
  final List<SavingsGoal> goals;
  final List<Quest> quests;
  final List<LearningLesson> lessons;
  final List<String> bodies;
  final List<String> colors;
  final List<String> accessories;

  int get petCombinations =>
      bodies.length * colors.length * accessories.length;
}

class ContentLoader {
  static Future<GameContent> load() async {
    final itemsRaw =
        await rootBundle.loadString('assets/content/items.json');
    final goalsRaw =
        await rootBundle.loadString('assets/content/goals.json');
    final questsRaw =
        await rootBundle.loadString('assets/content/quests.json');
    final lessonsRaw =
        await rootBundle.loadString('assets/content/lessons.json');
    final petsRaw = await rootBundle.loadString('assets/content/pets.json');

    final items = (jsonDecode(itemsRaw) as List)
        .map((e) => ShopItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final goals = (jsonDecode(goalsRaw) as List)
        .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
        .toList();
    final quests = (jsonDecode(questsRaw) as List)
        .map((e) => Quest.fromJson(e as Map<String, dynamic>))
        .toList();
    final lessons = (jsonDecode(lessonsRaw) as List)
        .map((e) => LearningLesson.fromJson(e as Map<String, dynamic>))
        .toList();
    final pets = jsonDecode(petsRaw) as Map<String, dynamic>;

    return GameContent(
      items: items,
      goals: goals,
      quests: quests,
      lessons: lessons,
      bodies: (pets['bodies'] as List).cast<String>(),
      colors: (pets['colors'] as List).cast<String>(),
      accessories: (pets['accessories'] as List).cast<String>(),
    );
  }
}
