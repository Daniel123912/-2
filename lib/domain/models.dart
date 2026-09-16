enum ExpenseKind { mandatory, optional }

enum QuestTheme { budget, savings, purchases }

enum PeriodPhase { planning, playing, summary }

/// Возрастной трек обучения (ТЗ: 7–11 лет).
enum AgeTrack {
  junior, // 7–8
  middle, // 9–10
  senior, // 11
}

enum QuestDifficulty { easy, medium, hard }

extension AgeTrackX on AgeTrack {
  String get label => switch (this) {
        AgeTrack.junior => '7–8 лет',
        AgeTrack.middle => '9–10 лет',
        AgeTrack.senior => '11 лет',
      };

  String get shortLabel => switch (this) {
        AgeTrack.junior => 'Лёгкий',
        AgeTrack.middle => 'Средний',
        AgeTrack.senior => 'Сложный',
      };

  String get description => switch (this) {
        AgeTrack.junior => 'Простые выборы: нужное и желаемое.',
        AgeTrack.middle => 'План, копилка и сравнение цен.',
        AgeTrack.senior => 'Приоритеты, компромиссы и контроль плана.',
      };

  /// Какие сложности заданий доступны на треке.
  Set<QuestDifficulty> get allowedDifficulties => switch (this) {
        AgeTrack.junior => {QuestDifficulty.easy},
        AgeTrack.middle => {QuestDifficulty.easy, QuestDifficulty.medium},
        AgeTrack.senior => {
            QuestDifficulty.easy,
            QuestDifficulty.medium,
            QuestDifficulty.hard,
          },
      };

  int get startingBalance => switch (this) {
        AgeTrack.junior => 100,
        AgeTrack.middle => 110,
        AgeTrack.senior => 120,
      };
}

extension QuestDifficultyX on QuestDifficulty {
  String get label => switch (this) {
        QuestDifficulty.easy => 'Лёгкое',
        QuestDifficulty.medium => 'Среднее',
        QuestDifficulty.hard => 'Сложное',
      };

  int get starReward => switch (this) {
        QuestDifficulty.easy => 1,
        QuestDifficulty.medium => 2,
        QuestDifficulty.hard => 3,
      };

  int get xpReward => switch (this) {
        QuestDifficulty.easy => 10,
        QuestDifficulty.medium => 18,
        QuestDifficulty.hard => 28,
      };
}

class SkillProgress {
  const SkillProgress({
    this.budgetXp = 0,
    this.savingsXp = 0,
    this.purchasesXp = 0,
  });

  final int budgetXp;
  final int savingsXp;
  final int purchasesXp;

  int xpFor(QuestTheme theme) => switch (theme) {
        QuestTheme.budget => budgetXp,
        QuestTheme.savings => savingsXp,
        QuestTheme.purchases => purchasesXp,
      };

  int levelFor(QuestTheme theme) => (xpFor(theme) / 40).floor() + 1;

  int get totalXp => budgetXp + savingsXp + purchasesXp;

  SkillProgress add(QuestTheme theme, int xp) {
    return switch (theme) {
      QuestTheme.budget => copyWith(budgetXp: budgetXp + xp),
      QuestTheme.savings => copyWith(savingsXp: savingsXp + xp),
      QuestTheme.purchases => copyWith(purchasesXp: purchasesXp + xp),
    };
  }

  SkillProgress copyWith({int? budgetXp, int? savingsXp, int? purchasesXp}) {
    return SkillProgress(
      budgetXp: budgetXp ?? this.budgetXp,
      savingsXp: savingsXp ?? this.savingsXp,
      purchasesXp: purchasesXp ?? this.purchasesXp,
    );
  }

  Map<String, dynamic> toJson() => {
        'budgetXp': budgetXp,
        'savingsXp': savingsXp,
        'purchasesXp': purchasesXp,
      };

