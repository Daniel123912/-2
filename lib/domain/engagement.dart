import 'models.dart';

/// Сюжетная «эпоха» игрового периода (вместо «период 3»).
class PeriodStory {
  const PeriodStory({
    required this.title,
    required this.hook,
    required this.mission,
  });

  final String title;
  final String hook;
  final String mission;
}

enum CosmeticSlot { head, held, room }

class CosmeticVisual {
  const CosmeticVisual({
    required this.emoji,
    required this.slot,
  });

  final String emoji;
  final CosmeticSlot slot;
}

class ItemCollection {
  const ItemCollection({
    required this.id,
    required this.name,
    required this.emoji,
    required this.itemIds,
  });

  final String id;
  final String name;
  final String emoji;
  final List<String> itemIds;

  int ownedCount(Iterable<String> owned) =>
      itemIds.where(owned.toSet().contains).length;

  bool isComplete(Iterable<String> owned) =>
      ownedCount(owned) >= itemIds.length;

  double progress(Iterable<String> owned) {
    if (itemIds.isEmpty) return 0;
    return (ownedCount(owned) / itemIds.length).clamp(0.0, 1.0);
  }
}

/// Контент вовлечения: эпохи, коллекции, косметика, реакции питомца.
class Engagement {
  static const periodStories = <PeriodStory>[
    PeriodStory(
      title: 'Неделя заботы',
      hook: 'Финни хочет вкусно поесть и чуть-чуть отложить.',
      mission: 'Закрой нужное и положи монеты в копилку.',
    ),
    PeriodStory(
      title: 'Неделя в магазине',
      hook: 'Витрина блестит — но сначала план!',
      mission: 'Составь бюджет и не купи всё подряд.',
    ),
    PeriodStory(
      title: 'Неделя копилки',
      hook: 'Мечта близко — каждый вклад важен.',
      mission: 'Пополни копилку по плану периода.',
    ),
    PeriodStory(
      title: 'Неделя подарков',
      hook: 'Поделиться тоже финансовое решение.',
      mission: 'Оставь немного на подарок другу.',
    ),
    PeriodStory(
      title: 'Неделя чемпиона',
      hook: 'Задания и план — путь к новой стадии!',
      mission: 'Выполни квесты и закрой обязательное.',
    ),
    PeriodStory(
      title: 'Неделя сюрпризов',
      hook: 'Сегодня может случиться секрет дня.',
      mission: 'Собери коллекцию и удиви Финни.',
    ),
  ];

  static const collections = <ItemCollection>[
    ItemCollection(
      id: 'care',
      name: 'Забота',
      emoji: '💚',
      itemIds: ['food_bowl', 'water', 'grooming', 'vet_check'],
    ),
    ItemCollection(
      id: 'style',
      name: 'Стиль',
      emoji: '✨',
      itemIds: ['hat', 'poster', 'toy_ball'],
    ),
    ItemCollection(
      id: 'kindness',
      name: 'Доброта',
      emoji: '🎁',
      itemIds: ['snack', 'gift_friend', 'gift_charity'],
    ),
  ];

  static const cosmetics = <String, CosmeticVisual>{
    'hat': CosmeticVisual(emoji: '🎩', slot: CosmeticSlot.head),
    'toy_ball': CosmeticVisual(emoji: '⚽', slot: CosmeticSlot.held),
    'poster': CosmeticVisual(emoji: '🖼️', slot: CosmeticSlot.room),
    'snack': CosmeticVisual(emoji: '🍪', slot: CosmeticSlot.held),
    'grooming': CosmeticVisual(emoji: '🪥', slot: CosmeticSlot.held),
    'gift_friend': CosmeticVisual(emoji: '🎀', slot: CosmeticSlot.room),
  };

  static PeriodStory storyForPeriod(int index) {
    final i = index < 1 ? 0 : (index - 1) % periodStories.length;
    return periodStories[i];
  }

  static bool isCosmetic(String itemId) => cosmetics.containsKey(itemId);

  static List<CosmeticVisual> visualsFor(Iterable<String> ownedIds) {
    final bySlot = <CosmeticSlot, CosmeticVisual>{};
    for (final id in ownedIds) {
      final visual = cosmetics[id];
      if (visual != null) bySlot[visual.slot] = visual;
    }
    return bySlot.values.toList();
  }

  static String petTapSpeech({
    required String petName,
    required int hunger,
    required int mood,
  }) {
    if (hunger < 35) {
      const lines = [
        'Я голодный… давай купим еду?',
        'Миска пустая. Сначала нужное!',
        'Животик урчит. Покорми меня?',
      ];
      return lines[DateTime.now().second % lines.length];
    }
    if (mood < 40) {
      const lines = [
        'Мне грустновато… может, игрушку?',
        'Обнимем? Потом продолжим копить.',
        'Давай сделаем что-то весёлое!',
      ];
      return lines[DateTime.now().second % lines.length];
    }
    if (mood >= 80) {
      const lines = [
        'Ура! Ты супер!',
        'Мне так весело с тобой!',
        'Ты мой чемпион!',
        'Давай ещё чуть-чуть в копилку!',
      ];
      return lines[DateTime.now().second % lines.length]
          .replaceFirst('Ты', petName.isEmpty ? 'Ты' : 'Эй');
    }
    const lines = [
      'Привет! Давай играть!',
      'Нажми ещё — мне нравится!',
      'Сначала нужное — потом игрушки!',
      'Мы крутая команда!',
      'Секрет дня ждёт тебя!',
    ];
    return lines[DateTime.now().millisecond % lines.length];
  }

  /// Награда «секрета дня» по календарному ключу YYYY-MM-DD.
  static SecretReward secretForDay(String dayKey) {
    final hash = dayKey.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return switch (hash % 4) {
      0 => const SecretReward(
          title: 'Монетный сюрприз',
          message: 'Финни нашёл блестящую монетку под подушкой!',
          coins: 8,
          mood: 4,
          stars: 0,
        ),
      1 => const SecretReward(
          title: 'Обнимашки',
          message: 'Секрет дня: Финни дарит тебе огромные обнимашки!',
          coins: 3,
          mood: 12,
          stars: 1,
        ),
      2 => const SecretReward(
          title: 'Звёздочка удачи',
          message: 'Сегодня тебе светит ★ удачи — лови!',
          coins: 5,
          mood: 6,
          stars: 2,
        ),
      _ => const SecretReward(
          title: 'Тихий клад',
          message: 'Ш-ш-ш… Финни шепчет: «Отложи ещё чуть-чуть!»',
          coins: 6,
          mood: 8,
          stars: 1,
        ),
    };
  }

  static String softFailHint({
    required bool mandatoryOk,
    required bool savedOk,
    required bool planClose,
  }) {
    if (!mandatoryOk) {
      return 'Как поправить: в следующем периоде сначала купи еду и уход — Финни сразу оживится.';
    }
    if (!savedOk) {
      return 'Как поправить: отложи хотя бы немного в копилку — даже 5 монет считаются!';
    }
    if (!planClose) {
      return 'Как поправить: смотри на план перед покупкой — так факт будет ближе.';
    }
    return 'Всё поправимо. Финни верит в тебя — попробуем ещё раз вместе!';
  }
}

class SecretReward {
  const SecretReward({
    required this.title,
    required this.message,
    required this.coins,
    required this.mood,
    required this.stars,
  });

  final String title;
  final String message;
  final int coins;
  final int mood;
  final int stars;
}
