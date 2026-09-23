import 'engagement.dart';
import 'models.dart';

/// Pure game-economy rules. Covered by unit tests.
///
/// Документ с формулами: `docs/economy_rules.md`.
class GameEconomy {
  static const int periodIncome = 40;
  static const int maxStat = 100;
  static const int minStat = 0;
  /// Мягкий пол сытости — питомец не «умирает» от голода в демо.
  static const int softHungerFloor = 10;
  static const int stages = 3;
  static const int goodPeriodsPerStage = 2;

  /// Базовый допуск «факт близок к плану» (суммарно по корзинам).
  static const int planFactTolerance = 15;

  /// Доля обязательных расходов от плана, достаточная для «закрытия нужд».
  static const double mandatoryCoverageRatio = 0.7;

  /// Максимальный бонус комбо в монетах для junior.
  static const int juniorComboBonusCap = 4;

  /// Максимальный бонус навыка (монеты) за уровень темы.
  static const int maxSkillCoinBonus = 5;

  /// Бонус за ежедневный вход (пропуск дня не штрафует).
  static const int loginBonusCoins = 5;

  /// Сколько монет родитель может выдать за одно нажатие.
  static const int parentGrantAmount = 20;

  /// Потолок родительских монет на профиль.
  static const int parentGrantCap = 100;

  /// Пауза между периодами вне демо-режима.
  static const Duration normalPeriodCooldown = Duration(hours: 1);

  static String stageTitle(int stage) => switch (stage.clamp(1, stages)) {
        1 => 'Малыш',
        2 => 'Растущий',
        _ => 'Чемпион',
      };

  /// Подсказка роста: сколько хороших периодов до следующей стадии.
  static String stageProgressHint(PlayerProfile profile) =>
      stageProgressHintFor(
        growthStage: profile.growthStage,
        goodPeriodStreak: profile.goodPeriodStreak,
      );

  static String stageProgressHintFor({
    required int growthStage,
    required int goodPeriodStreak,
  }) {
    if (growthStage >= stages) {
      return 'Максимальная стадия «${stageTitle(stages)}»!';
    }
    final left = goodPeriodsPerStage - goodPeriodStreak;
    final next = growthStage + 1;
    if (left <= 0) {
      return 'Следующий хороший период → стадия $next «${stageTitle(next)}».';
    }
    final word = left == 1 ? 'период' : 'периода';
    return 'Ещё $left хороших $word → стадия $next «${stageTitle(next)}».';
  }

  static String calendarDayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static bool canAdvancePeriod(PlayerProfile profile, {DateTime? now}) {
    if (profile.demoMode) return true;
    final raw = profile.nextPeriodAvailableAt;
    if (raw == null || raw.isEmpty) return true;
    final unlock = DateTime.tryParse(raw);
    if (unlock == null) return true;
    return !(now ?? DateTime.now()).isBefore(unlock);
  }

  static Duration? periodCooldownLeft(PlayerProfile profile, {DateTime? now}) {
    if (canAdvancePeriod(profile, now: now)) return null;
    final unlock = DateTime.tryParse(profile.nextPeriodAvailableAt ?? '');
    if (unlock == null) return null;
    return unlock.difference(now ?? DateTime.now());
  }

  static int clampStat(int value) =>
      value.clamp(minStat, maxStat).toInt();

  /// Сытость с мягким полом (штрафы не роняют ниже [softHungerFloor]).
  static int clampHunger(int value) =>
      value.clamp(softHungerFloor, maxStat).toInt();

  /// Баланс никогда не уходит в минус.
  static int clampBalance(int value) => value < 0 ? 0 : value;

  static bool canAfford(PlayerProfile profile, int price) =>
      price >= 0 && profile.balance >= price;

  /// Периодический доход (начисление валюты в начале периода).
  static int incomeForTrack(AgeTrack track) => switch (track) {
        AgeTrack.junior => periodIncome + 5,
        AgeTrack.middle => periodIncome,
        AgeTrack.senior => periodIncome + 5,
      };

  /// Стартовый баланс нового профиля по треку возраста.
  static int startingBalanceFor(AgeTrack track) => track.startingBalance;

  /// Допуск план/факт: не меньше 15 и не меньше ~15% от суммы плана.
  static int planFactToleranceFor(BudgetPlan plan) {
    final relative = (plan.total * 0.15).round();
    return relative > planFactTolerance ? relative : planFactTolerance;
  }

  /// План vs факт: дельты и флаги исхода периода.
  static PlanFactReport comparePlanFact(BudgetPlan plan, BudgetFact fact) {
    final mandatoryNeed =
        (plan.mandatory * mandatoryCoverageRatio).round();
    final mandatoryOk =
        fact.mandatorySpent >= mandatoryNeed && fact.mandatorySpent > 0;
    final totalFact = fact.spentTotal;
    final totalDelta = totalFact - plan.total;
    final planClose = totalDelta.abs() <= planFactToleranceFor(plan);
    final savedOk = fact.saved > 0;
    final wasGoodPeriod = mandatoryOk && (savedOk || planClose);
    return PlanFactReport(
      mandatoryDelta: fact.mandatorySpent - plan.mandatory,
      optionalDelta: fact.optionalSpent - plan.optional,
      savingsDelta: fact.saved - plan.savings,
      giftDelta: fact.giftSpent - plan.gift,
      totalDelta: totalDelta,
      mandatoryOk: mandatoryOk,
      planClose: planClose,
      savedOk: savedOk,
      wasGoodPeriod: wasGoodPeriod,
    );
  }

