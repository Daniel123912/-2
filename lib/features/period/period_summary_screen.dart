import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';

class PeriodSummaryScreen extends ConsumerWidget {
  const PeriodSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value!;
    final plan = profile.period.plan;
    final fact = profile.period.fact;

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text('Итог периода ${profile.period.index}'),
              backgroundColor: FinnyColors.cream.withValues(alpha: 0.95),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    color: FinnyColors.sky,
                    child: Text(
                      profile.period.feedback.isEmpty
                          ? profile.lastFeedback
                          : profile.period.feedback,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'План и факт',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _Row('Обязательное', plan.mandatory, fact.mandatorySpent),
                        _Row('Желаемое', plan.optional, fact.optionalSpent),
                        _Row('Накопления', plan.savings, fact.saved),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Стадия питомца: ${profile.growthStage}'),
                        Text('★ ${profile.stars} · навыки XP ${profile.skills.totalXp}'),
                        Text(
                          'Задания периода: ${profile.period.periodQuestsDone}/${profile.period.activeQuestIds.isEmpty ? profile.period.completedQuestIds.length : profile.period.activeQuestIds.length}',
                        ),
                        Text(
                          'Сытость: ${profile.hunger} · Настроение: ${profile.mood}',
                        ),
                        if (profile.comboBest > 0)
                          Text('Лучшее комбо: ×${profile.comboBest}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(gameControllerProvider.notifier)
                          .nextPeriod();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Следующий период'),
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.plan, this.fact);

  final String label;
  final int plan;
  final int fact;

  @override
  Widget build(BuildContext context) {
    final ok = (fact - plan).abs() <= 10;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text('план $plan'),
          const SizedBox(width: 12),
          Text(
            'факт $fact',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ok ? FinnyColors.forest : FinnyColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}
