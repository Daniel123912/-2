import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/economy.dart';
import '../../domain/engagement.dart';
import '../../domain/models.dart';
import '../../theme/app_theme.dart';

class PetAvatar extends StatefulWidget {
  const PetAvatar({
    super.key,
    required this.appearance,
    required this.stage,
    this.size = 120,
    this.showLabel = true,
    this.mood = 70,
    this.hunger = 70,
    this.animate = true,
    this.ownedItemIds = const [],
    this.petName = 'Финни',
    this.onTap,
    this.onSpeak,
  });

  final PetAppearance appearance;
  final int stage;
  final double size;
  final bool showLabel;
  final int mood;
  final int hunger;
  final bool animate;
  final List<String> ownedItemIds;
  final String petName;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSpeak;

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar> with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _wiggle;
  late final AnimationController _jump;
  bool _showHeart = false;
  bool _showTear = false;

  Color get _color {
    return switch (widget.appearance.color) {
      'серый' => const Color(0xFF94A3B8),
      'пятнистый' => FinnyColors.gold,
      _ => FinnyColors.purpleBright,
    };
  }

  IconData get _bodyIcon {
    return switch (widget.appearance.body) {
      'пушистый' => Icons.pets_rounded,
      'длинный' => Icons.cruelty_free_rounded,
      _ => Icons.emoji_nature_rounded,
    };
  }

