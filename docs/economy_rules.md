# Игровая и финансовая логика (формулы и правила)

Источник истины в коде: `lib/domain/economy.dart` (`GameEconomy`), модели — `lib/domain/models.dart`.  
Юнит-тесты: `test/domain/economy_test.dart`.

## 1. Стартовый баланс

| Трек | Возраст | Стартовый баланс |
|------|---------|------------------|
| `junior` | 7–8 | 100 |
| `middle` | 9–10 | 110 |
| `senior` | 11 | 120 |

Создание профиля: `PlayerProfile.fresh` → `AgeTrack.startingBalance`.  
Фаза периода: `planning`, стадия питомца `1`, сытость/настроение `70`.

## 2. Начисление валюты

| Источник | Формула | Когда |
|----------|---------|-------|
| Периодический доход | `40` (+`5` для `senior`) | `startNextPeriod` |
| Верный ответ в задании | см. §9 | `completeQuest` |
| Бонус за все квесты периода | `+10` | `closePeriod` |

Каждое изменение баланса сопровождается текстом в `lastFeedback` (источник и сумма).

## 3. Распределение бюджета

Перед периодом сумма делится на 3 корзины: **обязательное / желаемое / копилка**.

- `plan.total ≤ balance`
- суммы ≥ 0
- после `confirmPlan` фаза → `playing`, план фиксируется

Рекомендуемые доли (`recommendedPlan`):

| Трек | обяз. | жел. | копилка |
|------|-------|------|---------|
| junior | 50% | 25% | 25% |
| middle | 45% | 30% | 25% |
| senior | 40% | 30% | 30% |

Остаток округления уходит в копилку.

## 4. Обязательные и необязательные расходы

- Товары: `ExpenseKind.mandatory` / `optional` (`assets/content/items.json`).
- Покупка только в фазе `playing`, только если `canAfford`.
- Списание: `balance -= price` (через `clampBalance`, отрицательный баланс запрещён).
- Факт: `mandatorySpent` / `optionalSpent` += price.
- Влияние на питомца: `hunger += hungerDelta`, `mood += moodDelta` (clamp 0…100).
- Перерасход корзины относительно плана: дополнительно `mood − 3`.

## 5. Накопления и финансовые цели

- Цель выбирается из набора (`goals.json`).
- Пополнение: `transferToSavings(amount)` — с баланса в `savingsBalance`, факт `saved += amount`.
- Снятие: только после `confirmed: true`; иначе предупреждение; при снятии `mood − 5`.
- Достижение цели: `savingsBalance ≥ cost` → списание стоимости, `mood + 18`, `★ + 5`, цель сбрасывается.
- Оценка срока: `ceil((cost − savings) / averageSaving)` (`estimatedPeriodsToGoal`).

## 6. Проверка средств и запрет минуса

```
canAfford(profile, price) ⇔ price ≥ 0 ∧ balance ≥ price
clampBalance(v) = max(0, v)
```

Покупка / пополнение копилки при нехватке → `ok: false` и сообщение «Не хватает N монет…».

## 7. План vs факт

```
mandatoryOk  = fact.mandatory ≥ round(plan.mandatory × 0.7) ∧ fact.mandatory > 0
planClose    = |fact.total − plan.total| ≤ 15
               где fact.total = mandatory + optional + saved
savedOk      = fact.saved > 0
wasGoodPeriod = mandatoryOk ∧ (savedOk ∨ planClose)
```

Реализация: `GameEconomy.comparePlanFact` → `PlanFactReport`.  
UI: экран итога периода + строки план/факт в магазине и бюджете.

## 8. Игровые периоды

Фазы: `planning` → `playing` → `summary` → следующий `planning`.

| Событие | Метод |
|---------|-------|
| Подтвердить план | `confirmPlan` |
| Завершить период | `closePeriod` |
| Начать следующий | `startNextPeriod` (+ доход, hunger − 8) |

Демо-режим: переходы без календарных сроков.

## 9. Задания: награды и логика

Выдача набора: `pickPeriodQuests` — по одному квесту на тему (бюджет / копилка / покупки) + доп. по треку.

| Событие | Эффект |
|---------|--------|
| Неверный ответ | задание **не** закрывается; XP+3; mood−3; комбо = 0 |
| Верный ответ | закрытие; монеты; XP; ★; mood+8 (+4 при комбо ≥ 3) |

Монеты за верный ответ:

```
reward = option.reward
       + comboBonus          // streak≥2: (min(streak,5)−1)×2
       + difficulty.starReward × 2
       + periodBonus         // +4, если квест из набора периода
```

★ / XP по сложности: easy 1/10, medium 2/18, hard 3/28.

## 10. Состояние и рост питомца

Статы: `hunger`, `mood` ∈ [0, 100].

При закрытии периода:

| Условие | Последствия |
|---------|-------------|
| !mandatoryOk | mood−10, hunger−15 |
| savedOk | mood+5, ★+1 |
| planClose | ★+1; иначе mood−4 |
| все квесты периода | ★+2, balance+10, mood+5 |

Серия хороших периодов → стадия:

```
если goodPeriodStreak ≥ 2 и stage < 3:
  stage += 1
  streak = 0
  ★ += 2
```

Связь финансов с питомцем: покупки меняют сытость/настроение сразу; итог периода и серия «хороших» периодов определяют рост стадии.

## 11. Карта методов ↔ требования

| Требование | Метод / место |
|------------|---------------|
| Стартовый баланс | `PlayerProfile.fresh`, `startingBalanceFor` |
| Начисление валюты | `startNextPeriod`, `completeQuest`, бонус в `closePeriod` |
| Бюджет | `confirmPlan`, `recommendedPlan` |
| Покупки | `purchase`, `canAfford` |
| Копилка / цели | `transferToSavings`, `withdrawFromSavings`, `claimGoal` |
| План vs факт | `comparePlanFact`, `closePeriod` |
| Периоды | `GamePeriod`, фазы, `closePeriod` / `startNextPeriod` |
| Питомец | дельты в `purchase` / `closePeriod`, `applyStageProgress` |
| Задания | `pickPeriodQuests`, `completeQuest`, `questsForProfile` |
| Подсказка «что дальше» | `nextAction` |