  /// Цели накопления, доступные на треке возраста.
  static List<SavingsGoal> goalsForProfile(
    PlayerProfile profile,
    List<SavingsGoal> all,
  ) {
    return all.where((g) => g.availableFor(profile.ageTrack)).toList();
  }

  /// Задания, доступные игроку по возрасту (и опционально по сложности).
  static List<Quest> questsForProfile(
    PlayerProfile profile,
    List<Quest> all, {
    QuestDifficulty? onlyDifficulty,
    QuestTheme? onlyTheme,
  }) {
    return all.where((q) {
      if (!q.availableFor(profile.ageTrack)) return false;
      if (!profile.ageTrack.allowedDifficulties.contains(q.difficulty)) {
        return false;
      }
      if (onlyDifficulty != null && q.difficulty != onlyDifficulty) {
        return false;
      }
      if (onlyTheme != null && q.theme != onlyTheme) return false;
      return true;
    }).toList();
  }

  /// Набор заданий периода: по одному на тему + доп. для старшего трека.
  static List<String> pickPeriodQuests(
    PlayerProfile profile,
    List<Quest> all,
  ) {
    final available = questsForProfile(profile, all);
    if (available.isEmpty) return const [];

    final picked = <String>[];
    final periodOffset = (profile.period.index - 1).clamp(0, 999);

    for (final theme in QuestTheme.values) {
      final themed = available.where((q) => q.theme == theme).toList();
      if (themed.isEmpty) continue;

      themed.sort((a, b) {
        final aDone = profile.completedQuestIds.contains(a.id) ? 1 : 0;
        final bDone = profile.completedQuestIds.contains(b.id) ? 1 : 0;
        if (aDone != bDone) return aDone.compareTo(bDone);
        return a.id.compareTo(b.id);
      });

      final fresh =
          themed.where((q) => !profile.completedQuestIds.contains(q.id)).toList();
      final pool = fresh.isNotEmpty ? fresh : themed;
      picked.add(pool[periodOffset % pool.length].id);
    }

    if (profile.ageTrack == AgeTrack.senior) {
      final hardExtra = available
          .where(
            (q) =>
                q.difficulty == QuestDifficulty.hard && !picked.contains(q.id),
          )
          .toList();
      if (hardExtra.isNotEmpty) {
        picked.add(hardExtra[periodOffset % hardExtra.length].id);
      }
    } else if (profile.ageTrack == AgeTrack.middle) {
      final mediumExtra = available
          .where(
            (q) =>
                q.difficulty == QuestDifficulty.medium &&
                !picked.contains(q.id),
          )
          .toList();
      if (mediumExtra.isNotEmpty) {
        picked.add(mediumExtra[periodOffset % mediumExtra.length].id);
      }
    } else if (profile.ageTrack == AgeTrack.junior) {
      // Ещё одно лёгкое задание периода — больше практики без смены сложности.
      final easyExtra = available
          .where(
            (q) =>
                q.difficulty == QuestDifficulty.easy && !picked.contains(q.id),
          )
          .toList();
      if (easyExtra.isNotEmpty) {
        picked.add(easyExtra[(periodOffset + 1) % easyExtra.length].id);
      }
    }

    return picked;
  }

  static BudgetPlan recommendedPlan(PlayerProfile profile) {
    final bal = profile.balance;
    // mandatory, optional, savings, gift
    final ratios = switch (profile.ageTrack) {
      AgeTrack.junior => (0.45, 0.20, 0.25, 0.10),
      AgeTrack.middle => (0.40, 0.25, 0.25, 0.10),
      AgeTrack.senior => (0.35, 0.25, 0.30, 0.10),
    };
    var mandatory = (bal * ratios.$1).round();
    var optional = (bal * ratios.$2).round();
    var savings = (bal * ratios.$3).round();
    var gift = (bal * ratios.$4).round();
    final drift = bal - (mandatory + optional + savings + gift);
    savings += drift;
    if (savings < 0) {
      gift = (gift + savings).clamp(0, bal);
      savings = 0;
      final still = bal - (mandatory + optional + savings + gift);
      if (still < 0) {
        optional = (optional + still).clamp(0, bal);
      }
    }
    // Обязательная корзина не должна быть нулевой при ненулевом балансе.
    if (bal > 0 && mandatory <= 0) {
      mandatory = 1;
      if (optional > 0) {
        optional -= 1;
      } else if (gift > 0) {
        gift -= 1;
      } else if (savings > 0) {
        savings -= 1;
      }
    }
    return BudgetPlan(
      mandatory: mandatory,
      optional: optional.clamp(0, bal),
      savings: savings.clamp(0, bal),
      gift: gift.clamp(0, bal),
    );
  }

