import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../domain/models.dart';
import '../../state/game_controller.dart';
import '../adult/adult_screen.dart';
import '../budget/budget_screen.dart';
import '../learn/learn_screen.dart';
import '../period/period_summary_screen.dart';
import '../quests/quests_screen.dart';
import '../savings/savings_screen.dart';
import '../shop/shop_screen.dart';
import '../widgets/common.dart';

/// Игровой «Talking Tom»-шелл только для младшего возраста:
/// большая комната с питомцем + яркая нижняя панель.
class JuniorPlayShell extends ConsumerStatefulWidget {
  const JuniorPlayShell({super.key});

  @override
  ConsumerState<JuniorPlayShell> createState() => _JuniorPlayShellState();
}

class _JuniorPlayShellState extends ConsumerState<JuniorPlayShell> {
  var _tab = 0;
  var _loginClaimed = false;
  var _speech = 'Нажми на меня!';

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
    setState(() => _speech = result.message);
  }

  void _onSpeak(String text) {
    setState(() => _speech = text);
  }

  Future<void> _claimSecret() async {
    final result =
        await ref.read(gameControllerProvider.notifier).claimSecretOfDay();
    if (!mounted) return;
    setState(() => _speech = result.message);
    if (result.celebrate) {
      await showCelebration(
        context,
        title: result.celebrateTitle ?? 'Секрет дня!',
        message: result.message,
        stars: result.earnedStars,
      );
    } else {
      await showFeedback(context, result.message, ok: result.ok);
    }
  }

  Future<void> _runNext(NextAction next) async {
    if (next.kind == NextActionKind.finishPeriod) {
      final closed =
          await ref.read(gameControllerProvider.notifier).finishPeriod();
      if (!mounted) return;
      if (closed.stageGrew) {
        await showCelebration(
          context,
          title: 'Новая стадия!',
          message: closed.feedback,
        );
      } else if (closed.softFail) {
        setState(() => _speech = closed.feedback);
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PeriodSummaryScreen()),
      );
      return;
    }
    if (next.kind == NextActionKind.viewSummary) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PeriodSummaryScreen()),
      );
      return;
    }
    setState(() {
      _tab = switch (next.kind) {
        NextActionKind.planBudget => 4,
        NextActionKind.doQuests => 1,
        NextActionKind.buyMandatory => 2,
        NextActionKind.saveMoney || NextActionKind.claimGoal => 3,
        _ => 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(gameControllerProvider).value;
    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Нет профиля')));
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

    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: _tab,
        children: [
          _JuniorPetRoom(
            profile: profile,
            next: next,
            story: story,
            bubbleText: _speech,
            canSecret: canSecret,
            onSpeak: _onSpeak,
            onSecret: _claimSecret,
            onNext: () => _runNext(next),
            onLearn: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LearnScreen()),
            ),
            onAdult: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdultGateScreen()),
            ),
          ),
          const QuestsScreen(),
          const ShopScreen(),
          const SavingsScreen(),
          const BudgetScreen(),
        ],
      ),
      bottomNavigationBar: _JuniorDock(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _JuniorPetRoom extends StatelessWidget {
  const _JuniorPetRoom({
    required this.profile,
    required this.next,
    required this.story,
    required this.bubbleText,
    required this.canSecret,
    required this.onSpeak,
    required this.onSecret,
    required this.onNext,
    required this.onLearn,
    required this.onAdult,
  });

  final PlayerProfile profile;
  final NextAction next;
  final PeriodStory story;
  final String bubbleText;
  final bool canSecret;
  final ValueChanged<String> onSpeak;
  final VoidCallback onSecret;
  final VoidCallback onNext;
  final VoidCallback onLearn;
  final VoidCallback onAdult;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 88;
    final challenge = profile.parentChallengeTarget;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5B21B6),
            Color(0xFF7C3AED),
            Color(0xFFDB2777),
            Color(0xFFFBBF24),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 90,
            left: -30,
            child: _Cloud(size: 120, opacity: 0.18),
          ),
          Positioned(
            top: 140,
            right: -20,
            child: _Cloud(size: 90, opacity: 0.14),
          ),
          Positioned(
            bottom: bottomPad + 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
              child: Column(
                children: [
                  Row(
                    children: [
                      _HudPill(
                        icon: Icons.payments_rounded,
                        label: '${profile.balance}',
                        color: const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 8),
                      _HudPill(
                        icon: Icons.savings_rounded,
                        label: '${profile.savingsBalance}',
                        color: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 8),
                      _HudPill(
                        icon: Icons.star_rounded,
                        label: '${profile.stars}',
                        color: const Color(0xFFF472B6),
                      ),
                      const Spacer(),
                      if (canSecret) ...[
                        _RoundIconButton(
                          icon: Icons.auto_awesome_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: onSecret,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _RoundIconButton(
                        icon: Icons.auto_stories_rounded,
                        color: const Color(0xFF34D399),
                        onTap: onLearn,
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.family_restroom_rounded,
                        color: Colors.white24,
                        onTap: onAdult,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${story.title}: ${story.hook}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (challenge != null) ...[
                    const SizedBox(height: 8),
                    _ChallengeBar(
                      saved: profile.parentChallengeSaved,
                      target: challenge,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatFace(
                          emoji: '🍽️',
                          label: 'Сытость',
                          value: profile.hunger,
                          color: const Color(0xFF2DD4BF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatFace(
                          emoji: '😊',
                          label: 'Настрой',
                          value: profile.mood,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _SpeechBubble(text: bubbleText),
                  const SizedBox(height: 8),
                  PetAvatar(
                    appearance: profile.appearance,
                    stage: profile.growthStage,
                    mood: profile.mood,
                    hunger: profile.hunger,
                    petName: profile.petName,
                    ownedItemIds: profile.ownedItemIds,
                    size: 180,
                    showLabel: false,
                    animate: true,
                    onSpeak: onSpeak,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.petName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                  Text(
                    'стадия ${profile.growthStage} · ★ ${profile.stars}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  _PlayCta(
                    title: next.title,
                    subtitle: next.subtitle,
                    onTap: onNext,
                  ),
                  const SizedBox(height: 10),
                  _LearnInvite(onTap: onLearn),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeBar extends StatelessWidget {
  const _ChallengeBar({required this.saved, required this.target});

  final int saved;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF34D399)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Миссия от родителя: $saved/$target',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0),
              minHeight: 8,
              color: const Color(0xFF34D399),
              backgroundColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF4C1D95),
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

class _PlayCta extends StatelessWidget {
  const _PlayCta({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A3D), Color(0xFFFF4D8D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D8D).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Сейчас сделай это',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearnInvite extends StatelessWidget {
  const _LearnInvite({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Школа Финни',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Поиграть и поучиться вместе',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _StatFace extends StatelessWidget {
  const _StatFace({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 100)) / 100,
              minHeight: 8,
              backgroundColor: Colors.black26,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size * 0.55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}

class _JuniorDock extends StatelessWidget {
  const _JuniorDock({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = <({IconData icon, String label, Color color})>[
    (icon: Icons.home_rounded, label: 'Дом', color: Color(0xFFA78BFA)),
    (icon: Icons.extension_rounded, label: 'Квесты', color: Color(0xFFF472B6)),
    (icon: Icons.storefront_rounded, label: 'Магазин', color: Color(0xFFFBBF24)),
    (icon: Icons.savings_rounded, label: 'Копилка', color: Color(0xFF38BDF8)),
    (icon: Icons.pie_chart_rounded, label: 'План', color: Color(0xFF34D399)),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 8 + bottom * 0.35),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: const Color(0xFF2E1065),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _DockItem(
                  icon: _items[i].icon,
                  label: _items[i].label,
                  color: _items[i].color,
                  selected: index == i,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              width: selected ? 46 : 38,
              height: selected ? 46 : 38,
              decoration: BoxDecoration(
                color: selected ? color : color.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : color,
                size: selected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
