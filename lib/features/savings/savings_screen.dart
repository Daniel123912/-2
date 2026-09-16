import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(gameControllerProvider).value!;
    final canPlay = profile.period.phase == PeriodPhase.playing;

    return Scaffold(
      body: PlayBackground(
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            SavingsGoal? goal;
            for (final g in data.goals) {
              if (g.id == profile.selectedGoalId) {
                goal = g;
                break;
              }
            }
            final left = GameEconomy.remainingToGoal(profile, goal);
            final eta = goal == null
                ? null
                : GameEconomy.estimatedPeriodsToGoal(profile, goal);
            final canClaim =
                goal != null && profile.savingsBalance >= goal.cost;
            final planLeft = (profile.period.plan.savings -
                    profile.period.fact.saved)
                .clamp(0, profile.balance);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text('Накопления'),
                  backgroundColor: FinnyColors.cream.withValues(alpha: 0.95),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'В копилке: ${profile.savingsBalance} монет',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (goal != null) ...[
                              Text('Цель: ${goal.name} (${goal.cost})'),
                              Text(
                                canClaim
                                    ? 'Хватает на цель — можно забрать!'
                                    : 'Осталось: $left',
                              ),
                              if (eta != null && !canClaim)
                                Text(
                                  'При ~15 монетах за период: около $eta периодов',
                                  style: TextStyle(color: FinnyColors.mist),
                                ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: (profile.savingsBalance / goal.cost)
                                      .clamp(0, 1),
                                  minHeight: 14,
                                  color: FinnyColors.savings,
                                  backgroundColor:
                                      FinnyColors.savings.withValues(alpha: 0.15),
                                ),
                              ),
                            ] else
                              const Text('Выбери цель ниже.'),
                            if (canPlay && profile.period.plan.savings > 0) ...[
                              const SizedBox(height: 10),
                              Text(
                                'План периода: ${profile.period.fact.saved} / ${profile.period.plan.savings}',
                                style: TextStyle(color: FinnyColors.mist),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (canClaim && goal != null) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            final result = await ref
                                .read(gameControllerProvider.notifier)
                                .claimGoal(goal!);
                            if (context.mounted) {
                              await showFeedback(
                                context,
                                result.message,
                                ok: result.ok,
                                stars: result.earnedStars,
                              );
                            }
                          },
                          icon: const Icon(Icons.celebration),
                          label: Text('Забрать «${goal.name}»'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text('Цели',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...data.goals.map(
                        (g) {
                          final selected = profile.selectedGoalId == g.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SoftCard(
                              onTap: () => ref
                                  .read(gameControllerProvider.notifier)
                                  .selectGoal(g.id),
                              color: selected ? FinnyColors.sky : Colors.white,
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: FinnyColors.savings,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text('${g.description} · ${g.cost} монет'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        canPlay
                            ? 'Пополнить копилку'
                            : 'Пополнение доступно после плана бюджета',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final amount in [10, 15, 20, if (planLeft > 0 && planLeft != 10 && planLeft != 15 && planLeft != 20) planLeft])
                            FilledButton(
                              onPressed: !canPlay
                                  ? null
                                  : () async {
                                      final result = await ref
                                          .read(gameControllerProvider.notifier)
                                          .saveToGoal(amount);
                                      if (context.mounted) {
                                        await showFeedback(
                                          context,
                                          result.message,
                                          ok: result.ok,
                                        );
                                      }
                                    },
                              child: Text('+$amount'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          final warn = await ref
                              .read(gameControllerProvider.notifier)
                              .withdraw(15, confirmed: false);
                          if (!context.mounted) return;
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Снять из копилки?'),
                              content: Text(warn.message),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Нет'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Да, снять'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            final result = await ref
                                .read(gameControllerProvider.notifier)
                                .withdraw(15, confirmed: true);
                            if (context.mounted) {
                              await showFeedback(context, result.message,
                                  ok: result.ok);
                            }
                          }
                        },
                        child: const Text('Снять 15 из копилки'),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