  static NextAction nextAction(
    PlayerProfile profile, {
    SavingsGoal? goal,
  }) {
    final story = Engagement.storyForPeriod(profile.period.index);

    if (goal != null &&
        profile.selectedGoalId == goal.id &&
        profile.savingsBalance >= goal.cost) {
      return NextAction(
        kind: NextActionKind.claimGoal,
        title: '🎉 Забери цель!',
        subtitle: 'В копилке хватает на «${goal.name}».',
      );
    }

    final challenge = profile.parentChallengeTarget;
    if (challenge != null &&
        profile.parentChallengeSaved < challenge &&
        profile.period.phase == PeriodPhase.playing &&
        profile.balance >= 5) {
      final left = challenge - profile.parentChallengeSaved;
      return NextAction(
        kind: NextActionKind.saveMoney,
        title: 'Миссия от мамы/папы!',
        subtitle: 'Ещё $left монет в копилку — и победа.',
      );
    }

    switch (profile.period.phase) {
      case PeriodPhase.planning:
        return NextAction(
          kind: NextActionKind.planBudget,
          title: '📋 ${story.title}: составь план',
          subtitle: story.mission,
        );
      case PeriodPhase.summary:
        return NextAction(
          kind: NextActionKind.viewSummary,
          title: 'Итог: ${story.title}',
          subtitle: 'Сравни план и факт, затем начни новую неделю.',
        );
      case PeriodPhase.playing:
        final active = profile.period.activeQuestIds;
        final done = profile.period.completedQuestIds.toSet();
        final openQuests = active.where((id) => !done.contains(id)).length;
        if (openQuests > 0) {
          return NextAction(
            kind: NextActionKind.doQuests,
            title: '⚡ Задания недели',
            subtitle: 'Осталось $openQuests из ${active.length}. ${story.hook}',
          );
        }

        final needMandatory =
            (profile.period.plan.mandatory * mandatoryCoverageRatio)
                .round()
                .clamp(1, 9999);
        if (profile.period.fact.mandatorySpent < needMandatory) {
          return NextAction(
            kind: NextActionKind.buyMandatory,
            title: '🍽️ Покорми и позаботься',
            subtitle:
                'Нужное: план ${profile.period.plan.mandatory}, факт ${profile.period.fact.mandatorySpent}.',
          );
        }

        if (profile.selectedGoalId != null &&
            profile.period.fact.saved < profile.period.plan.savings) {
          final left =
              profile.period.plan.savings - profile.period.fact.saved;
          return NextAction(
            kind: NextActionKind.saveMoney,
            title: '🐷 Пополни копилку',
            subtitle: 'По плану ещё $left монет в этой неделе.',
          );
        }

        return NextAction(
          kind: NextActionKind.finishPeriod,
          title: '🏁 Заверши ${story.title}',
          subtitle: 'Сравни план и факт — Финни вырастет за хорошие серии.',
        );
    }
  }

