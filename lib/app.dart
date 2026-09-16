import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/create_pet/create_pet_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/game_controller.dart';
import 'theme/app_theme.dart';

class FinnyApp extends ConsumerStatefulWidget {
  const FinnyApp({super.key});

  @override
  ConsumerState<FinnyApp> createState() => _FinnyAppState();
}

class _FinnyAppState extends ConsumerState<FinnyApp> {
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(gameControllerProvider);

    return MaterialApp(
      title: 'Питомец Финни',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: profileAsync.when(
        loading: () => const Scaffold(
          body: PlayBackground(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Ошибка: $e')),
        ),
        data: (profile) {
          if (profile == null) {
            if (_showOnboarding) {
              return OnboardingScreen(
                onDone: () => setState(() => _showOnboarding = false),
              );
            }
            return const CreatePetScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