  factory SkillProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SkillProgress();
    return SkillProgress(
      budgetXp: json['budgetXp'] as int? ?? 0,
      savingsXp: json['savingsXp'] as int? ?? 0,
      purchasesXp: json['purchasesXp'] as int? ?? 0,
    );
  }
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.kind,
    required this.effectHint,
    required this.hungerDelta,
    required this.moodDelta,
  });

  final String id;
  final String name;
  final int price;
  final ExpenseKind kind;
  final String effectHint;
  final int hungerDelta;
  final int moodDelta;

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      kind: (json['kind'] as String) == 'mandatory'
          ? ExpenseKind.mandatory
          : ExpenseKind.optional,
      effectHint: json['effectHint'] as String,
      hungerDelta: json['hungerDelta'] as int? ?? 0,
      moodDelta: json['moodDelta'] as int? ?? 0,
    );
  }
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
  });

  final String id;
  final String name;
  final int cost;
  final String description;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      cost: json['cost'] as int,
      description: json['description'] as String,
    );
  }
}

class QuestOption {
  const QuestOption({
    required this.id,
    required this.label,
    required this.isGood,
    required this.reward,
    required this.explanation,
  });

  final String id;
  final String label;
  final bool isGood;
  final int reward;
  final String explanation;

  factory QuestOption.fromJson(Map<String, dynamic> json) {
    return QuestOption(
      id: json['id'] as String,
      label: json['label'] as String,
      isGood: json['isGood'] as bool,
      reward: json['reward'] as int,
      explanation: json['explanation'] as String,
    );
  }
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.prompt,
    required this.theme,
    required this.options,
    this.difficulty = QuestDifficulty.easy,
    this.tip = '',
    this.ageTracks = const {
      AgeTrack.junior,
      AgeTrack.middle,
      AgeTrack.senior,
    },
  });

  final String id;
  final String title;
  final String prompt;
  final QuestTheme theme;
  final List<QuestOption> options;
  final QuestDifficulty difficulty;
  final String tip;
  final Set<AgeTrack> ageTracks;

  bool availableFor(AgeTrack track) => ageTracks.contains(track);

  factory Quest.fromJson(Map<String, dynamic> json) {
    final themeRaw = json['theme'] as String;
    final theme = switch (themeRaw) {
      'budget' => QuestTheme.budget,
      'savings' => QuestTheme.savings,
      _ => QuestTheme.purchases,
    };
    final diffRaw = json['difficulty'] as String? ?? 'easy';
    final difficulty = switch (diffRaw) {
      'medium' => QuestDifficulty.medium,
      'hard' => QuestDifficulty.hard,
      _ => QuestDifficulty.easy,
    };
    final tracksRaw = (json['ageTracks'] as List?)?.cast<String>();
    final ageTracks = tracksRaw == null
        ? {AgeTrack.junior, AgeTrack.middle, AgeTrack.senior}
        : tracksRaw.map(_parseAgeTrack).toSet();

    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      prompt: json['prompt'] as String,
      theme: theme,
      difficulty: difficulty,
      tip: json['tip'] as String? ?? '',
      ageTracks: ageTracks,
      options: (json['options'] as List)
          .map((e) => QuestOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static AgeTrack _parseAgeTrack(String raw) => switch (raw) {
        'middle' => AgeTrack.middle,
        'senior' => AgeTrack.senior,
        _ => AgeTrack.junior,
      };
}

class PetAppearance {
  const PetAppearance({
    required this.body,
    required this.color,
    required this.accessory,
  });

  final String body;
  final String color;
  final String accessory;

  Map<String, dynamic> toJson() => {
        'body': body,
        'color': color,
        'accessory': accessory,
      };

  factory PetAppearance.fromJson(Map<String, dynamic> json) {
    return PetAppearance(
      body: json['body'] as String,
      color: json['color'] as String,
      accessory: json['accessory'] as String,
    );
  }

  String get label => '$body · $color · $accessory';
}

class BudgetPlan {
  const BudgetPlan({
    required this.mandatory,
    required this.optional,
    required this.savings,
  });

  final int mandatory;
  final int optional;
  final int savings;

  int get total => mandatory + optional + savings;

  BudgetPlan copyWith({int? mandatory, int? optional, int? savings}) {
    return BudgetPlan(
      mandatory: mandatory ?? this.mandatory,
      optional: optional ?? this.optional,
      savings: savings ?? this.savings,
    );
  }

  Map<String, dynamic> toJson() => {
        'mandatory': mandatory,
        'optional': optional,
        'savings': savings,
      };

  factory BudgetPlan.fromJson(Map<String, dynamic> json) {
    return BudgetPlan(
      mandatory: json['mandatory'] as int,
      optional: json['optional'] as int,
      savings: json['savings'] as int,
    );
  }

  static const empty = BudgetPlan(mandatory: 0, optional: 0, savings: 0);
}

class BudgetFact {
  const BudgetFact({
    this.mandatorySpent = 0,
    this.optionalSpent = 0,
    this.saved = 0,
  });

  final int mandatorySpent;
  final int optionalSpent;
  final int saved;

  BudgetFact copyWith({
    int? mandatorySpent,
    int? optionalSpent,
    int? saved,
  }) {
    return BudgetFact(
      mandatorySpent: mandatorySpent ?? this.mandatorySpent,
      optionalSpent: optionalSpent ?? this.optionalSpent,
      saved: saved ?? this.saved,
    );
  }

  Map<String, dynamic> toJson() => {
        'mandatorySpent': mandatorySpent,
        'optionalSpent': optionalSpent,
        'saved': saved,
      };

  factory BudgetFact.fromJson(Map<String, dynamic> json) {
    return BudgetFact(
      mandatorySpent: json['mandatorySpent'] as int? ?? 0,
      optionalSpent: json['optionalSpent'] as int? ?? 0,
      saved: json['saved'] as int? ?? 0,
    );
  }
}

class PurchaseRecord {
  const PurchaseRecord({
    required this.itemId,
    required this.name,
    required this.price,
    required this.kind,
  });

  final String itemId;
  final String name;
  final int price;
  final ExpenseKind kind;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'price': price,
        'kind': kind == ExpenseKind.mandatory ? 'mandatory' : 'optional',
      };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      kind: (json['kind'] as String) == 'mandatory'
          ? ExpenseKind.mandatory
          : ExpenseKind.optional,
    );
  }
}

