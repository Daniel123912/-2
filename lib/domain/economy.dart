import 'models.dart';

/// Pure game-economy rules. Covered by unit tests.
///
/// Документ с формулами: `docs/economy_rules.md`.
class GameEconomy {
  static const int periodIncome = 40;
  static const int maxStat = 100;
  static const int minStat = 0;
  static const int stages = 3;
  static const int goodPeriodsPerStage = 2;

  /// Допуск «факт близок к плану» (суммарно по трём корзинам).
  static const int planFactTolerance = 15;

  /// Доля обязательных расходов от плана, достаточная для «закрытия нужд».
  static const double mandatoryCoverageRatio = 0.7;

  static int clampStat(int value) =>
      value.clamp(minStat, maxStat).toInt();

  /// Баланс никогда не уходит в минус.
  static int clampBalance(int value) => value < 0 ? 0 : value;

  static bool canAfford(PlayerProfile profile, int price) =>
      price >= 0 && profile.balance >= price;

  /// Периодический доход (начисление валюты в начале периода).
  static int incomeForTrack(AgeTrack track) =>
      periodIncome + (track == AgeTrack.senior ? 5 : 0);

  /// Стартовый баланс нового профиля по треку возраста.
  static int startingBalanceFor(AgeTrack track) => track.startingBalance;

  /// План vs факт: дельты и флаги исхода периода.
  static PlanFactReport comparePlanFact(BudgetPlan plan, BudgetFact fact) {
    final mandatoryNeed =
        (plan.mandatory * mandatoryCoverageRatio).round();
    final mandatoryOk =
        fact.mandatorySpent >= mandatoryNeed && fact.mandatorySpent > 0;
    final totalFact =
        fact.mandatorySpent + fact.optionalSpent + fact.saved;
    final totalDelta = totalFact - plan.total;
    final planClose = totalDelta.abs() <= planFactTolerance;
    final savedOk = fact.saved > 0;
    final wasGoodPeriod = mandatoryOk && (savedOk || planClose);
    return PlanFactReport(
      mandatoryDelta: fact.mandatorySpent - plan.mandatory,
      optionalDelta: fact.optionalSpent - plan.optional,
      savingsDelta: fact.saved - plan.savings,
      totalDelta: totalDelta,
      mandatoryOk: mandatoryOk,
      planClose: planClose,
      savedOk: savedOk,
      wasGoodPeriod: wasGoodPeriod,
    );
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
    }