  String get _accessoryLabel {
    return switch (widget.appearance.accessory) {
      'шарфик' => 'Ш',
      'очки' => 'О',
      _ => 'Б',
    };
  }

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _jump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    if (widget.animate) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PetAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_float.isAnimating) {
      _float.repeat(reverse: true);
    } else if (!widget.animate && _float.isAnimating) {
      _float.stop();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _wiggle.dispose();
    _jump.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final speech = Engagement.petTapSpeech(
      petName: widget.petName,
      hunger: widget.hunger,
      mood: widget.mood,
    );
    widget.onSpeak?.call(speech);
    widget.onTap?.call();

    final sad = widget.hunger < 35 || widget.mood < 40;
    setState(() {
      _showHeart = !sad;
      _showTear = sad;
    });
    if (sad) {
      await _wiggle.forward(from: 0);
    } else {
      await _jump.forward(from: 0);
      await _wiggle.forward(from: 0);
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _showHeart = false;
        _showTear = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage.clamp(1, 3);
    final scale = switch (stage) {
      1 => 0.82,
      2 => 1.0,
      _ => 1.14,
    };
    final floatAmp = widget.mood < 40 ? 5.0 : (stage == 3 ? 12.0 : 10.0);
    final stageLabel = switch (stage) {
      1 => 'Малыш',
      2 => 'Растущий',
      _ => 'Чемпион',
    };
    final gradients = switch (stage) {
      1 => const [
          Color(0xFFC4B5FD),
          Color(0xFF8B5CF6),
          Color(0xFF6D28D9),
        ],
      2 => const [
          Color(0xFFA78BFA),
          Color(0xFF7C3AED),
          Color(0xFF5B21B6),
        ],
      _ => const [
          Color(0xFFFDE68A),
          Color(0xFFA78BFA),
          Color(0xFF7C3AED),
          Color(0xFF4C1D95),
        ],
    };
    final ringColor = switch (stage) {
      1 => const Color(0xFFDDD6FE),
      2 => FinnyColors.sky,
      _ => FinnyColors.gold,
    };
    final bodySize = switch (stage) {
      1 => widget.size * 0.38,
      2 => widget.size * 0.44,
      _ => widget.size * 0.5,
    };
    final cosmetics = Engagement.visualsFor(widget.ownedItemIds);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: SizedBox(
            width: widget.size + 40,
            height: widget.size + 40,
            child: AnimatedBuilder(
              animation: Listenable.merge([_float, _wiggle, _jump]),
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_float.value);
                final dy = widget.animate ? (t * 2 - 1) * floatAmp : 0.0;
                final rot = widget.animate ? (t * 2 - 1) * 0.04 : 0.0;
                final w = _wiggle.value;
                final wiggleRot =
                    (w < 0.5 ? w * 2 : (1 - w) * 2) * 0.12;
                final wiggleScale = 1 + (w < 0.5 ? w : 1 - w) * 0.08;
                final j = Curves.easeOutBack.transform(_jump.value);
                final jumpY = -28 * (j < 0.5 ? j * 2 : (1 - j) * 2);
                return Transform.translate(
                  offset: Offset(0, dy + jumpY),
                  child: Transform.rotate(
                    angle: rot +
                        (wiggleRot *
                            (w < 0.25 || (w > 0.5 && w < 0.75) ? -1 : 1)),
                    child: Transform.scale(
                      scale: scale * wiggleScale,
                      child: child,
                    ),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  for (final c in cosmetics)
                    if (c.slot == CosmeticSlot.room)
                      Positioned(
                        left: 0,
                        top: widget.size * 0.05,
                        child: Text(
                          c.emoji,
                          style: TextStyle(fontSize: widget.size * 0.22),
                        ),
                      ),
                  if (stage >= 2)
                    Container(
                      width: widget.size + (stage == 3 ? 28 : 16),
                      height: widget.size + (stage == 3 ? 28 : 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ringColor.withValues(alpha: 0.55),
                          width: stage == 3 ? 3.5 : 2,
                        ),
                        boxShadow: stage == 3
                            ? [
                                BoxShadow(
                                  color: FinnyColors.gold.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  if (stage == 3) ...[
                    Positioned(
                      left: 4,
                      child: Icon(
                        Icons.flare_rounded,
                        size: widget.size * 0.22,
                        color: FinnyColors.gold.withValues(alpha: 0.85),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      child: Icon(
                        Icons.flare_rounded,
                        size: widget.size * 0.22,
                        color: FinnyColors.gold.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradients,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (stage == 3
                                  ? FinnyColors.gold
                                  : FinnyColors.purpleLight)
                              .withValues(alpha: 0.55),
                          blurRadius: stage == 3 ? 42 : 36,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: widget.size * (stage == 1 ? 0.62 : 0.72),
                          height: widget.size * (stage == 1 ? 0.5 : 0.58),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEDE9FE)
                                .withValues(alpha: stage == 1 ? 0.45 : 0.35),
                          ),
                        ),
                        Icon(
                          stage == 1
                              ? Icons.child_care_rounded
                              : stage == 2
                                  ? _bodyIcon
                                  : Icons.workspace_premium_rounded,
                          size: bodySize,
                          color: Colors.white,
                        ),
                        if (stage >= 2)
                          Positioned(
                            top: widget.size * 0.06,
                            child: Container(
                              width: widget.size * 0.24,
                              height: widget.size * 0.24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFDE68A),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: FinnyColors.goldDark
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                stage == 3 ? '★' : '₽',
                                style: TextStyle(
                                  fontSize: widget.size * 0.1,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ),
                        if (stage == 1)
                          Positioned(
                            bottom: widget.size * 0.12,
                            child: Text(
                              '1',
                              style: TextStyle(
                                fontSize: widget.size * 0.14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        Positioned(
                          top: widget.size * (stage == 1 ? 0.12 : 0.18),
                          right: widget.size * 0.1,
                          child: Container(
                            width: widget.size * 0.2,
                            height: widget.size * 0.2,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              _accessoryLabel,
                              style: TextStyle(
                                fontSize: widget.size * 0.09,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final c in cosmetics)
                    if (c.slot == CosmeticSlot.head)
                      Positioned(
                        top: widget.size * 0.02,
                        child: Text(
                          c.emoji,
                          style: TextStyle(fontSize: widget.size * 0.28),
                        ),
                      ),
                  for (final c in cosmetics)
                    if (c.slot == CosmeticSlot.held)
                      Positioned(
                        right: 0,
                        bottom: widget.size * 0.12,
                        child: Text(
                          c.emoji,
                          style: TextStyle(fontSize: widget.size * 0.26),
                        ),
                      ),
                  if (_showHeart)
                    Positioned(
                      top: 0,
                      right: 8,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, v, child) => Opacity(
                          opacity: (1 - v).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -20 * v),
                            child: child,
                          ),
                        ),
                        child: const Text('💜', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  if (_showTear)
                    Positioned(
                      top: widget.size * 0.35,
                      left: widget.size * 0.28,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, v, child) => Opacity(
                          opacity: (1 - v).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 12 * v),
                            child: child,
                          ),
                        ),
                        child: const Text('💧', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 10),
          Text(
            'Стадия $stage «$stageLabel» · ${widget.appearance.label}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FinnyColors.mist,
                ),
          ),
        ],
      ],
    );
  }
}

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const Spacer(),
            Text(
              '$value%',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }
}

class SkillChip extends StatelessWidget {
  const SkillChip({
    super.key,
    required this.theme,
    required this.level,
    required this.xp,
  });

  final QuestTheme theme;
  final int level;
  final int xp;

  Color get _color => switch (theme) {
        QuestTheme.budget => FinnyColors.mint,
        QuestTheme.savings => FinnyColors.sky,
        QuestTheme.purchases => FinnyColors.gold,
      };

  String get _label => switch (theme) {
        QuestTheme.budget => 'Бюджет',
        QuestTheme.savings => 'Копилка',
        QuestTheme.purchases => 'Покупки',
      };

  @override
  Widget build(BuildContext context) {
    final progress = (xp % 40) / 40;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: _color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ур. $level',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w400,
              fontSize: 18,
              color: FinnyColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: _color,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  final QuestDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      QuestDifficulty.easy => FinnyColors.mint,
      QuestDifficulty.medium => FinnyColors.gold,
      QuestDifficulty.hard => FinnyColors.pink,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        difficulty.label,
        style: GoogleFonts.nunito(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Единый блок учебного прогресса (задания, цель, итог периода).
class LearnProgressCard extends StatelessWidget {
  const LearnProgressCard({
    super.key,
    required this.profile,
    this.goal,
    this.lessonsDone = 0,
    this.lessonsTotal = 0,
    this.onTap,
  });

  final PlayerProfile profile;
  final SavingsGoal? goal;
  final int lessonsDone;
  final int lessonsTotal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final questsDone = profile.completedQuestIds.length;
    final periodDone = profile.period.periodQuestsDone;
    final periodTotal = profile.period.activeQuestIds.isEmpty
        ? 0
        : profile.period.activeQuestIds.length;
    final goalText = goal == null
        ? 'Цель ещё не выбрана'
        : '${goal!.name}: ${profile.savingsBalance}/${goal!.cost}';
    final goalProgress = goal == null || goal!.cost <= 0
        ? 0.0
        : (profile.savingsBalance / goal!.cost).clamp(0.0, 1.0);
    final lastPeriod = profile.totalPeriodsCompleted <= 0
        ? 'Периодов ещё не завершено'
        : (profile.period.feedback.isNotEmpty
            ? profile.period.feedback
            : profile.lastFeedback);
    final stageHint = GameEconomy.stageProgressHint(profile);

    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Учебный прогресс',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Задания: всего $questsDone · период $periodDone'
            '${periodTotal > 0 ? '/$periodTotal' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (lessonsTotal > 0) ...[
            const SizedBox(height: 4),
            Text('Уроки: $lessonsDone/$lessonsTotal'),
          ],
          const SizedBox(height: 10),
          Text(goalText, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: goalProgress,
              minHeight: 8,
              color: FinnyColors.savings,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Стадия ${profile.growthStage} «${GameEconomy.stageTitle(profile.growthStage)}»',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            stageHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          if (profile.totalPeriodsCompleted > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Последний период: $lastPeriod',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showFeedback(
  BuildContext context,
  String message, {
  bool ok = true,
  int stars = 0,
  int xp = 0,
  int combo = 0,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(ok ? 'Отлично!' : 'Подумай ещё'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 16)),
          if (stars > 0 || xp > 0 || combo > 1) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (stars > 0) _RewardPill(icon: Icons.star_rounded, text: '+$stars'),
                if (xp > 0) _RewardPill(icon: Icons.bolt_rounded, text: 'XP +$xp'),
                if (combo > 1)
                  _RewardPill(
                    icon: Icons.local_fire_department_rounded,
                    text: '×$combo',
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Понятно'),
        ),
      ],
    ),
  );
}

/// Праздник с «конфетти» при цели / стадии / секрете / коллекции.
Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String message,
  int stars = 0,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'celebration',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, anim, _) {
      return SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFFBBF24)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    top: -8,
                    left: 12,
                    child: Text('🎊', style: TextStyle(fontSize: 28)),
                  ),
                  const Positioned(
                    top: -4,
                    right: 20,
                    child: Text('✨', style: TextStyle(fontSize: 24)),
                  ),
                  const Positioned(
                    bottom: 48,
                    left: 8,
                    child: Text('🎉', style: TextStyle(fontSize: 22)),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      if (stars > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          '★ +$stars',
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5B21B6),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Ура!'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class CollectionsCard extends StatelessWidget {
  const CollectionsCard({super.key, required this.ownedItemIds});

  final List<String> ownedItemIds;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Коллекции',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final c in Engagement.collections) ...[
            Row(
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${c.name}: ${c.ownedCount(ownedItemIds)}/${c.itemIds.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (c.isComplete(ownedItemIds))
                  const Text('✓', style: TextStyle(color: FinnyColors.mint)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: c.progress(ownedItemIds),
                minHeight: 8,
                color: FinnyColors.gold,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FinnyColors.purpleLight, FinnyColors.indigo],
        ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: FinnyColors.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
