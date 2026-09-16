import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(gameControllerProvider).value!;
    final plan = profile.period.plan;
    final fact = profile.period.fact;

    return Scaffold(
      body: PlayBackground(
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final mandatory =
                data.items.where((e) => e.kind == ExpenseKind.mandatory);
            final optional =
                data.items.where((e) => e.kind == ExpenseKind.optional);

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text('Покупки'),
                  backgroundColor: FinnyColors.cream.withValues(alpha: 0.95),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Баланс: ${profile.balance}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.period.phase == PeriodPhase.playing
                                  ? 'Сначала закрой нужное по плану, желаемое — по возможности.'
                                  : 'Покупки откроются после подтверждения плана.',
                            ),
                            if (plan.total > 0) ...[
                              const SizedBox(height: 12),
                              _PlanBar(
                                label: 'Обязательное',
                                plan: plan.mandatory,
                                fact: fact.mandatorySpent,
                                color: FinnyColors.budget,
                              ),
                              const SizedBox(height: 8),
                              _PlanBar(
                                label: 'Желаемое',
                                plan: plan.optional,
                                fact: fact.optionalSpent,
                                color: FinnyColors.purchases,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Обязательное',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...mandatory.map((item) => _ItemCard(item: item)),
                      const SizedBox(height: 12),
                      Text('Желаемое',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...optional.map((item) => _ItemCard(item: item)),
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

class _PlanBar extends StatelessWidget {
  const _PlanBar({
    required this.label,
    required this.plan,
    required this.fact,
    required this.color,
  });

  final String label;
  final int plan;
  final int fact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = plan <= 0 ? 0.0 : (fact / plan).clamp(0.0, 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: факт $fact / план $plan'),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio > 1 ? 1 : ratio,
            minHeight: 10,
            color: fact > plan ? FinnyColors.coral : color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kindLabel =
        item.kind == ExpenseKind.mandatory ? 'Обязательное' : 'Желаемое';
    final accent = item.kind == ExpenseKind.mandatory
        ? FinnyColors.budget
        : FinnyColors.purchases;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.price}',
                    style: const TextStyle(
                      color: FinnyColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('$kindLabel · ${item.effectHint}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(120, 44),
                  backgroundColor: accent,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(item.name),
                      content: Text(
                        'Купить за ${item.price}? Категория: $kindLabel.\n${item.effectHint}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Купить'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  final result =
                      await ref.read(gameControllerProvider.notifier).buy(item);
                  if (context.mounted) {
                    await showFeedback(context, result.message, ok: result.ok);
                  }
                },
                child: const Text('Купить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
