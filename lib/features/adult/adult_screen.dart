import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';

class AdultGateScreen extends StatefulWidget {
  const AdultGateScreen({super.key});

  @override
  State<AdultGateScreen> createState() => _AdultGateScreenState();
}

class _AdultGateScreenState extends State<AdultGateScreen> {
  late final int a;
  late final int b;
  final _ctrl = TextEditingController();
  String? error;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    a = 7 + rnd.nextInt(8);
    b = 3 + rnd.nextInt(7);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Раздел для взрослого'),
              backgroundColor: FinnyColors.cream.withValues(alpha: 0.95),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Реши пример, чтобы продолжить.',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$a + $b = ?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelText: 'Ответ',
                          errorText: error,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          if (int.tryParse(_ctrl.text.trim()) == a + b) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AdultPanelScreen(),
                              ),
                            );
                          } else {
                            setState(() => error = 'Неверный ответ');
                          }
                        },
                        child: const Text('Войти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdultPanelScreen extends ConsumerWidget {
  const AdultPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value;

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Прогресс и настройки'),
              backgroundColor: FinnyColors.cream.withValues(alpha: 0.95),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    child: const Text(
                      'Цели приложения: научить планировать бюджет, различать нужное и желаемое, копить на цель. Задания делятся по возрасту и сложности.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (profile != null) ...[
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Игрок: ${profile.playerName}'),
                          Text('Питомец: ${profile.petName}'),
                          Text(
                            'Периодов завершено: ${profile.totalPeriodsCompleted}',
                          ),
                          Text(
                            'Заданий выполнено: ${profile.completedQuestIds.length}',
                          ),
                          Text('Стадия роста: ${profile.growthStage}'),
                          Text('★ ${profile.stars} · XP ${profile.skills.totalXp}'),
                          Text(
                            'Навыки: бюджет ур.${profile.skills.levelFor(QuestTheme.budget)}, '
                            'копилка ур.${profile.skills.levelFor(QuestTheme.savings)}, '
                            'покупки ур.${profile.skills.levelFor(QuestTheme.purchases)}',
                          ),
                          Text('Лучшее комбо: ${profile.comboBest}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Уровень обучения ребёнка',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          ...AgeTrack.values.map(
                            (track) => RadioListTile<AgeTrack>(
                              contentPadding: EdgeInsets.zero,
                              value: track,
                              groupValue: profile.ageTrack,
                              title: Text('${track.label} · ${track.shortLabel}'),
                              subtitle: Text(track.description),
                              onChanged: (v) {
                                if (v != null) {
                                  ref
                                      .read(gameControllerProvider.notifier)
                                      .setAgeTrack(v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Демо-режим'),
                      subtitle: const Text(
                        'Периоды идут подряд без ожидания календарных сроков.',
                      ),
                      value: profile.demoMode,
                      onChanged: (v) => ref
                          .read(gameControllerProvider.notifier)
                          .setDemoMode(v),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Сбросить профиль?'),
                          content: const Text(
                            'Тестовый профиль вернётся к исходному состоянию. Прогресс будет удалён.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Сбросить'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref
                            .read(gameControllerProvider.notifier)
                            .resetProfile();
                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      }
                    },
                    child: const Text('Сбросить тестовый профиль'),
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
