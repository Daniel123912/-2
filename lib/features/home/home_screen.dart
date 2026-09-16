import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../adult/adult_screen.dart';
import '../budget/budget_screen.dart';
import '../period/period_summary_screen.dart';
import '../quests/quests_screen.dart';
import '../savings/savings_screen.dart';
import '../shop/shop_screen.dart';
import '../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Нет профиля')));
    }

    final content = ref.watch(contentProvider);
    final goal = content.maybeWhen(
      data: (data) {
        for (final g in data.goals) {
          if (g.id == profile.selectedGoalId) return g;
        }
        return null;
      },
      orElse: () => null,
    );
    final next = GameEconomy.nextAction(profile, goal: goal);

    final phaseLabel = switch (profile.period.phase) {
      PeriodPhase.planning => 'Составь план',
      PeriodPhase.playing => 'Играй и учись',
      PeriodPhase.summary => 'Смотри итог',
    };

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: FinnyColors.cream.withValues(alpha: 0.92),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.petName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${profile.ageTrack.label} · период ${profile.period.index}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FinnyColors.mist,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Раздел для взрослого',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdultGateScreen()),
                  ),
                  icon: const Icon(Icons.family_restroom),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    padding: const EdgeInsets.all(18),
                    color: Colors.white.withValues(alpha: 0.92),
                    child: Column(
                      children: [
                        PetAvatar(
                          appearance: profile.appearance,
                          stage: profile.growthStage,
                          mood: profile.mood,
                          showLabel: false,
                          size: 132,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          phaseLabel,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Стадия ${profile.growthStage} · ★ ${profile.stars}',
                          style: TextStyle(color: FinnyColors.mist),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    onTap: () async {
                      if (next.kind == NextActionKind.finishPeriod) {
                        await ref
                            .read(gameControllerProvider.notifier)
                            .finishPeriod();
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
                    color: FinnyColors.sun.withValues(alpha: 0.22),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: FinnyColors.sun.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.flag_circle,
                              color: FinnyColors.forest),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Сейчас важно',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: FinnyColors.mist,
                                ),
                              ),
                              Text(
                                next.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                next.subtitle,
                                style: TextStyle(color: FinnyColors.mist),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: FinnyColors.mist),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Баланс',
                          value: '${profile.balance}',
                          icon: Icons.monetization_on,
                          color: FinnyColors.sun,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Копилка',
                          value: '${profile.savingsBalance}',
                          icon: Icons.savings,
                          color: FinnyColors.savings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Комбо',
                          value: '${profile.period.goodQuestStreak}',
                          icon: Icons.local_fire_department,
                          color: FinnyColors.coral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      children: [
                        StatBar(
                          label: 'Сытость',
                          value: profile.hunger,
                          color: FinnyColors.budget,
                          icon: Icons.restaurant,
                        ),
                        const SizedBox(height: 12),
                        StatBar(
                          label: 'Настроение',
                          value: profile.mood,
                          color: FinnyColors.sun,
                          icon: Icons.sentiment_satisfied_alt,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Навыки', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                      color: const Color(0xFFFFF8E8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              color: FinnyColors.forest),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              profile.lastFeedback,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text('Что делать', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _NavTile(
                    icon: Icons.pie_chart_rounded,
                    title: 'План бюджета',
                    subtitle: profile.period.phase == PeriodPhase.planning
                        ? 'Начни период отсюда'
                        : 'План уже подтверждён',
                    accent: FinnyColors.budget,
                    highlighted: profile.period.phase == PeriodPhase.planning,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BudgetScreen()),
                    ),
                  ),
                  _NavTile(
                    icon: Icons.extension_rounded,
                    title: 'Задания',
                    subtitle: profile.period.activeQuestIds.isEmpty
                        ? 'Уроки по возрасту и сложности'
                        : 'Период: ${profile.period.periodQuestsDone}/${profile.period.activeQuestIds.length}',
                    accent: FinnyColors.coral,
                    highlighted: profile.period.phase == PeriodPhase.playing &&
                        !profile.period.periodQuestsComplete,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuestsScreen()),
                    ),
                  ),
                  _NavTile(
                    icon: Icons.storefront_rounded,
                    title: 'Покупки',
                    subtitle: 'Нужное и желаемое',
                    accent: FinnyColors.purchases,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    ),
                  ),
                  _NavTile(
                    icon: Icons.savings_rounded,
                    title: 'Накопления',
                    subtitle: 'Цель и копилка',
                    accent: FinnyColors.savings,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavingsScreen()),
                    ),
                  ),
                  if (profile.period.phase == PeriodPhase.playing)
                    _NavTile(
                      icon: Icons.flag_rounded,
                      title: 'Завершить период',
                      subtitle: 'Сравнить план и факт',
                      accent: FinnyColors.forest,
                      highlighted: next.kind == NextActionKind.finishPeriod,
                      onTap: () async {
                        await ref
                            .read(gameControllerProvider.notifier)
                            .finishPeriod();
                        if (context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PeriodSummaryScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  if (profile.period.phase == PeriodPhase.summary)
                    _NavTile(
                      icon: Icons.flag_rounded,
                      title: 'Итог периода',
                      subtitle: 'Посмотреть результат',
                      accent: FinnyColors.forest,
                      highlighted: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PeriodSummaryScreen(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Справка'),
                        content: const Text(
                          '1) Составь план бюджета.\n'
                          '2) Выполни задания периода (ошибку можно исправить).\n'
                          '3) Купи нужное и пополни копилку по плану.\n'
                          '4) Заверши период и сравни план с фактом.\n\n'
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
                    icon: const Icon(Icons.help_outline),
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: FinnyColors.mist, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: onTap,
        color: highlighted ? FinnyColors.sky : Colors.white,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: FinnyColors.mist, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FinnyColors.mist),
          ],
        ),
      ),
    );
  }
}