class GamePeriod {
  const GamePeriod({
    required this.index,
    required this.startingBalance,
    required this.phase,
    this.plan = BudgetPlan.empty,
    this.fact = const BudgetFact(),
    this.purchases = const [],
    this.activeQuestIds = const [],
    this.completedQuestIds = const [],
    this.feedback = '',
    this.goodQuestStreak = 0,
  });

  final int index;
  final int startingBalance;
  final PeriodPhase phase;
  final BudgetPlan plan;
  final BudgetFact fact;
  final List<PurchaseRecord> purchases;
  /// Задания, выданные на этот период (по 1+ на тему).
  final List<String> activeQuestIds;
  final List<String> completedQuestIds;
  final String feedback;
  final int goodQuestStreak;

  int get periodQuestsDone =>
      completedQuestIds.where(activeQuestIds.contains).length;

  bool get periodQuestsComplete =>
      activeQuestIds.isNotEmpty &&
      activeQuestIds.every(completedQuestIds.contains);

  GamePeriod copyWith({
    int? index,
    int? startingBalance,
    PeriodPhase? phase,
    BudgetPlan? plan,
    BudgetFact? fact,
    List<PurchaseRecord>? purchases,
    List<String>? activeQuestIds,
    List<String>? completedQuestIds,
    String? feedback,
    int? goodQuestStreak,
  }) {
    return GamePeriod(
      index: index ?? this.index,
      startingBalance: startingBalance ?? this.startingBalance,
      phase: phase ?? this.phase,
      plan: plan ?? this.plan,
      fact: fact ?? this.fact,
      purchases: purchases ?? this.purchases,
      activeQuestIds: activeQuestIds ?? this.activeQuestIds,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      feedback: feedback ?? this.feedback,
      goodQuestStreak: goodQuestStreak ?? this.goodQuestStreak,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'startingBalance': startingBalance,
        'phase': phase.name,
        'plan': plan.toJson(),
        'fact': fact.toJson(),
        'purchases': purchases.map((e) => e.toJson()).toList(),
        'activeQuestIds': activeQuestIds,
        'completedQuestIds': completedQuestIds,
        'feedback': feedback,
        'goodQuestStreak': goodQuestStreak,
      };

  factory GamePeriod.fromJson(Map<String, dynamic> json) {
    return GamePeriod(
      index: json['index'] as int,
      startingBalance: json['startingBalance'] as int,
      phase: PeriodPhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => PeriodPhase.planning,
      ),
      plan: BudgetPlan.fromJson(json['plan'] as Map<String, dynamic>),
      fact: BudgetFact.fromJson(json['fact'] as Map<String, dynamic>),
      purchases: (json['purchases'] as List? ?? [])
          .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeQuestIds: (json['activeQuestIds'] as List? ?? []).cast<String>(),
      completedQuestIds:
          (json['completedQuestIds'] as List? ?? []).cast<String>(),
      feedback: json['feedback'] as String? ?? '',
      goodQuestStreak: json['goodQuestStreak'] as int? ?? 0,
    );
  }
}

