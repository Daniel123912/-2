import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'Питомец Финни',
      body: 'Игра, где ты учишься управлять деньгами вместе с питомцем.',
      icon: Icons.pets,
    ),
    (
      title: 'Три решения',
      body: 'Потратить на нужное, на желаемое или отложить в копилку.',
      icon: Icons.account_balance_wallet,
    ),
    (
      title: 'Учись по возрасту',
      body: 'Задания делятся на лёгкие, средние и сложные — под твой уровень.',
      icon: Icons.school,
    ),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Финни',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 28),
                          SoftCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 36,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    color: FinnyColors.sky,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: FinnyColors.mint,
                                      width: 3,
                                    ),
                                  ),
                                  child: Icon(
                                    p.icon,
                                    size: 44,
                                    color: FinnyColors.forest,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  p.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  p.body,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _index == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _index == i
                            ? FinnyColors.forest
                            : FinnyColors.leaf,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (_index < _pages.length - 1) {
                      _page.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      widget.onDone();
                    }
                  },
                  child: Text(
                    _index < _pages.length - 1 ? 'Дальше' : 'Создать питомца',
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
