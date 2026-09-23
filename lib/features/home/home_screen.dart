import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../adult/adult_screen.dart';
import '../budget/budget_screen.dart';
import '../learn/learn_screen.dart';
import '../period/period_summary_screen.dart';
import '../quests/quests_screen.dart';
import '../savings/savings_screen.dart';
import '../shop/shop_screen.dart';
import '../widgets/common.dart';
import 'junior_play_shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _loginClaimed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoginBonus());
  }

  Future<void> _tryLoginBonus() async {
    if (_loginClaimed || !mounted) return;
    _loginClaimed = true;
    final result =
        await ref.read(gameControllerProvider.notifier).claimDailyLogin();
    if (!mounted || !result.ok) return;
    await showFeedback(context, result.message, ok: true);
  }

  void _openNext(BuildContext context, NextAction action) {
    final page = switch (action.kind) {
      NextActionKind.planBudget => const BudgetScreen(),
      NextActionKind.doQuests => const QuestsScreen(),
      NextActionKind.buyMandatory => const ShopScreen(),
      NextActionKind.saveMoney || NextActionKind.claimGoal =>
        const SavingsScreen(),
      NextActionKind.finishPeriod || NextActionKind.viewSummary =>
        const PeriodSummaryScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Нет профиля')));
    }

    // Для младших — отдельный «Talking Tom»-интерфейс с нижней панелью.
    if (profile.ageTrack == AgeTrack.junior) {
      return const JuniorPlayShell();
    }

    final content = ref.watch(contentProvider);
    final goal = content.maybeWhen(
      data: (data) {
        for (final g in GameEconomy.goalsForProfile(profile, data.goals)) {
          if (g.id == profile.selectedGoalId) return g;
        }
        return null;
      },
      orElse: () => null,
    );
    final next = GameEconomy.nextAction(profile, goal: goal);
    final story = Engagement.storyForPeriod(profile.period.index);
    final canSecret = GameEconomy.canClaimSecretOfDay(profile);

    final phaseLabel = switch (profile.period.phase) {
      PeriodPhase.planning => 'Составь план',
      PeriodPhase.playing => 'Играй и учись',
      PeriodPhase.summary => 'Смотри итог',
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Привет! 👋',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                  ),
                  Text(
                    profile.petName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [FinnyColors.purpleLight, FinnyColors.indigo],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: FinnyColors.purpleLight.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'УРОВЕНЬ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${profile.growthStage}',
                        style: const TextStyle(
                          color: FinnyColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Раздел для взрослого',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdultGateScreen()),
                  ),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(Icons.family_restroom_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      children: [
                        Text(
                          'Твой питомец ждёт тебя!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${story.title} · $phaseLabel',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.hook,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PetAvatar(
                          appearance: profile.appearance,
                          stage: profile.growthStage,
                          mood: profile.mood,
                          hunger: profile.hunger,
                          petName: profile.petName,
                          ownedItemIds: profile.ownedItemIds,
                          showLabel: false,
                          size: 160,
                          animate: true,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            'Нажми на ${profile.petName}!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                FinnyColors.purpleLight,
                                FinnyColors.indigo,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'стадия ${profile.growthStage} «${GameEconomy.stageTitle(profile.growthStage)}»  ·  ★ ${profile.stars}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          GameEconomy.stageProgressHint(profile),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.demoMode) ...[
                    const SizedBox(height: 10),
                    SoftCard(
                      color: FinnyColors.mint.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        'Демо: 5+ периодов подряд без ожидания. Хорошие серии растят стадию.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _HeroAction(
                    title: next.title,
                    subtitle: next.subtitle,
                    onTap: () async {
                      if (next.kind == NextActionKind.finishPeriod) {
                        final closed = await ref
                            .read(gameControllerProvider.notifier)
                            .finishPeriod();
                        if (!context.mounted) return;
                        if (closed.stageGrew) {
                          await showCelebration(
                            context,
                            title: 'Новая стадия!',
                            message: closed.feedback,
                          );
                        }
                        if (context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PeriodSummaryScreen(),
                            ),
                          );
                        }
                        return;
                      }
                      _openNext(context, next);
                    },
                  ),
                  if (canSecret) ...[
                    const SizedBox(height: 10),
                    SoftCard(
                      onTap: () async {
                        final result = await ref
                            .read(gameControllerProvider.notifier)
                            .claimSecretOfDay();
                        if (!context.mounted) return;
                        if (result.celebrate) {
                          await showCelebration(
                            context,
                            title: result.celebrateTitle ?? 'Секрет дня!',
                            message: result.message,
                            stars: result.earnedStars,
                          );
                        } else {
                          await showFeedback(
                            context,
                            result.message,
                            ok: result.ok,
                          );
                        }
                      },
                      color: FinnyColors.gold.withValues(alpha: 0.18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: const Row(
                        children: [
                          Text('✨', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Секрет дня — открой сюрприз!',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ],
                  if (profile.parentChallengeTarget != null) ...[
                    const SizedBox(height: 10),
                    SoftCard(
                      color: FinnyColors.mint.withValues(alpha: 0.15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Миссия от родителя: ${profile.parentChallengeSaved}/${profile.parentChallengeTarget}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: (profile.parentChallengeSaved /
                                      profile.parentChallengeTarget!)
                                  .clamp(0.0, 1.0),
                              minHeight: 8,
                              color: FinnyColors.mint,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  CollectionsCard(ownedItemIds: profile.ownedItemIds),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Баланс',
                          value: '${profile.balance}',
                          icon: Icons.payments_rounded,
                          color: FinnyColors.sun,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Копилка',
                          value: '${profile.savingsBalance}',
                          icon: Icons.savings_rounded,
                          color: FinnyColors.savings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Комбо',
                          value: '${profile.period.goodQuestStreak}',
                          icon: Icons.local_fire_department_rounded,
                          color: FinnyColors.coral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LearnProgressCard(
                    profile: profile,
                    goal: goal,
                    lessonsDone: content.maybeWhen(
                      data: (data) => GameEconomy.lessonsDoneCount(
                        profile,
                        data.lessons,
                      ),
                      orElse: () => 0,
                    ),
                    lessonsTotal: content.maybeWhen(
                      data: (data) => GameEconomy.lessonsForProfile(
                        profile,
                        data.lessons,
                      ).length,
                      orElse: () => 0,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LearnScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LearnScreen()),
                    ),
                    color: FinnyColors.purpleLight.withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: FinnyColors.glow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: FinnyColors.glow,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AgeLearnGuide.forTrack(profile.ageTrack)
                                    .headline,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                content.maybeWhen(
                                  data: (data) {
                                    final done = GameEconomy.lessonsDoneCount(
                                      profile,
                                      data.lessons,
                                    );
                                    final total = GameEconomy.lessonsForProfile(
                                      profile,
                                      data.lessons,
                                    ).length;
                                    return 'Уроки · $done/$total';
                                  },
                                  orElse: () => 'Короткие уроки под возраст',
                                ),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      children: [
                        StatBar(
                          label: 'Сытость',
                          value: profile.hunger,
                          color: FinnyColors.budget,
                          icon: Icons.restaurant_rounded,
                        ),
                        const SizedBox(height: 14),
                        StatBar(
                          label: 'Настроение',
                          value: profile.mood,
                          color: FinnyColors.sun,
                          icon: Icons.sentiment_satisfied_alt_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Навыки'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SkillChip(
                          theme: QuestTheme.budget,
                          level: profile.skills.levelFor(QuestTheme.budget),
                          xp: profile.skills.budgetXp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SkillChip(
                          theme: QuestTheme.savings,
                          level: profile.skills.levelFor(QuestTheme.savings),
                          xp: profile.skills.savingsXp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SkillChip(
                          theme: QuestTheme.purchases,
                          level: profile.skills.levelFor(QuestTheme.purchases),
                          xp: profile.skills.purchasesXp,
                        ),
                      ),
                    ],
                  ),
                  if (profile.lastFeedback.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SoftCard(
                      color: FinnyColors.gold.withValues(alpha: 0.12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: FinnyColors.gold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              profile.lastFeedback,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const SectionLabel('Что делать'),
                  const SizedBox(height: 12),
                  _BentoGrid(
                    profile: profile,
                    next: next,
                    onFinishPeriod: () async {
                      final closed = await ref
                          .read(gameControllerProvider.notifier)
                          .finishPeriod();
                      if (!context.mounted) return;
                      if (closed.stageGrew) {
                        await showCelebration(
                          context,
                          title: 'Новая стадия!',
                          message: closed.feedback,
                        );
                      }
                      if (context.mounted) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PeriodSummaryScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Справка'),
                        content: const Text(
                          '1) Составь план бюджета.\n'
                          '2) Выполни задания периода.\n'
                          '3) Купи нужное и пополни копилку.\n'
                          '4) Заверши период и сравни план с фактом.\n\n'
                          'Учёба — короткие уроки под возраст.\n'
                          'Звёзды и XP — за умные решения.\n'
                          'Комбо — серия правильных ответов подряд.',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Закрыть'),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.help_outline_rounded),
                    label: const Text('Справка: как играть'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FinnyColors.purpleLight,
              FinnyColors.indigo,
            ],
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: FinnyColors.glow,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сейчас важно',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: FinnyColors.mist, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoGrid extends StatelessWidget {
  const _BentoGrid({
    required this.profile,
    required this.next,
    required this.onFinishPeriod,
  });

  final PlayerProfile profile;
  final NextAction next;
  final VoidCallback onFinishPeriod;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.auto_stories_rounded,
                title: 'Учёба',
                subtitle: AgeLearnGuide.forTrack(profile.ageTrack).badge,
                accent: FinnyColors.mint,
                tall: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LearnScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 210,
                child: Column(
                  children: [
                    Expanded(
                      child: _BentoTile(
                        icon: Icons.pie_chart_rounded,
                        title: 'Бюджет',
                        subtitle: profile.period.phase == PeriodPhase.planning
                            ? 'Начни здесь'
                            : 'План готов',
                        accent: FinnyColors.budget,
                        highlighted:
                            profile.period.phase == PeriodPhase.planning,
                        fill: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BudgetScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _BentoTile(
                        icon: Icons.extension_rounded,
                        title: 'Задания',
                        subtitle: profile.period.activeQuestIds.isEmpty
                            ? 'По возрасту'
                            : '${profile.period.periodQuestsDone}/${profile.period.activeQuestIds.length}',
                        accent: FinnyColors.coral,
                        highlighted:
                            profile.period.phase == PeriodPhase.playing &&
                                !profile.period.periodQuestsComplete,
                        fill: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuestsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BentoTile(
                icon: Icons.storefront_rounded,
                title: 'Покупки',
                subtitle: 'Нужное и желаемое',
                accent: FinnyColors.purchases,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BentoTile(
                icon: Icons.savings_rounded,
                title: 'Копилка',
                subtitle: 'Цель и накопления',
                accent: FinnyColors.savings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavingsScreen()),
                ),
              ),
            ),
          ],
        ),
        if (profile.period.phase == PeriodPhase.playing) ...[
          const SizedBox(height: 10),
          _BentoTile(
            icon: Icons.flag_rounded,
            title: 'Завершить период',
            subtitle: 'Сравнить план и факт',
            accent: FinnyColors.forest,
            highlighted: next.kind == NextActionKind.finishPeriod,
            wide: true,
            onTap: onFinishPeriod,
          ),
        ],
        if (profile.period.phase == PeriodPhase.summary) ...[
          const SizedBox(height: 10),
          _BentoTile(
            icon: Icons.flag_rounded,
            title: 'Итог периода',
            subtitle: 'Посмотреть результат',
            accent: FinnyColors.forest,
            highlighted: true,
            wide: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PeriodSummaryScreen()),
            ),
          ),
        ],
      ],
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.highlighted = false,
    this.tall = false,
    this.wide = false,
    this.fill = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool highlighted;
  final bool tall;
  final bool wide;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final iconBox = fill ? 32.0 : 40.0;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: (tall || fill) ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(fill ? 12 : 14),
          ),
          child: Icon(icon, color: accent, size: fill ? 18 : 22),
        ),
        if (tall || fill) const Spacer(flex: 1) else const SizedBox(height: 10),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fill ? 14 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            height: 1.1,
          ),
        ),
        SizedBox(height: fill ? 1 : 2),
        Text(
          subtitle,
          maxLines: tall ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FinnyColors.mist,
            fontSize: fill ? 10 : 11,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ],
    );

    final card = SoftCard(
      onTap: onTap,
      radius: 22,
      padding: EdgeInsets.all(tall ? 16 : (fill ? 12 : 14)),
      color: highlighted
          ? FinnyColors.purpleLight.withValues(alpha: 0.28)
          : null,
      child: SizedBox(
        width: double.infinity,
        height: tall ? 210 : (fill ? double.infinity : null),
        child: body,
      ),
    );

    return card;
  }
}