/// Подсказка «что делать дальше» на главном экране.
enum NextActionKind {
  planBudget,
  doQuests,
  buyMandatory,
  saveMoney,
  claimGoal,
  finishPeriod,
  viewSummary,
}

class NextAction {
  const NextAction({
    required this.kind,
    required this.title,
    required this.subtitle,
  });

  final NextActionKind kind;
  final String title;
  final String subtitle;
}

class PlayerProfile {
  const PlayerProfile({
    required this.playerName,
    required this.petName,
    required this.appearance,
    required this.balance,
    required this.savingsBalance,
    required this.hunger,
    required this.mood,
    required this.growthStage,
    required this.goodPeriodStreak,
    required this.selectedGoalId,
    required this.demoMode,
    required this.onboardingDone,
    required this.period,
    required this.completedQuestIds,
    required this.lastFeedback,
    this.totalPeriodsCompleted = 0,
    this.ageTrack = AgeTrack.middle,
    this.skills = const SkillProgress(),
    this.stars = 0,
    this.comboBest = 0,
  });

  final String playerName;
  final String petName;
  final PetAppearance appearance;
  final int balance;
  final int savingsBalance;
  final int hunger;
  final int mood;
  final int growthStage;
  final int goodPeriodStreak;
  final String? selectedGoalId;
  final bool demoMode;
  final bool onboardingDone;
  final GamePeriod period;
  final List<String> completedQuestIds;
  final String lastFeedback;
  final int totalPeriodsCompleted;
  final AgeTrack ageTrack;
  final SkillProgress skills;
  final int stars;
  final int comboBest;

