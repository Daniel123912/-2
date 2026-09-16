import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Игровая палитра: лесной бирюзовый + солнечный янтарь (не «AI-фиолетовый»).
class FinnyColors {
  static const forest = Color(0xFF0F5C4C);
  static const mint = Color(0xFF2BB673);
  static const leaf = Color(0xFF7ED6A5);
  static const sky = Color(0xFFD8F3E8);
  static const cream = Color(0xFFF7FBFA);
  static const sun = Color(0xFFF4B942);
  static const coral = Color(0xFFE07A5F);
  static const ink = Color(0xFF1A2E28);
  static const mist = Color(0xFF5C7A70);
  static const card = Color(0xFFFFFFFF);
  static const budget = Color(0xFF2A9D8F);
  static const savings = Color(0xFF4A6FA5);
  static const purchases = Color(0xFFE9A825);
}

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: FinnyColors.forest,
      brightness: Brightness.light,
      primary: FinnyColors.forest,
      secondary: FinnyColors.sun,
      tertiary: FinnyColors.coral,
      surface: FinnyColors.cream,
    );

    final display = GoogleFonts.fredokaTextTheme();
    final body = GoogleFonts.nunitoTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: FinnyColors.cream,
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: FinnyColors.forest,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: FinnyColors.forest,
          fontWeight: FontWeight.w700,
          fontSize: 26,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: body.titleMedium?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        bodyLarge: body.bodyLarge?.copyWith(
          color: FinnyColors.ink,
          fontSize: 17,
          height: 1.35,
        ),
        bodyMedium: body.bodyMedium?.copyWith(
          color: FinnyColors.ink,
          fontSize: 16,
          height: 1.35,
        ),
        labelLarge: body.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: FinnyColors.ink,
        titleTextStyle: display.titleLarge?.copyWith(
          color: FinnyColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      cardTheme: CardThemeData(
        color: FinnyColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: FinnyColors.leaf.withValues(alpha: 0.45)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FinnyColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: body.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FinnyColors.forest,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: FinnyColors.mint, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: body.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: FinnyColors.leaf,
        backgroundColor: FinnyColors.sky,
        labelStyle: body.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

/// Мягкий игровой фон с градиентом и «монетками».
class PlayBackground extends StatelessWidget {
  const PlayBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F8F1),
            Color(0xFFF7FBFA),
            Color(0xFFFFF6E0),
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _Blob(color: FinnyColors.leaf.withValues(alpha: 0.35), size: 160),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _Blob(color: FinnyColors.sun.withValues(alpha: 0.22), size: 180),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? FinnyColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinnyColors.leaf.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: FinnyColors.forest.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }
}
