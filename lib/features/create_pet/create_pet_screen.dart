import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class CreatePetScreen extends ConsumerStatefulWidget {
  const CreatePetScreen({super.key});

  @override
  ConsumerState<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends ConsumerState<CreatePetScreen> {
  final _playerCtrl = TextEditingController(text: 'Саша');
  final _petCtrl = TextEditingController(text: 'Финни');
  int bodyIdx = 0;
  int colorIdx = 0;
  int accIdx = 0;
  AgeTrack ageTrack = AgeTrack.middle;

  @override
  void dispose() {
    _playerCtrl.dispose();
    _petCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(contentProvider);
    return Scaffold(
      body: PlayBackground(
        child: contentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка контента: $e')),
          data: (content) {
            final appearance = PetAppearance(
              body: content.bodies[bodyIdx],
              color: content.colors[colorIdx],
              accessory: content.accessories[accIdx],
            );
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text('Создай питомца'),
                  backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
                  surfaceTintColor: Colors.transparent,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      PetAvatar(appearance: appearance, stage: 1, size: 140),
                      const SizedBox(height: 8),
                      Text(
                        'Вариантов вида: ${content.petCombinations}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FinnyColors.mist),
                      ),
                      const SizedBox(height: 20),
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Сложность',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Выбери «попроще» или «посложнее» — без вопроса о возрасте. Задания подстроятся.',
                            ),
                            const SizedBox(height: 12),
                            ...AgeTrack.values.map((track) {
                              final selected = ageTrack == track;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: selected
                                      ? FinnyColors.purpleLight.withValues(alpha: 0.35)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        setState(() => ageTrack = track),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: selected
                                              ? FinnyColors.purpleBright
                                              : FinnyColors.line,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                track.difficultyLabel,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              DifficultyBadge(
                                                difficulty: switch (track) {
                                                  AgeTrack.junior =>
                                                    QuestDifficulty.easy,
                                                  AgeTrack.middle =>
                                                    QuestDifficulty.medium,
                                                  AgeTrack.senior =>
                                                    QuestDifficulty.hard,
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(track.description),
                                          Text(
                                            track.label,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.45),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _playerCtrl,
                        decoration: InputDecoration(
                          labelText: 'Твоё игровое имя',
                          filled: true,
                          fillColor: Color(0x14FFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _petCtrl,
                        decoration: InputDecoration(
                          labelText: 'Имя питомца',
                          filled: true,
                          fillColor: Color(0x14FFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SoftCard(
                        child: Column(
                          children: [
                            _ChoiceRow(
                              label: 'Форма',
                              values: content.bodies,
                              index: bodyIdx,
                              onChanged: (i) => setState(() => bodyIdx = i),
                            ),
                            _ChoiceRow(
                              label: 'Цвет',
                              values: content.colors,
                              index: colorIdx,
                              onChanged: (i) => setState(() => colorIdx = i),
                            ),
                            _ChoiceRow(
                              label: 'Аксессуар',
                              values: content.accessories,
                              index: accIdx,
                              onChanged: (i) => setState(() => accIdx = i),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () async {
                          await ref
                              .read(gameControllerProvider.notifier)
                              .createProfile(
                                playerName: _playerCtrl.text,
                                petName: _petCtrl.text,
                                appearance: appearance,
                                ageTrack: ageTrack,
                              );
                        },
                        child: const Text('Начать игру'),
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

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.index,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < values.length; i++)
              ChoiceChip(
                label: Text(values[i]),
                selected: index == i,
                onSelected: (_) => onChanged(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