  PlayerProfile copyWith({
    String? playerName,
    String? petName,
    PetAppearance? appearance,
    int? balance,
    int? savingsBalance,
    int? hunger,
    int? mood,
    int? growthStage,
    int? goodPeriodStreak,
    Object? selectedGoalId = _sentinel,
    bool? demoMode,
    bool? onboardingDone,
    GamePeriod? period,
    List<String>? completedQuestIds,
    String? lastFeedback,
    int? totalPeriodsCompleted,
    AgeTrack? ageTrack,
    SkillProgress? skills,
    int? stars,
    int? comboBest,
  }) {
    return PlayerProfile(
      playerName: playerName ?? this.playerName,
      petName: petName ?? this.petName,
      appearance: appearance ?? this.appearance,
      balance: balance ?? this.balance,
      savingsBalance: savingsBalance ?? this.savingsBalance,
      hunger: hunger ?? this.hunger,
      mood: mood ?? this.mood,
      growthStage: growthStage ?? this.growthStage,
      goodPeriodStreak: goodPeriodStreak ?? this.goodPeriodStreak,
      selectedGoalId: identical(selectedGoalId, _sentinel)
          ? this.selectedGoalId
          : selectedGoalId as String?,
      demoMode: demoMode ?? this.demoMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      period: period ?? this.period,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      totalPeriodsCompleted:
          totalPeriodsCompleted ?? this.totalPeriodsCompleted,
      ageTrack: ageTrack ?? this.ageTrack,
      skills: skills ?? this.skills,
      stars: stars ?? this.stars,
      comboBest: comboBest ?? this.comboBest,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'petName': petName,
        'appearance': appearance.toJson(),
        'balance': balance,
        'savingsBalance': savingsBalance,
        'hunger': hunger,
        'mood': mood,
        'growthStage': growthStage,
        'goodPeriodStreak': goodPeriodStreak,
        'selectedGoalId': selectedGoalId,
        'demoMode': demoMode,
        'onboardingDone': onboardingDone,
        'period': period.toJson(),
        'completedQuestIds': completedQuestIds,
        'lastFeedback': lastFeedback,
        'totalPeriodsCompleted': totalPeriodsCompleted,
        'ageTrack': ageTrack.name,
        'skills': skills.toJson(),
        'stars': stars,
        'comboBest': comboBest,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final trackRaw = json['ageTrack'] as String? ?? 'middle';
    final ageTrack = switch (trackRaw) {
      'junior' => AgeTrack.junior,
      'senior' => AgeTrack.senior,
      _ => AgeTrack.middle,
    };
    return PlayerProfile(
      playerName: json['playerName'] as String,
      petName: json['petName'] as String,
      appearance:
          PetAppearance.fromJson(json['appearance'] as Map<String, dynamic>),
      balance: json['balance'] as int,
      savingsBalance: json['savingsBalance'] as int,
      hunger: json['hunger'] as int,
      mood: json['mood'] as int,
      growthStage: json['growthStage'] as int,
      goodPeriodStreak: json['goodPeriodStreak'] as int,
      selectedGoalId: json['selectedGoalId'] as String?,
      demoMode: json['demoMode'] as bool? ?? true,
      onboardingDone: json['onboardingDone'] as bool? ?? false,
      period: GamePeriod.fromJson(json['period'] as Map<String, dynamic>),
      completedQuestIds:
          (json['completedQuestIds'] as List? ?? []).cast<String>(),
      lastFeedback: json['lastFeedback'] as String? ?? '',
      totalPeriodsCompleted: json['totalPeriodsCompleted'] as int? ?? 0,
      ageTrack: ageTrack,
      skills: SkillProgress.fromJson(json['skills'] as Map<String, dynamic>?),
      stars: json['stars'] as int? ?? 0,
      comboBest: json['comboBest'] as int? ?? 0,
    );
  }

  static PlayerProfile fresh({
    required String playerName,
    required String petName,
    required PetAppearance appearance,
    AgeTrack ageTrack = AgeTrack.middle,
    int? startingBalance,
  }) {
    final balance = startingBalance ?? ageTrack.startingBalance;
    return PlayerProfile(
      playerName: playerName,
      petName: petName,
      appearance: appearance,
      balance: balance,
      savingsBalance: 0,
      hunger: 70,
      mood: 70,
      growthStage: 1,
      goodPeriodStreak: 0,
      selectedGoalId: null,
      demoMode: true,
      onboardingDone: true,
      ageTrack: ageTrack,
      skills: const SkillProgress(),
      stars: 0,
      comboBest: 0,
      period: GamePeriod(
        index: 1,
        startingBalance: balance,
        phase: PeriodPhase.planning,
      ),
      completedQuestIds: const [],
      lastFeedback:
          'Добро пожаловать! Трек: ${ageTrack.label}. Сначала составь план бюджета.',
    );
  }
}

const Object _sentinel = Object();

class EconomyResult {
  const EconomyResult({
    required this.profile,
    required this.message,
    this.ok = true,
    this.earnedStars = 0,
    this.earnedXp = 0,
    this.combo = 0,
  });

  final PlayerProfile profile;
  final String message;
  final bool ok;
  final int earnedStars;
  final int earnedXp;
  final int combo;
}
