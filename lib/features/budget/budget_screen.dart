import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  double? mandatory;
  double? optional;
  double? savings;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(gameControllerProvider).value!;
    final max = profile.balance.toDouble().clamp(20.0, 300.0).toDouble();
    final suggested = GameEconomy.recommendedPlan(profile);
    final m = mandatory ??
        (profile.period.plan.total > 0
            ? profile.period.plan.mandatory.toDouble()
            : suggested.mandatory.toDouble());
    final o = optional ??
        (profile.period.plan.total > 0
            ? profile.period.plan.optional.toDouble()
            : suggested.optional.toDouble());
    final s = savings ??
        (profile.period.plan.total > 0
            ? profile.period.plan.savings.toDouble()
            : suggested.savings.toDouble());
    final total = m.round() + o.round() + s.round();
    final left = profile.balance - total;
    final locked = profile.period.phase != PeriodPhase.planning;

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('План бюджета'),
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
                          'Доступно: ${profile.balance} монет',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          locked
                              ? 'План уже подтверждён. Сравни его с покупками в итоге периода.'
                              : 'Распредели деньги до начала периода: нужное, желаемое, копилка. После подтверждения откроются задания.',
                        ),
                      ],
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        final plan = GameEconomy.recommendedPlan(profile);
                        setState(() {
                          mandatory = plan.mandatory.toDouble();
                          optional = plan.optional.toDouble();
                          savings = plan.savings.toDouble();
                        });
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Подставить умный план'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Column(
                      children: [
                        _SliderBlock(
                          label: 'Обязательное',
                          value: m.clamp(0.0, max).toDouble(),
                          max: max,
                          color: FinnyColors.budget,
                          enabled: !locked,
                          onChanged: (v) => setState(() => mandatory = v),
                        ),
                        _SliderBlock(
                          label: 'Желаемое',
                          value: o.clamp(0.0, max).toDouble(),
                          max: max,
                          color: FinnyColors.purchases,
                          enabled: !locked,
                          onChanged: (v) => setState(() => optional = v),
                        ),
                        _SliderBlock(
                          label: 'Накопления',
                          value: s.clamp(0.0, max).toDouble(),
                          max: max,
                          color: FinnyColors.savings,
                          enabled: !locked,
                          onChanged: (v) => setState(() => savings = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    color: left < 0
                        ? FinnyColors.coral.withValues(alpha: 0.15)
                        : FinnyColors.sky,
                    child: Text(
                      'В плане: $total · Остаток: $left',
                      style: TextStyle(
                        fontSize: 18,
                        color: left < 0
                            ? Colors.red.shade700
                            : FinnyColors.forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!locked)
                    FilledButton(
                      onPressed: () async {
                        final plan = BudgetPlan(
                          mandatory: m.round(),
                          optional: o.round(),
                          savings: s.round(),
                        );
                        final result = await ref
                            .read(gameControllerProvider.notifier)
                            .confirmBudget(plan);
                        if (context.mounted) {
                          await showFeedback(context, result.message,
                              ok: result.ok);
                          if (result.ok) Navigator.pop(context);
                        }
                      },
                      child: const Text('Подтвердить план'),
                    ),
                  if (locked) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'План: обяз. ${profile.period.plan.mandatory}, жел. ${profile.period.plan.optional}, копилка ${profile.period.plan.savings}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Факт: обяз. ${profile.period.fact.mandatorySpent}, жел. ${profile.period.fact.optionalSpent}, копилка ${profile.period.fact.saved}',
                          ),
                          if (profile.period.activeQuestIds.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Задания периода: ${profile.period.periodQuestsDone}/${profile.period.activeQuestIds.length}',
                            ),
                          ],
                        ],
                      ),
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

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.color,
    required this.max,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final Color color;
  final double max;

  @override
  Widget build(BuildContext context) {
    final divisions = (max / 5).round().clamp(4, 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ${value.round()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, max),
          max: max,
          divisions: divisions,
          activeColor: color,
          label: '${value.round()}',
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}