    return picked;
  }

  static BudgetPlan recommendedPlan(PlayerProfile profile) {
    final bal = profile.balance;
    final ratios = switch (profile.ageTrack) {
      AgeTrack.junior => (0.50, 0.25, 0.25),
      AgeTrack.middle => (0.45, 0.30, 0.25),
      AgeTrack.senior => (0.40, 0.30, 0.30),
    };
    var mandatory = (bal * ratios.$1).round();
    var optional = (bal * ratios.$2).round();
    var savings = (bal * ratios.$3).round();
    final drift = bal - (mandatory + optional + savings);
    savings += drift;
    if (savings < 0) {
      mandatory = (mandatory + savings).clamp(0, bal);
      savings = 0;
    }
    return BudgetPlan(
      mandatory: mandatory,
      optional: optional.clamp(0, bal),
      savings: savings.clamp(0, bal),
    );
  }

  static NextAction nextAction(
    PlayerProfile profile, {
    SavingsGoal? goal,
  }) {
    if (goal != null &&
        profile.selectedGoalId == goal.id &&
        profile.savingsBalance >= goal.cost) {
      return NextAction(
        kind: NextActionKind.claimGoal,
        title: 'Забери цель!',
        subtitle: 'В копилке хватает на «${goal.name}».',
      );
    }

    switch (profile.period.phase) {
      case PeriodPhase.planning:
        return const NextAction(
          kind: NextActionKind.planBudget,
          title: 'Составь план бюджета',
          subtitle: 'Разложи монеты: нужное, желаемое, копилка.',
        );
      case PeriodPhase.summary:
        return const NextAction(
          kind: NextActionKind.viewSummary,
          title: 'Смотри итог периода',
          subtitle: 'Сравни план и факт, затем начни новый период.',
        );
      case PeriodPhase.playing:
        final active = profile.period.activeQuestIds;
        final done = profile.period.completedQuestIds.toSet();
        final openQuests = active.where((id) => !done.contains(id)).length;
        if (openQuests > 0) {
          return NextAction(
            kind: NextActionKind.doQuests,
            title: 'Выполни задания периода',
            subtitle: 'Осталось $openQuests из ${active.length}.',
          );
        }

        final needMandatory =
            (profile.period.plan.mandatory * mandatoryCoverageRatio)
                .round()
                .clamp(1, 9999);
        if (profile.period.fact.mandatorySpent < needMandatory) {
          return NextAction(
            kind: NextActionKind.buyMandatory,
            title: 'Закрой обязательные покупки',
            subtitle:
                'План ${profile.period.plan.mandatory}, факт ${profile.period.fact.mandatorySpent}.',
          );
        }

        if (profile.selectedGoalId != null &&
            profile.period.fact.saved < profile.period.plan.savings) {
          final left =
              profile.period.plan.savings - profile.period.fact.saved;
          return NextAction(
            kind: NextActionKind.saveMoney,
            title: 'Пополни копилку',
            subtitle: 'По плану ещё $left монет в этом периоде.',
          );
        }

        return const NextAction(
          kind: NextActionKind.finishPeriod,
          title: 'Заверши период',
          subtitle: 'Сравни план и факт — питомец вырастет за хорошие серии.',
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
    if (plan.mandatory < 0 || plan.optional < 0 || plan.savings < 0) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Суммы не могут быть отрицательными.',
      );
    }

    final active = questPool.isEmpty
        ? profile.period.activeQuestIds
        : pickPeriodQuests(profile, questPool);

    final updated = profile.copyWith(
      period: profile.period.copyWith(
        plan: plan,
        phase: PeriodPhase.playing,
        activeQuestIds: active,
        completedQuestIds: const [],
        goodQuestStreak: 0,
      ),
      lastFeedback: active.isEmpty
          ? 'План готов: нужно ${plan.mandatory}, желаемое ${plan.optional}, копилка ${plan.savings}.'
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
    final newFact = item.kind == ExpenseKind.mandatory
        ? fact.copyWith(mandatorySpent: fact.mandatorySpent + item.price)
        : fact.copyWith(optionalSpent: fact.optionalSpent + item.price);

    final purchases = [
      ...profile.period.purchases,
      PurchaseRecord(
        itemId: item.id,
        name: item.name,
        price: item.price,
        kind: item.kind,
      ),
    ];

    final planCap = item.kind == ExpenseKind.mandatory
        ? profile.period.plan.mandatory
        : profile.period.plan.optional;
    final spent = item.kind == ExpenseKind.mandatory
        ? newFact.mandatorySpent
        : newFact.optionalSpent;
    final overPlan = planCap > 0 && spent > planCap;

    final message = item.kind == ExpenseKind.mandatory
        ? '${item.name}: обязательная покупка. ${item.effectHint}'
        : '${item.name}: желаемая покупка. ${item.effectHint}';
    final planHint = overPlan
        ? ' Внимание: факт по этой корзине уже выше плана.'
        : '';

    final updated = profile.copyWith(
      balance: clampBalance(profile.balance - item.price),
      hunger: clampStat(profile.hunger + item.hungerDelta),
      mood: clampStat(profile.mood + item.moodDelta + (overPlan ? -3 : 0)),
      period: profile.period.copyWith(fact: newFact, purchases: purchases),
      lastFeedback: '$message$planHint',
    );
    return EconomyResult(profile: updated, message: updated.lastFeedback);
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
    final updated = profile.copyWith(
      balance: clampBalance(profile.balance - amount),
      savingsBalance: profile.savingsBalance + amount,
      period: profile.period.copyWith(
        fact: fact.copyWith(saved: fact.saved + amount),
      ),
      lastFeedback:
          'В копилку отложено $amount монет. Так цель становится ближе.',
    );
    return EconomyResult(profile: updated, message: updated.lastFeedback);
  }

  static EconomyResult withdrawFromSavings(
    PlayerProfile profile,
    int amount, {
    required bool confirmed,
  }) {
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
    final updated = profile.copyWith(
      balance: profile.balance + amount,
      savingsBalance: profile.savingsBalance - amount,
      mood: clampStat(profile.mood - 5),
      lastFeedback:
          'Из копилки снято $amount. Цель отодвинулась. Попробуй снова откладывать.',
    );
    return EconomyResult(profile: updated, message: updated.lastFeedback);
  }

  static EconomyResult claimGoal(PlayerProfile profile, SavingsGoal goal) {
    if (profile.selectedGoalId != goal.id) {
      return EconomyResult(
        profile: profile,
        ok: false,
        message: 'Сначала выбери эту цель.',
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
          'Цель «${goal.name}» достигнута! ★+5. Можно выбрать новую цель.',
    );
    return EconomyResult(
      profile: updated,
      message: updated.lastFeedback,
      earnedStars: 5,
    );
  }

  /// Верный ответ закрывает задание периода. Ошибка — можно повторить.
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

    // Ошибка: учимся, комбо сбрасывается, задание остаётся открытым.
    if (!option.isGood) {
      const xpGain = 3;
      final skills = profile.skills.add(quest.theme, xpGain);
      final message =
          '${option.explanation} Попробуй другой ответ. (XP+$xpGain)';
      final updated = profile.copyWith(
        mood: clampStat(profile.mood - 3),
        skills: skills,
        period: profile.period.copyWith(goodQuestStreak: 0),
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

    final baseReward = option.reward;
    final streak = profile.period.goodQuestStreak + 1;
    final comboBonus = streak >= 2 ? (streak.clamp(2, 5) - 1) * 2 : 0;
    final difficultyBonus = quest.difficulty.starReward * 2;
    final isPeriodQuest = profile.period.activeQuestIds.contains(quest.id);
    final periodBonus = isPeriodQuest ? 4 : 0;
    final reward = baseReward + comboBonus + difficultyBonus + periodBonus;

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
    final periodText = periodBonus > 0 ? ' Бонус периода +$periodBonus.' : '';
    final starsText = ' ★+$starsGain';
    final message =
        '${option.explanation}$comboText$periodText (+$reward монет, XP+$xpGain$starsText)';

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
      hunger = clampStat(hunger - 15);
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
      reasons.add('В копилку ничего не попало — попробуй в следующем периоде.');
    }
    if (report.planClose) {
      reasons.add('Факт близок к плану — отличный контроль бюджета.');
      stars += 1;
    } else {
      reasons.add('Факт заметно отличается от плана. Скорректируй следующий.');
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
    }

    var stage = profile.growthStage;
    final stageUp = applyStageProgress(
      currentStage: stage,
      goodStreak: streak,
    );
    stage = stageUp.stage;
    streak = stageUp.streak;
    if (stageUp.grew) {
      reasons.add('Питомец вырос до стадии $stage!');
      stars += 2;
    }

    final feedback = reasons.join(' ');
    final summaryProfile = profile.copyWith(
      balance: clampBalance(balance),
      mood: mood,
      hunger: hunger,
      goodPeriodStreak: streak,
      growthStage: stage,
      stars: stars,
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

  static PlayerProfile startNextPeriod(PlayerProfile profile) {
    final nextIndex = profile.period.index + 1;
    final income = incomeForTrack(profile.ageTrack);
    final newBalance = clampBalance(profile.balance + income);
    return profile.copyWith(
      balance: newBalance,
      hunger: clampStat(profile.hunger - 8),
      period: GamePeriod(
        index: nextIndex,
        startingBalance: newBalance,
        phase: PeriodPhase.planning,
      ),
      lastFeedback:
          'Новый период $nextIndex. Получен доход +$income. Составь новый план.',
    );
  }

  static int remainingToGoal(PlayerProfile profile, SavingsGoal? goal) {
    if (goal == null) return 0;
    final left = goal.cost - profile.savingsBalance;
    return left < 0 ? 0 : left;
  }

  static int? estimatedPeriodsToGoal(
    PlayerProfile profile,
    SavingsGoal goal, {
    int averageSaving = 15,
  }) {
    final left = remainingToGoal(profile, goal);
    if (left == 0) return 0;
    if (averageSaving <= 0) return null;
    return (left / averageSaving).ceil();
  }

  static bool isQuestDoneThisPeriod(PlayerProfile profile, String questId) =>
      profile.period.completedQuestIds.contains(questId);
}

class PeriodCloseResult {
  const PeriodCloseResult({
    required this.profile,
    required this.feedback,
    required this.wasGoodPeriod,
  });

  final PlayerProfile profile;
  final String feedback;
  final bool wasGoodPeriod;
}

/// Сводка план vs факт за период.
class PlanFactReport {
  const PlanFactReport({
    required this.mandatoryDelta,
    required this.optionalDelta,
    required this.savingsDelta,
    required this.totalDelta,
    required this.mandatoryOk,
    required this.planClose,
    required this.savedOk,
    required this.wasGoodPeriod,
  });

  final int mandatoryDelta;
  final int optionalDelta;
  final int savingsDelta;
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