  static EconomyResult confirmPlan(
    PlayerProfile profile,
    BudgetPlan plan, {
    List<Quest> questPool = const [],
  }) {
    if (profile.period.phase != PeriodPhase.planning) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'План уже подтверждён. Дождись следующего периода.',
      );
    }
    if (plan.total > profile.balance) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message:
            'План больше доступных денег. Осталось ${profile.balance} монет.',
      );
    }
    if (plan.mandatory < 0 ||
        plan.optional < 0 ||
        plan.savings < 0 ||
        plan.gift < 0) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Суммы не могут быть отрицательными.',
      );
    }
    if (plan.mandatory <= 0) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message:
            'В плане нужны обязательные расходы — иначе питомец останется голодным.',
      );
    }

    final active = questPool.isEmpty
        ? profile.period.activeQuestIds
        : pickPeriodQuests(profile, questPool);

    final giftPart =
        plan.gift > 0 ? ', подарок ${plan.gift}' : '';
    final updated = profile.copyWith(
      period: profile.period.copyWith(
        plan: plan,
        phase: PeriodPhase.playing,
        activeQuestIds: active,
        completedQuestIds: const [],
        goodQuestStreak: 0,
        failXpQuestIds: const [],
      ),
      lastFeedback: active.isEmpty
          ? 'План готов: нужно ${plan.mandatory}, желаемое ${plan.optional}, копилка ${plan.savings}$giftPart.'
          : 'План готов! На период выдано ${active.length} заданий. Сначала уроки — потом покупки.',
    );
    return EconomyResult(
      profile: updated,
      message: updated.lastFeedback,
    );
  }

  static EconomyResult purchase(PlayerProfile profile, ShopItem item) {
    if (profile.period.phase != PeriodPhase.playing) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Сначала подтверди план бюджета.',
      );
    }
    if (!canAfford(profile, item.price)) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message:
            'Не хватает ${item.price - profile.balance} монет. Выполни задание или отложи желаемое.',
      );
    }

    final fact = profile.period.fact;
    final BudgetFact newFact;
    switch (item.kind) {
      case ExpenseKind.mandatory:
        newFact =
            fact.copyWith(mandatorySpent: fact.mandatorySpent + item.price);
      case ExpenseKind.gift:
        newFact = fact.copyWith(giftSpent: fact.giftSpent + item.price);
      case ExpenseKind.optional:
        newFact =
            fact.copyWith(optionalSpent: fact.optionalSpent + item.price);
    }

    final purchases = [
      ...profile.period.purchases,
      PurchaseRecord(
        itemId: item.id,
        name: item.name,
        price: item.price,
        kind: item.kind,
      ),
    ];

    final planCap = switch (item.kind) {
      ExpenseKind.mandatory => profile.period.plan.mandatory,
      ExpenseKind.gift => profile.period.plan.gift,
      ExpenseKind.optional => profile.period.plan.optional,
    };
    final spent = switch (item.kind) {
      ExpenseKind.mandatory => newFact.mandatorySpent,
      ExpenseKind.gift => newFact.giftSpent,
      ExpenseKind.optional => newFact.optionalSpent,
    };
    // Любой расход сверх плана (в т.ч. при нулевой корзине) — перерасход.
    final overPlan = spent > planCap;

    final message = switch (item.kind) {
      ExpenseKind.mandatory =>
        '${item.name}: обязательная покупка. ${item.effectHint}',
      ExpenseKind.gift =>
        '${item.name}: подарок. ${item.effectHint}',
      ExpenseKind.optional =>
        '${item.name}: желаемая покупка. ${item.effectHint}',
    };
    final planHint = overPlan
        ? ' Финни шепчет: «Это сверх плана — в следующий раз глянь на корзину. Ничего страшного, поправим!»'
        : '';

    final owned = profile.ownedItemIds.contains(item.id)
        ? profile.ownedItemIds
        : [...profile.ownedItemIds, item.id];
    final collectionReward = _maybeCompleteCollection(
      ownedIds: owned,
      alreadyCompleted: profile.completedCollectionIds,
    );
    var stars = profile.stars;
    var moodBonus = 0;
    var completedCollections = profile.completedCollectionIds;
    String? collectionId;
    var celebrate = false;
    var celebrateTitle = '';
    if (collectionReward != null) {
      stars += 3;
      moodBonus += 8;
      completedCollections = [
        ...completedCollections,
        collectionReward.id,
      ];
      collectionId = collectionReward.id;
      celebrate = true;
      celebrateTitle = 'Коллекция «${collectionReward.name}» собрана!';
    }

    final cosmeticHint = Engagement.isCosmetic(item.id)
        ? ' Теперь это видно на ${profile.petName}!'
        : '';

    final updated = profile.copyWith(
      balance: clampBalance(profile.balance - item.price),
      hunger: clampStat(profile.hunger + item.hungerDelta),
      mood: clampStat(
        profile.mood + item.moodDelta + moodBonus + (overPlan ? -3 : 0),
      ),
      stars: stars,
      ownedItemIds: owned,
      completedCollectionIds: completedCollections,
      period: profile.period.copyWith(fact: newFact, purchases: purchases),
      lastFeedback: '$message$planHint$cosmeticHint'
          '${celebrate ? ' $celebrateTitle ★+3' : ''}',
    );
    return EconomyResult(
      profile: updated,
      message: updated.lastFeedback,
      celebrate: celebrate,
      celebrateTitle: celebrate ? celebrateTitle : null,
      collectionCompleteId: collectionId,
      earnedStars: celebrate ? 3 : 0,
    );
  }

  static ItemCollection? _maybeCompleteCollection({
    required List<String> ownedIds,
    required List<String> alreadyCompleted,
  }) {
    for (final collection in Engagement.collections) {
      if (alreadyCompleted.contains(collection.id)) continue;
      if (collection.isComplete(ownedIds)) return collection;
    }
    return null;
  }

  static EconomyResult transferToSavings(PlayerProfile profile, int amount) {
    if (profile.period.phase != PeriodPhase.playing) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Копилку пополняют после подтверждения плана.',
      );
    }
    if (amount <= 0) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Выбери сумму больше нуля.',
      );
    }
    if (profile.selectedGoalId == null) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Сначала выбери цель накопления.',
      );
    }
    if (!canAfford(profile, amount)) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Не хватает монет для копилки.',
      );
    }
    final fact = profile.period.fact;
    var challengeSaved = profile.parentChallengeSaved;
    var challengeDone = false;
    final target = profile.parentChallengeTarget;
    if (target != null && challengeSaved < target) {
      challengeSaved = (challengeSaved + amount).clamp(0, target);
      if (challengeSaved >= target) challengeDone = true;
    }

    final challengeMsg = challengeDone
        ? ' Миссия от родителя выполнена! ★+3'
        : (target != null
            ? ' Челлендж: $challengeSaved/$target.'
            : '');

    final updated = profile.copyWith(
      balance: clampBalance(profile.balance - amount),
      savingsBalance: profile.savingsBalance + amount,
      stars: profile.stars + (challengeDone ? 3 : 0),
      mood: clampStat(profile.mood + (challengeDone ? 10 : 0)),
      parentChallengeSaved: challengeSaved,
      parentChallengeTarget: challengeDone ? null : profile.parentChallengeTarget,
      period: profile.period.copyWith(
        fact: fact.copyWith(saved: fact.saved + amount),
      ),
      lastFeedback:
          'В копилку отложено $amount монет. Так цель становится ближе.$challengeMsg',
    );
    return EconomyResult(
      profile: updated,
      message: updated.lastFeedback,
      celebrate: challengeDone,
      celebrateTitle: challengeDone ? 'Миссия от родителя!' : null,
      earnedStars: challengeDone ? 3 : 0,
    );
  }

  static EconomyResult withdrawFromSavings(
    PlayerProfile profile,
    int amount, {
    required bool confirmed,
  }) {
    if (profile.period.phase != PeriodPhase.playing) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Снимать из копилки можно только во время периода игры.',
      );
    }
    if (!confirmed) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message:
            'Снятие уменьшит копилку на $amount. Подтверди, если уверен.',
      );
    }
    if (amount <= 0 || amount > profile.savingsBalance) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Нельзя снять столько из копилки.',
      );
    }
    final fact = profile.period.fact;
    final savedAfter = (fact.saved - amount).clamp(0, fact.saved);
    final updated = profile.copyWith(
      balance: profile.balance + amount,
      savingsBalance: profile.savingsBalance - amount,
      mood: clampStat(profile.mood - 5),
      period: profile.period.copyWith(
        fact: fact.copyWith(saved: savedAfter),
      ),
      lastFeedback:
          'Из копилки снято $amount. Цель отодвинулась. Попробуй снова откладывать.',
    );
    return EconomyResult(profile: updated, message: updated.lastFeedback);
  }

  static EconomyResult claimGoal(PlayerProfile profile, SavingsGoal goal) {
    if (profile.period.phase == PeriodPhase.planning) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Сначала подтверди план периода — потом забери цель.',
      );
    }
    if (profile.selectedGoalId != goal.id) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Сначала выбери эту цель.',
      );
    }
    if (!goal.availableFor(profile.ageTrack)) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Эта цель для другого возраста.',
      );
    }
    if (profile.savingsBalance < goal.cost) {
      final left = goal.cost - profile.savingsBalance;
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Ещё не хватает $left монет до «${goal.name}».',
      );
    }

    final updated = profile.copyWith(
      savingsBalance: profile.savingsBalance - goal.cost,
      mood: clampStat(profile.mood + 18),
      stars: profile.stars + 5,
      selectedGoalId: null,
      lastFeedback:
          'Цель «${goal.name}» достигнута! ★+5. ${profile.petName} прыгает от радости!',
    );
    return EconomyResult(
      profile: updated,
      message: updated.lastFeedback,
      earnedStars: 5,
      celebrate: true,
      celebrateTitle: 'Цель взята!',
    );
  }

  /// Верный ответ закрывает задание периода. Ошибка — можно повторить.
  /// Каталог («все уроки») — практика: XP и настроение, без монет и ★.
  static EconomyResult completeQuest(
    PlayerProfile profile,
    Quest quest,
    QuestOption option,
  ) {
    if (profile.period.phase != PeriodPhase.playing) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Задания открываются после подтверждения плана бюджета.',
      );
    }
    if (profile.period.completedQuestIds.contains(quest.id)) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Это задание уже выполнено в этом периоде.',
      );
    }
    if (!quest.availableFor(profile.ageTrack)) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Это задание для другого возраста.',
      );
    }
    if (!profile.ageTrack.allowedDifficulties.contains(quest.difficulty)) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Это задание сложнее твоего трека обучения.',
      );
    }

    final hasPeriodSet = profile.period.activeQuestIds.isNotEmpty;
    final isPeriodQuest =
        !hasPeriodSet || profile.period.activeQuestIds.contains(quest.id);
    final isPractice = hasPeriodSet && !isPeriodQuest;

    // Ошибка: учимся, комбо сбрасывается, задание остаётся открытым.
    if (!option.isGood) {
      final alreadyFailed =
          profile.period.failXpQuestIds.contains(quest.id);
      final xpGain = alreadyFailed ? 0 : 3;
      final moodPenalty =
          profile.ageTrack == AgeTrack.junior ? 1 : 3;
      final skills = xpGain > 0
          ? profile.skills.add(quest.theme, xpGain)
          : profile.skills;
      final failIds = alreadyFailed
          ? profile.period.failXpQuestIds
          : [...profile.period.failXpQuestIds, quest.id];
      final xpText = xpGain > 0 ? ' (XP+$xpGain)' : ' (XP уже начислен за попытку)';
      final message = '${option.explanation} Попробуй другой ответ.$xpText';
      final updated = profile.copyWith(
        mood: clampStat(profile.mood - moodPenalty),
        skills: skills,
        period: profile.period.copyWith(
          goodQuestStreak: 0,
          failXpQuestIds: failIds,
        ),
        lastFeedback: message,
      );
      return EconomyResult(
        profile: updated,
        message: message,
        ok: false,
        earnedXp: xpGain,
        combo: 0,
      );
    }

    // Практика из каталога: без монет и ★; закрывается на период (без фарма).
    if (isPractice) {
      final xpGain = (quest.difficulty.xpReward / 2).round().clamp(1, 99);
      final skills = profile.skills.add(quest.theme, xpGain);
      final message =
          '${option.explanation} Практика: XP+$xpGain (монеты — только за задания периода).';
      final updated = profile.copyWith(
        mood: clampStat(profile.mood + 3),
        skills: skills,
        period: profile.period.copyWith(
          completedQuestIds: [...profile.period.completedQuestIds, quest.id],
        ),
        lastFeedback: message,
      );
      return EconomyResult(
        profile: updated,
        message: message,
        earnedXp: xpGain,
        combo: profile.period.goodQuestStreak,
      );
    }

    final baseReward = option.reward;
    final streak = profile.period.goodQuestStreak + 1;
    var comboBonus = streak >= 2 ? (streak.clamp(2, 5) - 1) * 2 : 0;
    if (profile.ageTrack == AgeTrack.junior &&
        comboBonus > juniorComboBonusCap) {
      comboBonus = juniorComboBonusCap;
    }
    final difficultyBonus = quest.difficulty.starReward * 2;
    final periodBonus = hasPeriodSet ? 4 : 0;
    final skillLevel = profile.skills.levelFor(quest.theme);
    final skillBonus =
        (skillLevel - 1).clamp(0, maxSkillCoinBonus);
    final reward =
        baseReward + comboBonus + difficultyBonus + periodBonus + skillBonus;

    final xpGain = quest.difficulty.xpReward;
    final starsGain = quest.difficulty.starReward;
    final moodDelta = 8 + (streak >= 3 ? 4 : 0);

    final skills = profile.skills.add(quest.theme, xpGain);
    final comboBest =
        streak > profile.comboBest ? streak : profile.comboBest;

    final lifetime = profile.completedQuestIds.contains(quest.id)
        ? profile.completedQuestIds
        : [...profile.completedQuestIds, quest.id];

    final comboText = comboBonus > 0 ? ' Комбо ×$streak (+$comboBonus)!' : '';
    final skillText = skillBonus > 0 ? ' Навык +$skillBonus.' : '';
    final periodText = periodBonus > 0 ? ' Бонус периода +$periodBonus.' : '';
    final starsText = ' ★+$starsGain';
    final message =
        '${option.explanation}$comboText$periodText$skillText (+$reward монет, XP+$xpGain$starsText)';

    final updated = profile.copyWith(
      balance: clampBalance(profile.balance + reward),
      mood: clampStat(profile.mood + moodDelta),
      skills: skills,
      stars: profile.stars + starsGain,
      comboBest: comboBest,
      completedQuestIds: lifetime,
      period: profile.period.copyWith(
        completedQuestIds: [...profile.period.completedQuestIds, quest.id],
        goodQuestStreak: streak,
      ),
      lastFeedback: message,
    );
    return EconomyResult(
      profile: updated,
      message: message,
      earnedStars: starsGain,
      earnedXp: xpGain,
      combo: streak,
    );
  }

  static PeriodCloseResult closePeriod(PlayerProfile profile) {
    if (profile.period.phase != PeriodPhase.playing) {
      return PeriodCloseResult(
        profile: profile,
        feedback: 'Период уже завершён.',
        wasGoodPeriod: false,
      );
    }

    final plan = profile.period.plan;
    final fact = profile.period.fact;
    final report = comparePlanFact(plan, fact);

    var mood = profile.mood;
    var hunger = profile.hunger;
    var streak = profile.goodPeriodStreak;
    var stars = profile.stars;
    var balance = profile.balance;
    final reasons = <String>[];

    if (!report.mandatoryOk) {
      mood = clampStat(mood - 10);
      hunger = clampHunger(hunger - 15);
      reasons.add('Обязательные расходы закрыты не полностью.');
    } else {
      reasons.add('Обязательные нужды питомца закрыты.');
      stars += 1;
    }
    if (report.savedOk) {
      reasons.add('Ты отложил деньги на цель.');
      mood = clampStat(mood + 5);
      stars += 1;
    } else {
      reasons.add('В копилку ничего не попало.');
    }
    if (report.planClose) {
      reasons.add('Факт близок к плану — отличный контроль бюджета.');
      stars += 1;
    } else {
      reasons.add('Факт заметно отличается от плана.');
      mood = clampStat(mood - 4);
    }

    final questsDone = profile.period.periodQuestsDone;
    final activeCount = profile.period.activeQuestIds.length;
    if (profile.period.periodQuestsComplete) {
      reasons.add('Все задания периода выполнены — супер!');
      stars += 2;
      balance += 10;
      mood = clampStat(mood + 5);
    } else if (questsDone >= 2 ||
        (activeCount == 0 && profile.period.completedQuestIds.length >= 2)) {
      reasons.add('Ты выполнил $questsDone заданий периода.');
      stars += 1;
      mood = clampStat(mood + 3);
    } else if (questsDone == 0 && profile.period.completedQuestIds.isEmpty) {
      reasons.add('В этом периоде не было верных ответов в заданиях.');
    }

    final good = report.wasGoodPeriod;
    if (good) {
      streak += 1;
    } else {
      streak = streak > 0 ? streak - 1 : 0;
      reasons.add(
        Engagement.softFailHint(
          mandatoryOk: report.mandatoryOk,
          savedOk: report.savedOk,
          planClose: report.planClose,
        ),
      );
    }

    var stage = profile.growthStage;
    final stageUp = applyStageProgress(
      currentStage: stage,
      goodStreak: streak,
    );
    stage = stageUp.stage;
    streak = stageUp.streak;
    if (stageUp.grew) {
      reasons.add(
        'Питомец вырос до стадии $stage «${stageTitle(stage)}»!',
      );
      stars += 2;
    } else {
      reasons.add(stageProgressHintFor(
        growthStage: stage,
        goodPeriodStreak: streak,
      ));
    }

    final story = Engagement.storyForPeriod(profile.period.index);
    final feedback = '${story.title}. ${reasons.join(' ')}';
    final now = DateTime.now();
    final nextUnlock = profile.demoMode
        ? null
        : now.add(normalPeriodCooldown).toIso8601String();
    final summaryProfile = profile.copyWith(
      balance: clampBalance(balance),
      mood: mood,
      hunger: hunger,
      goodPeriodStreak: streak,
      growthStage: stage,
      stars: stars,
      nextPeriodAvailableAt: nextUnlock,
      period: profile.period.copyWith(
        phase: PeriodPhase.summary,
        feedback: feedback,
      ),
      lastFeedback: feedback,
      totalPeriodsCompleted: profile.totalPeriodsCompleted + 1,
    );

    return PeriodCloseResult(
      profile: summaryProfile,
      feedback: feedback,
      wasGoodPeriod: good,
      stageGrew: stageUp.grew,
      softFail: !good,
    );
  }

  /// Правила перехода на следующую стадию питомца.
  static StageProgress applyStageProgress({
    required int currentStage,
    required int goodStreak,
  }) {
    var stage = currentStage.clamp(1, stages).toInt();
    var streak = goodStreak;
    var grew = false;
    if (streak >= goodPeriodsPerStage && stage < stages) {
      stage += 1;
      streak = 0;
      grew = true;
    }
    return StageProgress(stage: stage, streak: streak, grew: grew);
  }

  static PlayerProfile startNextPeriod(
    PlayerProfile profile, {
    DateTime? now,
  }) {
    if (!canAdvancePeriod(profile, now: now)) {
      final left = periodCooldownLeft(profile, now: now);
      final mins = left == null ? 0 : left.inMinutes.clamp(1, 9999);
      return profile.copyWith(
        lastFeedback:
            'В обычном режиме следующий период через ~$mins мин. Включи демо — периоды идут сразу.',
      );
    }
    final nextIndex = profile.period.index + 1;
    final income = incomeForTrack(profile.ageTrack);
    final newBalance = clampBalance(profile.balance + income);
    final story = Engagement.storyForPeriod(nextIndex);
    final demoHint =
        profile.demoMode ? ' Демо: периоды без ожидания.' : '';
    return profile.copyWith(
      balance: newBalance,
      hunger: clampHunger(profile.hunger - 8),
      nextPeriodAvailableAt: null,
      period: GamePeriod(
        index: nextIndex,
        startingBalance: newBalance,
        phase: PeriodPhase.planning,
      ),
      lastFeedback:
          'Новая ${story.title.toLowerCase()}! ${story.hook} Доход +$income. ${story.mission}$demoHint',
    );
  }

  /// Секрет дня — один раз в календарный день.
  static EconomyResult claimSecretOfDay(
    PlayerProfile profile, {
    DateTime? now,
  }) {
    final day = calendarDayKey(now);
    if (profile.secretClaimedDay == day) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Секрет дня уже открыт. Загляни завтра!',
      );
    }
    final reward = Engagement.secretForDay(day);
    final updated = profile.copyWith(
      balance: clampBalance(profile.balance + reward.coins),
      mood: clampStat(profile.mood + reward.mood),
      stars: profile.stars + reward.stars,
      secretClaimedDay: day,
      lastFeedback: '${reward.title}: ${reward.message}',
    );
    return EconomyResult(
      profile: updated,
      message: updated.lastFeedback,
      earnedStars: reward.stars,
      celebrate: true,
      celebrateTitle: reward.title,
    );
  }

  static bool canClaimSecretOfDay(PlayerProfile profile, {DateTime? now}) {
    return profile.secretClaimedDay != calendarDayKey(now);
  }

  /// Родительский челлендж: отложить N монет в копилку.
  static EconomyResult setParentChallenge(
    PlayerProfile profile,
    int targetCoins,
  ) {
    if (targetCoins < 10 || targetCoins > 200) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Выбери цель от 10 до 200 монет.',
      );
    }
    final updated = profile.copyWith(
      parentChallengeTarget: targetCoins,
      parentChallengeSaved: 0,
      lastFeedback:
          'Миссия от родителя: отложи $targetCoins монет в копилку. ${profile.petName} в деле!',
    );
    return EconomyResult(profile: updated, message: updated.lastFeedback);
  }

  static EconomyResult clearParentChallenge(PlayerProfile profile) {
    final updated = profile.copyWith(
      parentChallengeTarget: null,
      parentChallengeSaved: 0,
      lastFeedback: 'Родительский челлендж снят.',
    );
    return EconomyResult(profile: updated, message: updated.lastFeedback);
  }

  /// Бонус за вход раз в календарный день. Пропуск дня не отнимает прогресс.
  static EconomyResult claimDailyLogin(
    PlayerProfile profile, {
    DateTime? now,
  }) {
    final day = calendarDayKey(now);
    if (profile.lastLoginBonusDay == day) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Бонус за сегодня уже получен.',
      );
    }
    final message =
        'Бонус за вход: +$loginBonusCoins монет. Пропуск дня ничего не отнимает.';
    final updated = profile.copyWith(
      balance: clampBalance(profile.balance + loginBonusCoins),
      mood: clampStat(profile.mood + 2),
      lastLoginBonusDay: day,
      lastFeedback: message,
    );
    return EconomyResult(profile: updated, message: message);
  }

  /// Опциональная выдача монет родителем (с лимитом на профиль).
  static EconomyResult grantParentCoins(
    PlayerProfile profile, {
    int amount = parentGrantAmount,
  }) {
    if (amount <= 0) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Сумма должна быть больше нуля.',
      );
    }
    if (profile.parentGrantTotal >= parentGrantCap) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Лимит родительских монет на этот профиль исчерпан ($parentGrantCap).',
      );
    }
    final room = parentGrantCap - profile.parentGrantTotal;
    final give = amount > room ? room : amount;
    final message =
        'Родитель добавил +$give монет. Всего выдано ${profile.parentGrantTotal + give}/$parentGrantCap.';
    final updated = profile.copyWith(
      balance: clampBalance(profile.balance + give),
      parentGrantTotal: profile.parentGrantTotal + give,
      mood: clampStat(profile.mood + 3),
      lastFeedback: message,
    );
    return EconomyResult(profile: updated, message: message);
  }

  static int remainingToGoal(PlayerProfile profile, SavingsGoal? goal) {
    if (goal == null) return 0;
    final left = goal.cost - profile.savingsBalance;
    return left < 0 ? 0 : left;
  }

  static int? estimatedPeriodsToGoal(
    PlayerProfile profile,
    SavingsGoal goal, {
    int? averageSaving,
  }) {
    final left = remainingToGoal(profile, goal);
    if (left == 0) return 0;
    final avg = averageSaving ??
        (profile.period.plan.savings > 0 ? profile.period.plan.savings : 15);
    if (avg <= 0) return null;
    return (left / avg).ceil();
  }

  static bool isQuestDoneThisPeriod(PlayerProfile profile, String questId) =>
      profile.period.completedQuestIds.contains(questId);

  /// Уроки блока «Учёба» для трека возраста.
  static List<LearningLesson> lessonsForProfile(
    PlayerProfile profile,
    List<LearningLesson> all,
  ) {
    return all.where((l) => l.availableFor(profile.ageTrack)).toList();
  }

  /// Урок «сегодня»: сначала незавершённые, с ротацией по периоду.
  static LearningLesson? featuredLesson(
    PlayerProfile profile,
    List<LearningLesson> all,
  ) {
    final list = lessonsForProfile(profile, all);
    if (list.isEmpty) return null;
    final open =
        list.where((l) => !profile.completedLessonIds.contains(l.id)).toList();
    final pool = open.isNotEmpty ? open : list;
    final offset = (profile.period.index - 1).clamp(0, 999);
    return pool[offset % pool.length];
  }

  static int lessonsDoneCount(
    PlayerProfile profile,
    List<LearningLesson> all,
  ) {
    final ids = lessonsForProfile(profile, all).map((l) => l.id).toSet();
    return profile.completedLessonIds.where(ids.contains).length;
  }

  /// Верный ответ мини-проверки закрывает урок и даёт награду (один раз).
  static EconomyResult completeLesson(
    PlayerProfile profile,
    LearningLesson lesson,
    QuestOption option,
  ) {
    if (!lesson.availableFor(profile.ageTrack)) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Этот урок для другого возраста.',
      );
    }
    if (!option.isGood) {
      final moodPenalty = profile.ageTrack == AgeTrack.junior ? 0 : 1;
      final message =
          '${option.explanation} Подумай ещё — можно выбрать снова.';
      return EconomyResult(
        profile: profile.copyWith(
          mood: clampStat(profile.mood - moodPenalty),
          lastFeedback: message,
        ),
        ok: false,
        message: message,
      );
    }

    final already = profile.completedLessonIds.contains(lesson.id);
    if (already) {
      final message =
          '${option.explanation} Урок уже изучен — можно перечитать когда угодно.';
      return EconomyResult(
        profile: profile.copyWith(lastFeedback: message),
        message: message,
      );
    }

    final coins = lesson.rewardCoins;
    final xp = lesson.rewardXp;
    final skills = profile.skills.add(lesson.theme, xp);
    final message =
        '${option.explanation} Урок «${lesson.title}» изучен! +$coins монет, XP+$xp, ★+1';
    final updated = profile.copyWith(
      balance: clampBalance(profile.balance + coins),
      mood: clampStat(profile.mood + 5),
      stars: profile.stars + 1,
      skills: skills,
      completedLessonIds: [...profile.completedLessonIds, lesson.id],
      lastFeedback: message,
    );
    return EconomyResult(
      profile: updated,
      message: message,
      earnedStars: 1,
      earnedXp: xp,
    );
  }
}

class PeriodCloseResult {
  const PeriodCloseResult({
    required this.profile,
    required this.feedback,
    required this.wasGoodPeriod,
    this.stageGrew = false,
    this.softFail = false,
  });

  final PlayerProfile profile;
  final String feedback;
  final bool wasGoodPeriod;
  final bool stageGrew;
  final bool softFail;
}

/// Сводка план vs факт за период.
class PlanFactReport {
  const PlanFactReport({
    required this.mandatoryDelta,
    required this.optionalDelta,
    required this.savingsDelta,
    required this.giftDelta,
    required this.totalDelta,
    required this.mandatoryOk,
    required this.planClose,
    required this.savedOk,
    required this.wasGoodPeriod,
  });

  final int mandatoryDelta;
  final int optionalDelta;
  final int savingsDelta;
  final int giftDelta;
  final int totalDelta;
  final bool mandatoryOk;
  final bool planClose;
  final bool savedOk;
  final bool wasGoodPeriod;
}

class StageProgress {
  const StageProgress({
    required this.stage,
    required this.streak,
    required this.grew,
  });

  final int stage;
  final int streak;
  final bool grew;
}
