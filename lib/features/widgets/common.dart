import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../theme/app_theme.dart';

class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.appearance,
    required this.stage,
    this.size = 120,
    this.showLabel = true,
    this.mood = 70,
  });

  final PetAppearance appearance;
  final int stage;
  final double size;
  final bool showLabel;
  final int mood;

  Color get _color {
    return switch (appearance.color) {
      'серый' => const Color(0xFF7A8B9A),
      'пятнистый' => const Color(0xFFC4A35A),
      _ => const Color(0xFFE07A3D),
    };
  }

  IconData get _bodyIcon {
    return switch (appearance.body) {
      'пушистый' => Icons.pets,
      'длинный' => Icons.cruelty_free,
      _ => Icons.emoji_nature,
    };
  }

  String get _accessoryLabel {
    return switch (appearance.accessory) {
      'шарфик' => 'Ш',
      'очки' => 'О',
      _ => 'Б',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scale = 0.85 + (stage * 0.1);
    final bounce = mood >= 70 ? 0.0 : (mood < 40 ? 4.0 : 2.0);
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, t, child) {
            return Transform.translate(
              offset: Offset(0, bounce * (1 - t)),
              child: Transform.scale(scale: scale * (0.85 + 0.15 * t), child: child),
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _color.withValues(alpha: 0.35),
                  FinnyColors.sky.withValues(alpha: 0.5),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(_bodyIcon, size: size * 0.45, color: _color),
                Positioned(
                  top: 10,
                  right: 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _color),
                    ),
                    child: Text(
                      _accessoryLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            'Стадия $stage · ${appearance.label}',
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
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: const Duration(milliseconds: 500),
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 12,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
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
        QuestTheme.budget => FinnyColors.budget,
        QuestTheme.savings => FinnyColors.savings,
        QuestTheme.purchases => FinnyColors.purchases,
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text('ур. $level', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: _color,
              backgroundColor: _color.withValues(alpha: 0.15),
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
      QuestDifficulty.medium => FinnyColors.sun,
      QuestDifficulty.hard => FinnyColors.coral,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (stars > 0) _RewardPill(icon: Icons.star, text: '+$stars'),
                if (xp > 0) _RewardPill(icon: Icons.bolt, text: 'XP +$xp'),
                if (combo > 1)
                  _RewardPill(icon: Icons.local_fire_department, text: '×$combo'),
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

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: FinnyColors.sky,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: FinnyColors.forest),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
