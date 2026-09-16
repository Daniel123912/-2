import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content_loader.dart';
import '../data/profile_repository.dart';
import '../domain/economy.dart';
import '../domain/models.dart';

final contentProvider = FutureProvider<GameContent>((ref) async {
  return ContentLoader.load();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final gameControllerProvider =
    AsyncNotifierProvider<GameController, PlayerProfile?>(GameController.new);

class GameController extends AsyncNotifier<PlayerProfile?> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<PlayerProfile?> build() async {
    return _repo.load();
  }

  Future<void> _persist(PlayerProfile? profile) async {
    state = AsyncData(profile);
    if (profile == null) {
      await _repo.clear();
    } else {
      await _repo.save(profile);
    }
  }

  Future<void> createProfile({
    required String playerName,
    required String petName,
    required PetAppearance appearance,
    AgeTrack ageTrack = AgeTrack.middle,
  }) async {
    final profile = PlayerProfile.fresh(
      playerName: playerName.trim().isEmpty ? 'Игрок' : playerName.trim(),
      petName: petName.trim().isEmpty ? 'Финни' : petName.trim(),
      appearance: appearance,
      ageTrack: ageTrack,
    );
    await _persist(profile);
  }

  Future<void> setAgeTrack(AgeTrack track) async {
    final profile = state.value;
    if (profile == null) return;
    await _persist(profile.copyWith(
      ageTrack: track,
      lastFeedback: 'Уровень обучения: ${track.label}. Задания обновлены.',
    ));
  }

  Future<EconomyResult> confirmBudget(BudgetPlan plan) async {
    final profile = state.value;
    if (profile == null) {
      return EconomyResult(
        profile: PlayerProfile.fresh(
          playerName: 'Игрок',
          petName: 'Финни',
          appearance: const PetAppearance(
            body: 'круглый',
            color: 'рыжий',
            accessory: 'бантик',
          ),
        ),
        ok: false,
        message: 'Сначала создай питомца.',
      );
    }
    final content = await ref.read(contentProvider.future);
    final result = GameEconomy.confirmPlan(
      profile,
      plan,
      questPool: content.quests,
    );
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> buy(ShopItem item) async {
    final profile = state.value!;
    final result = GameEconomy.purchase(profile, item);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<void> selectGoal(String goalId) async {
    final profile = state.value!;
    await _persist(profile.copyWith(
      selectedGoalId: goalId,
      lastFeedback: 'Цель выбрана. Откладывай монеты в копилку!',
    ));
  }

  Future<EconomyResult> saveToGoal(int amount) async {
    final profile = state.value!;
    final result = GameEconomy.transferToSavings(profile, amount);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> withdraw(int amount, {required bool confirmed}) async {
    final profile = state.value!;
    final result = GameEconomy.withdrawFromSavings(
      profile,
      amount,
      confirmed: confirmed,
    );
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> answerQuest(Quest quest, QuestOption option) async {
    final profile = state.value!;
    final result = GameEconomy.completeQuest(profile, quest, option);
    // Сохраняем и верный, и неверный ответ (XP/комбо/настроение).
    await _persist(result.profile);
    return result;
  }

  Future<EconomyResult> claimGoal(SavingsGoal goal) async {
    final profile = state.value!;
    final result = GameEconomy.claimGoal(profile, goal);
    if (result.ok) await _persist(result.profile);
    return result;
  }

  Future<String> finishPeriod() async {
    final profile = state.value!;
    final result = GameEconomy.closePeriod(profile);
    await _persist(result.profile);
    return result.feedback;
  }

  Future<void> nextPeriod() async {
    final profile = state.value!;
    await _persist(GameEconomy.startNextPeriod(profile));
  }

  Future<void> setDemoMode(bool enabled) async {
    final profile = state.value!;
    await _persist(profile.copyWith(demoMode: enabled));
  }

  Future<void> resetProfile() async {
    await _persist(null);
  }
}
