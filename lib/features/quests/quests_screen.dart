import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  QuestTheme? _themeFilter;
  bool _catalogMode = false;

  String _themeLabel(QuestTheme theme) => switch (theme) {
        QuestTheme.budget => 'Бюджет',
        QuestTheme.savings => 'Накопления',
        QuestTheme.purchases => 'Покупки',
      };

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(gameControllerProvider).value!;
    final allowed = profile.ageTrack.allowedDifficulties.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final locked = profile.period.phase != PeriodPhase.playing;

    return Scaffold(
      body: PlayBackground(
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final byId = {for (final q in data.quests) q.id: q};
            final periodQuests = profile.period.activeQuestIds
                .map((id) => byId[id])
                .whereType<Quest>()
                .toList();
            final periodDone = periodQuests
                .where(
                  (q) => GameEconomy.isQuestDoneThisPeriod(profile, q.id),
                )
                .length;

            final available = GameEconomy.questsForProfile(
              profile,
              data.quests,
              onlyTheme: _themeFilter,
            );

            final header = SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locked
                        ? 'Сначала подтверди план бюджета — тогда откроются задания периода.'
                        : 'Трек: ${profile.ageTrack.label}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locked
                        ? 'Задания учат бюджету, копилке и покупкам.'
                        : 'Период: $periodDone / ${periodQuests.isEmpty ? '—' : periodQuests.length} · ★ ${profile.stars} · комбо ${profile.period.goodQuestStreak}',
                  ),
                  if (!locked && periodQuests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: periodDone / periodQuests.length,
                        minHeight: 8,
                        color: FinnyColors.coral,
                        backgroundColor:
                            FinnyColors.coral.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Задания периода'),
                        selected: !_catalogMode,
                        onSelected: (_) =>
                            setState(() => _catalogMode = false),
                      ),
                      FilterChip(
                        label: const Text('Все уроки'),
                        selected: _catalogMode,
                        onSelected: (_) =>
                            setState(() => _catalogMode = true),
                      ),
                    ],
                  ),
                  if (_catalogMode) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Все темы'),
                          selected: _themeFilter == null,
                          onSelected: (_) =>
                              setState(() => _themeFilter = null),
                        ),
                        for (final t in QuestTheme.values)
                          FilterChip(
                            label: Text(_themeLabel(t)),
                            selected: _themeFilter == t,
                            onSelected: (_) =>
                                setState(() => _themeFilter = t),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );

            if (locked) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('Задания'),
                    backgroundColor:
                        FinnyColors.bg.withValues(alpha: 0.78),
                    surfaceTintColor: Colors.transparent,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        header,
                        const SizedBox(height: 24),
                        const Text(
                          'Подтверди план на экране «План бюджета», чтобы получить задания периода.',
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            }

            if (!_catalogMode) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('Задания'),
                    backgroundColor:
                        FinnyColors.bg.withValues(alpha: 0.78),
                    surfaceTintColor: Colors.transparent,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(child: header),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final quests = periodQuests.isEmpty
                              ? available.take(3).toList()
                              : periodQuests;
                          if (index >= quests.length) return null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QuestTile(
                              quest: quests[index],
                              profile: profile,
                              themeLabel: _themeLabel,
                            ),
                          );
                        },
                        childCount: (periodQuests.isEmpty
                            ? available.take(3).length
                            : periodQuests.length),
                      ),
                    ),
                  ),
                ],
              );
            }

            return DefaultTabController(
              length: allowed.length,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    backgroundColor:
                        FinnyColors.bg.withValues(alpha: 0.78),
                    surfaceTintColor: Colors.transparent,
                    title: const Text('Задания'),
                    bottom: TabBar(
                      tabs: [
                        for (final d in allowed) Tab(text: d.label),
                      ],
                    ),
                  ),
                ],
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: header,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          for (final difficulty in allowed)
                            _QuestList(
                              quests: GameEconomy.questsForProfile(
                                profile,
                                data.quests,
                                onlyDifficulty: difficulty,
                                onlyTheme: _themeFilter,
                              ),
                              profile: profile,
                              themeLabel: _themeLabel,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.quest,
    required this.profile,
    required this.themeLabel,
  });

  final Quest quest;
  final PlayerProfile profile;
  final String Function(QuestTheme) themeLabel;

  @override
  Widget build(BuildContext context) {
    final done = GameEconomy.isQuestDoneThisPeriod(profile, quest.id);
    final isPeriod = profile.period.activeQuestIds.contains(quest.id);
    return SoftCard(
      onTap: done
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuestDetailScreen(quest: quest),
                ),
              ),
      color: done
          ? FinnyColors.mint.withValues(alpha: 0.14)
          : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (done ? FinnyColors.mint : FinnyColors.coral)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.quiz_rounded,
              color: done ? FinnyColors.forest : FinnyColors.coral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${themeLabel(quest.theme)}'
                  '${isPeriod ? ' · период' : ' · практика'}'
                  '${done ? ' · выполнено' : (isPeriod ? ' · ★${quest.difficulty.starReward}' : ' · без монет')}',
                  style: TextStyle(color: FinnyColors.mist, fontSize: 13),
                ),
              ],
            ),
          ),
          DifficultyBadge(difficulty: quest.difficulty),
        ],
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  const _QuestList({
    required this.quests,
    required this.profile,
    required this.themeLabel,
  });

  final List<Quest> quests;
  final PlayerProfile profile;
  final String Function(QuestTheme) themeLabel;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'На этом уровне пока нет заданий с выбранным фильтром.',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _QuestTile(
            quest: quests[index],
            profile: profile,
            themeLabel: themeLabel,
          ),
        );
      },
    );
  }
}

class QuestDetailScreen extends ConsumerWidget {
  const QuestDetailScreen({super.key, required this.quest});

  final Quest quest;

  String _themeLabel(QuestTheme theme) => switch (theme) {
        QuestTheme.budget => 'Бюджет',
        QuestTheme.savings => 'Накопления',
        QuestTheme.purchases => 'Покупки',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(gameControllerProvider).value!;
    final done = GameEconomy.isQuestDoneThisPeriod(profile, quest.id);

    return Scaffold(
      body: PlayBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(quest.title),
              backgroundColor: FinnyColors.bg.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            DifficultyBadge(difficulty: quest.difficulty),
                            const SizedBox(width: 8),
                            Text(
                              _themeLabel(quest.theme),
                              style: TextStyle(color: FinnyColors.mist),
                            ),
                            const Spacer(),
                            Text(
                              '★ ${quest.difficulty.starReward} · XP ${quest.difficulty.xpReward}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (quest.tip.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FinnyColors.sheet,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: FinnyColors.sun,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    quest.tip,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          quest.prompt,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (done) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Задание уже выполнено в этом периоде.',
                            style: TextStyle(
                              color: FinnyColors.forest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!done)
                    ...quest.options.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          onTap: () async {
                            final result = await ref
                                .read(gameControllerProvider.notifier)
                                .answerQuest(quest, option);
                            if (!context.mounted) return;
                            await showFeedback(
                              context,
                              result.message,
                              ok: result.ok,
                              stars: result.earnedStars,
                              xp: result.earnedXp,
                              combo: result.combo,
                            );
                            if (!context.mounted) return;
                            if (result.ok) Navigator.pop(context);
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: FinnyColors.ink,
                              ),
                            ],
                          ),
                        ),
                      ),
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
