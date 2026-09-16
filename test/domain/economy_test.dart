import 'package:finny/domain/economy.dart';
import 'package:finny/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerProfile baseProfile({
  int balance = 100,
  AgeTrack ageTrack = AgeTrack.middle,
}) {
  return PlayerProfile.fresh(
    playerName: 'Саша',
    petName: 'Финни',
    appearance: const PetAppearance(
      body: 'круглый',
      color: 'рыжий',
      accessory: 'бантик',
    ),
    startingBalance: balance,
    ageTrack: ageTrack,
  );
}

Quest sampleQuest({
  String id = 'q1',
  QuestTheme theme = QuestTheme.budget,
  QuestDifficulty difficulty = QuestDifficulty.easy,
  bool goodFirst = true,
}) {
  return Quest(
    id: id,
    title: 'Тест',
    prompt: '?',
    theme: theme,
    difficulty: difficulty,
    options: [
      QuestOption(
        id: 'a',
        label: 'да',
        isGood: goodFirst,
        reward: 12,
        explanation: 'хорошо',
      ),
      const QuestOption(
        id: 'b',
        label: 'нет',
        isGood: false,
        reward: 3,
        explanation: 'подумай ещё',
      ),
    ],
  );
}

void main() {
  group('GameEconomy', () {
    test('confirmPlan rejects overspend', () {
      final profile = baseProfile(balance: 50);
      final result = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 30, optional: 20, savings: 10),
      );
      expect(result.ok, isFalse);
    });

    test('confirmPlan locks plan, opens playing and assigns quests', () {
      final profile = baseProfile();
      final pool = [
        sampleQuest(id: 'qb', theme: QuestTheme.budget),
        sampleQuest(id: 'qs', theme: QuestTheme.savings),
        sampleQuest(id: 'qp', theme: QuestTheme.purchases),
      ];
      final result = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: pool,
      );
      expect(result.ok, isTrue);
      expect(result.profile.period.phase, PeriodPhase.playing);
      expect(result.profile.period.plan.total, 90);
      expect(result.profile.period.activeQuestIds.length, 3);
    });

    test('purchase fails without funds', () {
      final planned = GameEconomy.confirmPlan(
        baseProfile(balance: 20),
        const BudgetPlan(mandatory: 10, optional: 5, savings: 5),
      ).profile;
      final item = const ShopItem(
        id: 'toy',
        name: 'Мячик',
        price: 25,
        kind: ExpenseKind.optional,
        effectHint: 'весело',
        hungerDelta: 0,
        moodDelta: 5,
      );
      final result = GameEconomy.purchase(planned, item);
      expect(result.ok, isFalse);
      expect(result.message, contains('Не хватает'));
    });

    test('purchase decreases balance and updates fact', () {
      final planned = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
      ).profile;
      final item = const ShopItem(
        id: 'food',
        name: 'Еда',
        price: 20,
        kind: ExpenseKind.mandatory,
        effectHint: 'сытость',
        hungerDelta: 20,
        moodDelta: 5,
      );
      final result = GameEconomy.purchase(planned, item);
      expect(result.ok, isTrue);
      expect(result.profile.balance, 80);
      expect(result.profile.period.fact.mandatorySpent, 20);
    });

    test('savings transfer and withdraw require confirmation', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 30, optional: 20, savings: 30),
      ).profile;
      profile = profile.copyWith(selectedGoalId: 'house');
      final saved = GameEconomy.transferToSavings(profile, 15);
      expect(saved.ok, isTrue);
      expect(saved.profile.savingsBalance, 15);

      final warn = GameEconomy.withdrawFromSavings(
        saved.profile,
        15,
        confirmed: false,
      );
      expect(warn.ok, isFalse);

      final withdrawn = GameEconomy.withdrawFromSavings(
        saved.profile,
        15,
        confirmed: true,
      );
      expect(withdrawn.ok, isTrue);
      expect(withdrawn.profile.savingsBalance, 0);
    });

    test('claimGoal spends savings and grants stars', () {
      var profile = baseProfile().copyWith(
        selectedGoalId: 'party',
        savingsBalance: 90,
      );
      const goal = SavingsGoal(
        id: 'party',
        name: 'Праздник',
        cost: 90,
        description: 'fun',
      );
      final result = GameEconomy.claimGoal(profile, goal);
      expect(result.ok, isTrue);
      expect(result.profile.savingsBalance, 0);
      expect(result.profile.stars, 5);
      expect(result.profile.selectedGoalId, isNull);
    });

    test('closePeriod can grow pet after good streak', () {
      var profile = baseProfile();
      for (var i = 0; i < 2; i++) {
        profile = GameEconomy.confirmPlan(
          profile,
          const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        ).profile;
        profile = GameEconomy.purchase(
          profile,
          const ShopItem(
            id: 'food',
            name: 'Еда',
            price: 25,
            kind: ExpenseKind.mandatory,
            effectHint: 'ok',
            hungerDelta: 10,
            moodDelta: 5,
          ),
        ).profile;
        profile = GameEconomy.transferToSavings(
          profile.copyWith(selectedGoalId: 'house'),
          15,
        ).profile;
        final closed = GameEconomy.closePeriod(profile);
        profile = closed.profile;
        if (profile.period.phase == PeriodPhase.summary) {
          profile = GameEconomy.startNextPeriod(profile);
        }
      }
      expect(profile.growthStage, greaterThanOrEqualTo(1));
      expect(profile.totalPeriodsCompleted, greaterThanOrEqualTo(1));
    });

    test('quest blocked before plan', () {
      final profile = baseProfile();
      final quest = sampleQuest();
      final result =
          GameEconomy.completeQuest(profile, quest, quest.options.first);
      expect(result.ok, isFalse);
      expect(result.message, contains('плана'));
    });

    test('wrong answer allows retry; good answer closes once', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final quest = sampleQuest();
      final wrong = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.last,
      );
      expect(wrong.ok, isFalse);
      expect(wrong.profile.period.completedQuestIds, isEmpty);
      expect(wrong.profile.period.goodQuestStreak, 0);

      final first = GameEconomy.completeQuest(
        wrong.profile,
        quest,
        quest.options.first,
      );
      expect(first.ok, isTrue);
      expect(first.profile.period.completedQuestIds, contains('q1'));
      expect(first.profile.stars, 1);
      expect(first.profile.skills.budgetXp, greaterThan(0));

      final second = GameEconomy.completeQuest(
        first.profile,
        quest,
        quest.options.first,
      );
      expect(second.ok, isFalse);
    });

    test('quests filtered by age track', () {
      final junior = baseProfile(ageTrack: AgeTrack.junior);
      const easy = Quest(
        id: 'easy',
        title: 'e',
        prompt: '?',
        theme: QuestTheme.budget,
        difficulty: QuestDifficulty.easy,
        ageTracks: {AgeTrack.junior, AgeTrack.middle},
        options: [],
      );
      const hard = Quest(
        id: 'hard',
        title: 'h',
        prompt: '?',
        theme: QuestTheme.budget,
        difficulty: QuestDifficulty.hard,
        ageTracks: {AgeTrack.senior},
        options: [],
      );
      final list = GameEconomy.questsForProfile(junior, [easy, hard]);
      expect(list.map((e) => e.id), ['easy']);
    });

    test('nextAction guides planning then quests', () {
      final planning = baseProfile();
      expect(
        GameEconomy.nextAction(planning).kind,
        NextActionKind.planBudget,
      );

      final playing = GameEconomy.confirmPlan(
        planning,
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [
          sampleQuest(id: 'qb', theme: QuestTheme.budget),
          sampleQuest(id: 'qs', theme: QuestTheme.savings),
          sampleQuest(id: 'qp', theme: QuestTheme.purchases),
        ],
      ).profile;
      expect(
        GameEconomy.nextAction(playing).kind,
        NextActionKind.doQuests,
      );
    });

    test('quest can be replayed in next period', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final quest = sampleQuest();
      profile = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.first,
      ).profile;
      profile = GameEconomy.closePeriod(profile).profile;
      profile = GameEconomy.startNextPeriod(profile);
      profile = GameEconomy.confirmPlan(
        profile,
        const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final again = GameEconomy.completeQuest(
        profile,
        quest,
        quest.options.first,
      );
      expect(again.ok, isTrue);
    });

    test('starting balance depends on age track', () {
      expect(GameEconomy.startingBalanceFor(AgeTrack.junior), 100);
      expect(GameEconomy.startingBalanceFor(AgeTrack.middle), 110);
      expect(GameEconomy.startingBalanceFor(AgeTrack.senior), 120);
      final senior = PlayerProfile.fresh(
        playerName: 'Саша',
        petName: 'Финни',
        appearance: const PetAppearance(
          body: 'круглый',
          color: 'рыжий',
          accessory: 'бантик',
        ),
        ageTrack: AgeTrack.senior,
      );
      expect(senior.balance, 120);
    });

    test('period income is credited and never goes negative', () {
      final next = GameEconomy.startNextPeriod(baseProfile(balance: 50));
      expect(next.balance, 50 + GameEconomy.incomeForTrack(AgeTrack.middle));
      expect(next.period.phase, PeriodPhase.planning);
      expect(next.period.index, 2);
      expect(GameEconomy.clampBalance(-7), 0);
      expect(GameEconomy.canAfford(baseProfile(balance: 10), 11), isFalse);
    });

    test('recommendedPlan distributes full balance into three baskets', () {
      final plan = GameEconomy.recommendedPlan(baseProfile(balance: 100));
      expect(plan.total, 100);
      expect(plan.mandatory, greaterThan(0));
      expect(plan.optional, greaterThan(0));
      expect(plan.savings, greaterThan(0));
    });

    test('comparePlanFact marks good period when needs and savings ok', () {
      const plan = BudgetPlan(mandatory: 30, optional: 20, savings: 20);
      const fact = BudgetFact(mandatorySpent: 25, optionalSpent: 10, saved: 15);
      final report = GameEconomy.comparePlanFact(plan, fact);
      expect(report.mandatoryOk, isTrue);
      expect(report.savedOk, isTrue);
      expect(report.wasGoodPeriod, isTrue);
    });

    test('bad mandatory spending hurts pet stats on closePeriod', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
      ).profile;
      final beforeHunger = profile.hunger;
      final beforeMood = profile.mood;
      // Spend only optional — skip mandatory needs.
      profile = GameEconomy.purchase(
        profile,
        const ShopItem(
          id: 'toy',
          name: 'Игрушка',
          price: 10,
          kind: ExpenseKind.optional,
          effectHint: 'весело',
          hungerDelta: 0,
          moodDelta: 2,
        ),
      ).profile;
      final closed = GameEconomy.closePeriod(profile);
      expect(closed.wasGoodPeriod, isFalse);
      expect(closed.profile.hunger, lessThan(beforeHunger));
      expect(closed.profile.mood, lessThan(beforeMood + 2));
      expect(closed.feedback, contains('Обязательные'));
    });

    test('two good periods grow pet to stage 2', () {
      var profile = baseProfile().copyWith(selectedGoalId: 'house');
      expect(profile.growthStage, 1);

      for (var i = 0; i < 2; i++) {
        profile = GameEconomy.confirmPlan(
          profile,
          const BudgetPlan(mandatory: 30, optional: 20, savings: 20),
        ).profile;
        profile = GameEconomy.purchase(
          profile,
          const ShopItem(
            id: 'food',
            name: 'Еда',
            price: 25,
            kind: ExpenseKind.mandatory,
            effectHint: 'ok',
            hungerDelta: 10,
            moodDelta: 5,
          ),
        ).profile;
        profile = GameEconomy.transferToSavings(profile, 15).profile;
        final closed = GameEconomy.closePeriod(profile);
        expect(closed.wasGoodPeriod, isTrue);
        profile = closed.profile;
        if (profile.period.phase == PeriodPhase.summary) {
          profile = GameEconomy.startNextPeriod(profile);
        }
      }

      expect(profile.growthStage, 2);
      expect(
        GameEconomy.applyStageProgress(currentStage: 3, goodStreak: 5).grew,
        isFalse,
      );
    });

    test('quest reward links finance to pet mood and balance', () {
      var profile = GameEconomy.confirmPlan(
        baseProfile(balance: 100),
        const BudgetPlan(mandatory: 40, optional: 30, savings: 20),
        questPool: [sampleQuest()],
      ).profile;
      final before = profile.balance;
      final beforeMood = profile.mood;
      final result = GameEconomy.completeQuest(
        profile,
        sampleQuest(),
        sampleQuest().options.first,
      );
      expect(result.ok, isTrue);
      expect(result.profile.balance, greaterThan(before));
      expect(result.profile.mood, greaterThan(beforeMood));
      expect(result.earnedStars, 1);
    });
  });
}
