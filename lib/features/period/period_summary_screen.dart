import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class PeriodSummaryScreen extends ConsumerWidget {
  const PeriodSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value!;
    final plan = profile.period.plan;
    final fact = profile.period.fact;
    final canAdvance = GameEconomy.canAdvancePeriod(profile);
    final cooldown = GameEconomy.periodCooldownLeft(profile);
    final mins = cooldown?.inMinutes.clamp(1, 9999) ?? 0;

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(
                Engagement.storyForPeriod(profile.period.index).title,
              ),
              backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    color: profile.period.feedback.contains('Как поправить')
                        ? FinnyColors.coral.withValues(alpha: 0.2)
                        : FinnyColors.sky,
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
                        _Row('Подарить', plan.gift, fact.giftSpent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PetAvatar(
                              appearance: profile.appearance,
                              stage: profile.growthStage,
                              mood: profile.mood,
                              hunger: profile.hunger,
                              petName: profile.petName,
                              ownedItemIds: profile.ownedItemIds,
                              size: 72,
                              showLabel: false,
                              animate: false,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Стадия ${profile.growthStage} «${GameEconomy.stageTitle(profile.growthStage)}»',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(GameEconomy.stageProgressHint(profile)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('★ ${profile.stars} · навыки XP ${profile.skills.totalXp}'),
                        Text(
                          'Задания периода: ${profile.period.periodQuestsDone}/${profile.period.activeQuestIds.isEmpty ? profile.period.completedQuestIds.length : profile.period.activeQuestIds.length}',
                        ),
                        Text(
                          'Сытость: ${profile.hunger} · Настроение: ${profile.mood}',
                        ),
                        if (profile.comboBest > 0)
                          Text('Лучшее комбо: ×${profile.comboBest}'),
                        if (profile.demoMode)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Демо: следующий период без ожидания.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CollectionsCard(ownedItemIds: profile.ownedItemIds),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: canAdvance
                        ? () async {
                            await ref
                                .read(gameControllerProvider.notifier)
                                .nextPeriod();
                            if (context.mounted) Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      canAdvance
                          ? 'Следующий период'
                          : 'Подождите ~$mins мин (или включите демо)',
                    ),
                  ),
                  if (!canAdvance) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(gameControllerProvider.notifier)
                            .setDemoMode(true);
                      },
                      child: const Text('Включить демо-режим'),
                    ),
                  ],
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
