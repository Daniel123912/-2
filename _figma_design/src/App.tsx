import { useState, useEffect, useRef } from 'react'

/* ─────────────── SVG Components ─────────────── */

function StarsBg() {
  const stars = Array.from({ length: 28 }, (_, i) => ({
    id: i,
    x: Math.random() * 100,
    y: Math.random() * 100,
    size: Math.random() * 3 + 1,
    delay: Math.random() * 3,
    dur: 2 + Math.random() * 2,
  }))
  return (
    <div className="stars-bg">
      <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
        {stars.map(s => (
          <circle
            key={s.id}
            cx={`${s.x}%`} cy={`${s.y}%`}
            r={s.size}
            fill="white"
            style={{
              opacity: 0.3,
              animation: `stars-twinkle ${s.dur}s ease-in-out ${s.delay}s infinite`,
            }}
          />
        ))}
      </svg>
    </div>
  )
}

function FinniCharacter({ mood = 'happy', onClick }: { mood?: string; onClick?: () => void }) {
  const [wiggling, setWiggling] = useState(false)
  const handleClick = () => {
    setWiggling(true)
    setTimeout(() => setWiggling(false), 700)
    onClick?.()
  }
  return (
    <div
      className={`finni-wrapper cursor-pointer select-none ${wiggling ? 'animate-wiggle' : 'animate-float'}`}
      onClick={handleClick}
      style={{ filter: 'drop-shadow(0 20px 40px rgba(124,58,237,0.5))' }}
    >
      <svg viewBox="0 0 180 180" fill="none" xmlns="http://www.w3.org/2000/svg">
        {/* Body glow */}
        <ellipse cx="90" cy="95" rx="68" ry="64" fill="url(#bodyGlow)" opacity="0.3"/>

        {/* Ears */}
        <path d="M38 60 L22 20 L55 45 Z" fill="#FBBF24"/>
        <path d="M40 58 L26 28 L52 47 Z" fill="#FDE68A"/>
        <path d="M142 60 L158 20 L125 45 Z" fill="#FBBF24"/>
        <path d="M140 58 L154 28 L128 47 Z" fill="#FDE68A"/>

        {/* Main body */}
        <circle cx="90" cy="95" r="62" fill="url(#bodyGrad)"/>

        {/* Tummy patch */}
        <ellipse cx="90" cy="105" rx="36" ry="30" fill="url(#tummyGrad)" opacity="0.9"/>

        {/* Face - eyes */}
        {mood === 'happy' ? (
          <>
            <ellipse cx="72" cy="82" rx="10" ry="11" fill="white"/>
            <ellipse cx="108" cy="82" rx="10" ry="11" fill="white"/>
            <circle cx="74" cy="84" r="6" fill="#1A0533"/>
            <circle cx="110" cy="84" r="6" fill="#1A0533"/>
            <circle cx="76" cy="82" r="2" fill="white"/>
            <circle cx="112" cy="82" r="2" fill="white"/>
            {/* Happy squint lines */}
            <path d="M63 76 Q72 72 81 76" stroke="#F472B6" strokeWidth="2.5" strokeLinecap="round" fill="none"/>
            <path d="M99 76 Q108 72 117 76" stroke="#F472B6" strokeWidth="2.5" strokeLinecap="round" fill="none"/>
          </>
        ) : (
          <>
            <path d="M65 82 Q72 76 79 82" stroke="#1A0533" strokeWidth="3" strokeLinecap="round" fill="white"/>
            <path d="M101 82 Q108 76 115 82" stroke="#1A0533" strokeWidth="3" strokeLinecap="round" fill="white"/>
          </>
        )}

        {/* Nose */}
        <ellipse cx="90" cy="97" rx="8" ry="5" fill="#F472B6"/>
        <ellipse cx="88" cy="95" rx="3" ry="2" fill="rgba(255,255,255,0.5)"/>

        {/* Smile */}
        <path d="M74 108 Q90 122 106 108" stroke="#C026D3" strokeWidth="3" strokeLinecap="round" fill="none"/>

        {/* Cheeks */}
        <ellipse cx="58" cy="103" rx="11" ry="7" fill="#F9A8D4" opacity="0.7"/>
        <ellipse cx="122" cy="103" rx="11" ry="7" fill="#F9A8D4" opacity="0.7"/>

        {/* Coin on forehead */}
        <circle cx="90" cy="48" r="14" fill="url(#coinGrad)" style={{ filter: 'drop-shadow(0 4px 8px rgba(217,119,6,0.6))' }}/>
        <circle cx="90" cy="48" r="11" fill="none" stroke="#FDE68A" strokeWidth="1.5"/>
        <text x="90" y="53" textAnchor="middle" fontSize="12" fontWeight="bold" fontFamily="Nunito" fill="#92400E">₽</text>

        {/* Sparkles */}
        <path d="M148 45 L150 38 L152 45 L159 47 L152 49 L150 56 L148 49 L141 47 Z" fill="#FBBF24" opacity="0.9" style={{ animation: 'sparkle 2s ease-in-out 0.3s infinite' }}/>
        <path d="M28 55 L29.5 50 L31 55 L36 56.5 L31 58 L29.5 63 L28 58 L23 56.5 Z" fill="#60A5FA" opacity="0.8" style={{ animation: 'sparkle 2s ease-in-out 1s infinite' }}/>
        <path d="M155 90 L156.2 86.5 L157.4 90 L161 91.2 L157.4 92.4 L156.2 96 L155 92.4 L151.4 91.2 Z" fill="#F472B6" opacity="0.8" style={{ animation: 'sparkle 1.8s ease-in-out 0.7s infinite' }}/>

        {/* Small paws at bottom */}
        <ellipse cx="66" cy="148" rx="18" ry="12" fill="url(#bodyGrad)" opacity="0.9"/>
        <ellipse cx="114" cy="148" rx="18" ry="12" fill="url(#bodyGrad)" opacity="0.9"/>

        <defs>
          <radialGradient id="bodyGlow" cx="50%" cy="50%">
            <stop offset="0%" stopColor="#7C3AED"/>
            <stop offset="100%" stopColor="#4C1D95" stopOpacity="0"/>
          </radialGradient>
          <linearGradient id="bodyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#A78BFA"/>
            <stop offset="60%" stopColor="#7C3AED"/>
            <stop offset="100%" stopColor="#5B21B6"/>
          </linearGradient>
          <linearGradient id="tummyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#EDE9FE"/>
            <stop offset="100%" stopColor="#C4B5FD"/>
          </linearGradient>
          <linearGradient id="coinGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FDE68A"/>
            <stop offset="100%" stopColor="#D97706"/>
          </linearGradient>
        </defs>
      </svg>
    </div>
  )
}

function CoinIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="11" fill="url(#cg)"/>
      <circle cx="12" cy="12" r="8.5" fill="none" stroke="#FDE68A" strokeWidth="1"/>
      <text x="12" y="16" textAnchor="middle" fontSize="10" fontWeight="bold" fontFamily="Nunito" fill="#92400E">₽</text>
      <defs>
        <linearGradient id="cg" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#FDE68A"/>
          <stop offset="100%" stopColor="#D97706"/>
        </linearGradient>
      </defs>
    </svg>
  )
}

/* ─────────────── Data ─────────────── */

const QUESTS = [
  { id: 1, emoji: '🛒', title: 'Умный покупатель', desc: 'Сравни цены в двух магазинах', xp: 50, coins: 30, done: true, color: '#10B981', bg: 'rgba(16,185,129,0.12)' },
  { id: 2, emoji: '🐷', title: 'Копи-копи!', desc: 'Отложи 20₽ в копилку сегодня', xp: 40, coins: 25, done: false, color: '#F472B6', bg: 'rgba(244,114,182,0.12)' },
  { id: 3, emoji: '💡', title: 'Финансовая загадка', desc: 'Ответь на вопрос про сдачу', xp: 60, coins: 40, done: false, color: '#FBBF24', bg: 'rgba(251,191,36,0.12)' },
  { id: 4, emoji: '🎯', title: 'Цель недели', desc: 'Накопи 200₽ за 7 дней', xp: 100, coins: 80, done: false, color: '#60A5FA', bg: 'rgba(96,165,250,0.12)' },
  { id: 5, emoji: '📊', title: 'Мой бюджет', desc: 'Запиши 3 своих расхода', xp: 35, coins: 20, done: false, color: '#A78BFA', bg: 'rgba(167,139,250,0.12)' },
]

const SHOP_ITEMS = [
  { id: 1, emoji: '🎩', name: 'Шляпа банкира', price: 150, owned: false },
  { id: 2, emoji: '🌈', name: 'Радужный плащ', price: 200, owned: true },
  { id: 3, emoji: '💎', name: 'Алмазный ошейник', price: 350, owned: false },
  { id: 4, emoji: '🍎', name: 'Любимое яблоко', price: 50, owned: false },
  { id: 5, emoji: '🏠', name: 'Домик-дворец', price: 500, owned: false },
  { id: 6, emoji: '🎸', name: 'Мини-гитара', price: 180, owned: false },
]

const TRANSACTIONS = [
  { id: 1, emoji: '⭐', label: 'Квест: умный покупатель', amount: +30, date: 'Сегодня' },
  { id: 2, emoji: '🎮', label: 'Игра: финансовый тест', amount: +20, date: 'Вчера' },
  { id: 3, emoji: '🌈', label: 'Куплено: радужный плащ', amount: -200, date: 'Вчера' },
  { id: 4, emoji: '🎁', label: 'Бонус выходного дня', amount: +50, date: '15 сен' },
  { id: 5, emoji: '🐷', label: 'Пополнение копилки', amount: +40, date: '14 сен' },
]

/* ─────────────── Screens ─────────────── */

function HomeScreen({ setTab }: { setTab: (t: number) => void }) {
  const [clicked, setClicked] = useState(false)
  const [showHeart, setShowHeart] = useState(false)
  const balance = 480
  const savingsGoal = 1000
  const savings = 480
  const xp = 720
  const maxXp = 1000
  const streak = 5

  const handleFinniClick = () => {
    setClicked(true)
    setShowHeart(true)
    setTimeout(() => setShowHeart(false), 1500)
    setTimeout(() => setClicked(false), 700)
  }

  return (
    <div style={{ background: 'linear-gradient(160deg, #1A0533 0%, #0D0120 50%, #0A1628 100%)', minHeight: '100%', paddingBottom: 100 }}>
      <StarsBg/>

      {/* Header */}
      <div className="relative" style={{ padding: '56px 24px 0' }}>
        <div className="flex items-center justify-between">
          <div>
            <p style={{ color: 'rgba(255,255,255,0.5)', fontSize: 13, fontWeight: 600, marginBottom: 2 }}>Привет, Маша! 👋</p>
            <h1 style={{ fontFamily: "'Fredoka One'", fontSize: 28, color: 'white', margin: 0, lineHeight: 1.1 }}>Твой питомец<br/>ждёт тебя!</h1>
          </div>
          {/* Level badge */}
          <div style={{
            background: 'linear-gradient(135deg, #7C3AED, #4F46E5)',
            borderRadius: 20, padding: '10px 16px', textAlign: 'center',
            boxShadow: '0 8px 24px rgba(124,58,237,0.5)'
          }}>
            <div style={{ color: 'rgba(255,255,255,0.6)', fontSize: 10, fontWeight: 700 }}>УРОВЕНЬ</div>
            <div style={{ fontFamily: "'Fredoka One'", fontSize: 28, color: '#FBBF24', lineHeight: 1 }}>8</div>
          </div>
        </div>

        {/* XP Bar */}
        <div className="mt-3">
          <div className="flex justify-between mb-1">
            <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', fontWeight: 600 }}>Опыт</span>
            <span style={{ fontSize: 11, color: '#A78BFA', fontWeight: 700 }}>{xp} / {maxXp} XP</span>
          </div>
          <div className="progress-track">
            <div className="progress-bar" style={{
              '--target-width': `${(xp/maxXp)*100}%`,
              background: 'linear-gradient(90deg, #7C3AED, #A78BFA)',
            } as any}/>
          </div>
        </div>

        {/* Streak + Coins row */}
        <div className="flex gap-3 mt-4">
          <div className="flex-1 card-glass flex items-center gap-3" style={{ padding: '10px 16px' }}>
            <span style={{ fontSize: 22 }}>🔥</span>
            <div>
              <div style={{ fontFamily: "'Fredoka One'", fontSize: 22, color: '#FB923C', lineHeight: 1 }}>{streak} дней</div>
              <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.4)', fontWeight: 600 }}>Серия входов</div>
            </div>
          </div>
          <div className="flex-1 card-glass flex items-center gap-3 animate-pulse-glow" style={{ padding: '10px 16px' }}>
            <CoinIcon size={28}/>
            <div>
              <div style={{ fontFamily: "'Fredoka One'", fontSize: 22, color: '#FBBF24', lineHeight: 1 }}>{balance}₽</div>
              <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.4)', fontWeight: 600 }}>Монеток</div>
            </div>
          </div>
        </div>
      </div>

      {/* Finni */}
      <div className="relative flex justify-center items-center" style={{ marginTop: 16, height: 220 }}>
        {showHeart && (
          <div style={{
            position: 'absolute', top: 10, left: '58%',
            fontSize: 32, animation: 'slide-up 0.4s ease-out both',
            pointerEvents: 'none'
          }}>💜</div>
        )}
        <div className="relative">
          {!clicked && (
            <div className="ring-ping" style={{ position: 'absolute', inset: -12, borderRadius: '50%', border: '2px solid rgba(167,139,250,0.3)', animation: 'ring-ping 2s ease-out infinite' }}/>
          )}
          <FinniCharacter mood="happy" onClick={handleFinniClick}/>
        </div>
        <div style={{
          position: 'absolute', bottom: 10, left: '50%', transform: 'translateX(-50%)',
          background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(8px)',
          borderRadius: 999, padding: '6px 16px',
          fontSize: 12, fontWeight: 700, color: 'rgba(255,255,255,0.7)',
          whiteSpace: 'nowrap', border: '1px solid rgba(255,255,255,0.1)'
        }}>
          Нажми на Финни! ✨
        </div>
      </div>

      {/* Hunger / Mood bars */}
      <div className="card-glass mx-6" style={{ padding: '16px 20px', marginTop: 0 }}>
        <h3 style={{ fontFamily: "'Fredoka One'", color: 'white', margin: '0 0 12px', fontSize: 16 }}>Состояние Финни</h3>
        {[
          { label: '❤️ Здоровье', val: 85, color: '#F472B6' },
          { label: '😊 Настроение', val: 92, color: '#FBBF24' },
          { label: '🍎 Сытость', val: 60, color: '#34D399' },
        ].map(b => (
          <div key={b.label} className="mb-2">
            <div className="flex justify-between mb-1">
              <span style={{ fontSize: 12, fontWeight: 700, color: 'rgba(255,255,255,0.7)' }}>{b.label}</span>
              <span style={{ fontSize: 12, fontWeight: 800, color: b.color }}>{b.val}%</span>
            </div>
            <div className="progress-track">
              <div className="progress-bar" style={{ '--target-width': `${b.val}%`, background: b.color } as any}/>
            </div>
          </div>
        ))}
      </div>

      {/* Savings Goal */}
      <div className="mx-6 mt-4 card-gradient streak" style={{
        background: 'linear-gradient(135deg, #0D9488, #0F766E)',
        padding: '18px 20px',
      }}>
        <div className="flex justify-between items-start mb-3">
          <div>
            <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.6)', fontWeight: 700 }}>🎯 Цель: Велосипед</div>
            <div style={{ fontFamily: "'Fredoka One'", color: 'white', fontSize: 22, marginTop: 2 }}>{savings} / {savingsGoal}₽</div>
          </div>
          <div style={{ fontSize: 36 }}>🚲</div>
        </div>
        <div className="progress-track" style={{ height: 12 }}>
          <div className="progress-bar" style={{ '--target-width': `${(savings/savingsGoal)*100}%`, background: 'linear-gradient(90deg, #34D399, #6EE7B7)' } as any}/>
        </div>
        <div className="flex justify-between mt-2">
          <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', fontWeight: 600 }}>Накоплено 48%</span>
          <span style={{ fontSize: 11, color: '#6EE7B7', fontWeight: 700 }}>Осталось 520₽</span>
        </div>
      </div>

      {/* Quick quests */}
      <div className="mx-6 mt-5">
        <div className="flex justify-between items-center mb-3">
          <h3 style={{ fontFamily: "'Fredoka One'", color: 'white', margin: 0, fontSize: 20 }}>Квесты сегодня</h3>
          <button
            onClick={() => setTab(1)}
            style={{ color: '#A78BFA', fontWeight: 700, fontSize: 13, background: 'none', border: 'none', cursor: 'pointer' }}
          >Все →</button>
        </div>
        {QUESTS.slice(0, 3).map((q, i) => (
          <div key={q.id} className="quest-card mb-3" style={{ background: q.bg, border: `1px solid ${q.color}30`, animationDelay: `${i * 0.1}s` }}>
            <div style={{ width: 48, height: 48, borderRadius: 16, background: `${q.color}20`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, flexShrink: 0 }}>
              {q.emoji}
            </div>
            <div className="flex-1 min-w-0">
              <div style={{ fontWeight: 800, color: 'white', fontSize: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
                {q.title}
                {q.done && <span style={{ fontSize: 10, background: '#10B981', color: 'white', borderRadius: 999, padding: '1px 8px', fontWeight: 700 }}>✓</span>}
              </div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)', fontWeight: 600, marginTop: 2 }}>{q.desc}</div>
            </div>
            <div style={{ textAlign: 'right', flexShrink: 0 }}>
              <div className="coin-badge"><CoinIcon size={12}/> {q.coins}</div>
              <div style={{ fontSize: 10, color: 'rgba(255,255,255,0.4)', fontWeight: 600, marginTop: 4 }}>+{q.xp} XP</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

function QuestsScreen() {
  const [active, setActive] = useState<number | null>(null)
  const [completed, setCompleted] = useState<number[]>([1])

  const handleComplete = (id: number) => {
    if (!completed.includes(id)) {
      setCompleted(prev => [...prev, id])
    }
    setActive(null)
  }

  return (
    <div style={{ background: 'linear-gradient(160deg, #0A1628 0%, #0D0120 100%)', minHeight: '100%', paddingBottom: 100 }}>
      <StarsBg/>
      <div style={{ padding: '56px 24px 0' }}>
        <h1 style={{ fontFamily: "'Fredoka One'", fontSize: 30, color: 'white', margin: '0 0 4px' }}>Квесты 🗺️</h1>
        <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, fontWeight: 600, margin: '0 0 20px' }}>
          Выполняй задания — зарабатывай монеты!
        </p>

        {/* Stats row */}
        <div className="flex gap-3 mb-6">
          {[
            { label: 'Выполнено', val: completed.length, emoji: '✅', color: '#34D399' },
            { label: 'Доступно', val: QUESTS.length - completed.length, emoji: '🎯', color: '#FBBF24' },
            { label: 'Монет заработано', val: completed.reduce((s, id) => s + (QUESTS.find(q => q.id === id)?.coins || 0), 0), emoji: '💰', color: '#A78BFA' },
          ].map(s => (
            <div key={s.label} className="card-glass flex-1 text-center" style={{ padding: '12px 8px' }}>
              <div style={{ fontSize: 20, marginBottom: 2 }}>{s.emoji}</div>
              <div style={{ fontFamily: "'Fredoka One'", fontSize: 22, color: s.color }}>{s.val}</div>
              <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.4)', fontWeight: 700, lineHeight: 1.2 }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Quest list */}
        {QUESTS.map((q, i) => {
          const done = completed.includes(q.id)
          return (
            <div
              key={q.id}
              className="quest-card mb-3"
              style={{
                background: done ? `${q.color}18` : q.bg,
                border: `1.5px solid ${done ? q.color : q.color + '30'}`,
                opacity: done ? 0.75 : 1,
                animationDelay: `${i * 0.08}s`,
              }}
              onClick={() => !done && setActive(q.id)}
            >
              <div style={{
                width: 52, height: 52, borderRadius: 18,
                background: `${q.color}25`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 26, flexShrink: 0, position: 'relative'
              }}>
                {q.emoji}
                {done && (
                  <div style={{
                    position: 'absolute', bottom: -2, right: -2,
                    width: 18, height: 18, borderRadius: '50%',
                    background: '#10B981', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 10, color: 'white', fontWeight: 900
                  }}>✓</div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div style={{ fontWeight: 800, color: done ? 'rgba(255,255,255,0.5)' : 'white', fontSize: 15 }}>{q.title}</div>
                <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.4)', fontWeight: 600, marginTop: 3 }}>{q.desc}</div>
                <div style={{ display: 'flex', gap: 8, marginTop: 6 }}>
                  <span style={{ fontSize: 11, color: q.color, fontWeight: 700 }}>⚡ {q.xp} XP</span>
                </div>
              </div>
              <div style={{ textAlign: 'right', flexShrink: 0 }}>
                <div className="coin-badge"><CoinIcon size={12}/> {q.coins}</div>
                <div style={{ fontSize: 12, marginTop: 6, color: done ? '#10B981' : q.color }}>
                  {done ? 'Готово!' : '→'}
                </div>
              </div>
            </div>
          )
        })}
      </div>

      {/* Quest modal */}
      {active !== null && (() => {
        const q = QUESTS.find(x => x.id === active)!
        return (
          <div
            style={{
              position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.7)',
              backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'flex-end',
              zIndex: 100, padding: '0 0 100px'
            }}
            onClick={() => setActive(null)}
          >
            <div
              className="animate-bounce-in"
              style={{
                width: '100%', borderRadius: '32px 32px 0 0',
                background: 'linear-gradient(180deg, #2D1165, #1A0533)',
                border: '1px solid rgba(255,255,255,0.1)',
                padding: '28px 24px 32px',
              }}
              onClick={e => e.stopPropagation()}
            >
              <div className="text-center mb-4">
                <div style={{ fontSize: 56, marginBottom: 8 }}>{q.emoji}</div>
                <h2 style={{ fontFamily: "'Fredoka One'", fontSize: 26, color: 'white', margin: '0 0 8px' }}>{q.title}</h2>
                <p style={{ color: 'rgba(255,255,255,0.5)', fontWeight: 600, fontSize: 14, margin: 0 }}>{q.desc}</p>
              </div>
              <div className="flex gap-3 mb-6">
                <div className="flex-1 text-center card-glass" style={{ padding: '14px 8px' }}>
                  <div style={{ fontFamily: "'Fredoka One'", fontSize: 26, color: '#FBBF24' }}>{q.coins}</div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', fontWeight: 700 }}>Монет</div>
                </div>
                <div className="flex-1 text-center card-glass" style={{ padding: '14px 8px' }}>
                  <div style={{ fontFamily: "'Fredoka One'", fontSize: 26, color: '#A78BFA' }}>{q.xp}</div>
                  <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', fontWeight: 700 }}>XP</div>
                </div>
              </div>
              <button
                onClick={() => handleComplete(q.id)}
                style={{
                  width: '100%', padding: '18px', borderRadius: 20,
                  background: `linear-gradient(135deg, ${q.color}, ${q.color}99)`,
                  border: 'none', cursor: 'pointer', color: 'white',
                  fontFamily: "'Fredoka One'", fontSize: 20,
                  boxShadow: `0 8px 32px ${q.color}60`,
                  transition: 'transform 0.15s',
                }}
              >
                Выполнено! ✓
              </button>
            </div>
          </div>
        )
      })()}
    </div>
  )
}

function PiggyScreen() {
  const [adding, setAdding] = useState(false)
  const [amount, setAmount] = useState('')
  const [total, setTotal] = useState(480)
  const goal = 1000
  const pct = Math.min((total / goal) * 100, 100)

  const handleAdd = () => {
    const n = parseInt(amount)
    if (n > 0) {
      setTotal(prev => prev + n)
      setAmount('')
      setAdding(false)
    }
  }

  return (
    <div style={{ background: 'linear-gradient(160deg, #0F0A28, #0D0120 100%)', minHeight: '100%', paddingBottom: 100 }}>
      <StarsBg/>
      <div style={{ padding: '56px 24px 0' }}>
        <h1 style={{ fontFamily: "'Fredoka One'", fontSize: 30, color: 'white', margin: '0 0 4px' }}>Копилка 🐷</h1>
        <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, fontWeight: 600, margin: '0 0 24px' }}>
          Копи на мечту вместе с Финни!
        </p>

        {/* Big piggy visual */}
        <div className="card-gradient" style={{
          background: 'linear-gradient(135deg, #2D1165, #1A0533)',
          border: '1px solid rgba(255,255,255,0.08)', padding: '28px 24px',
        }}>
          <div className="flex justify-between items-start mb-2">
            <div>
              <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12, fontWeight: 700 }}>🚲 Велосипед</div>
              <div style={{ fontFamily: "'Fredoka One'", color: 'white', fontSize: 36, lineHeight: 1.1 }}>{total}₽</div>
              <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, fontWeight: 600 }}>из {goal}₽</div>
            </div>
            <div style={{ position: 'relative', width: 90, height: 90 }}>
              {/* SVG Piggy */}
              <svg viewBox="0 0 90 90" fill="none">
                <ellipse cx="45" cy="52" rx="36" ry="30" fill="#F9A8D4"/>
                <circle cx="45" cy="36" r="22" fill="#F9A8D4"/>
                <circle cx="36" cy="30" r="7" fill="#FDA4AF"/>
                <circle cx="54" cy="30" r="7" fill="#FDA4AF"/>
                <circle cx="36" cy="30" r="3.5" fill="#1A0533"/>
                <circle cx="54" cy="30" r="3.5" fill="#1A0533"/>
                <ellipse cx="45" cy="42" rx="9" ry="6" fill="#FDA4AF"/>
                <circle cx="42" cy="41" r="2" fill="#9F1239"/>
                <circle cx="48" cy="41" r="2" fill="#9F1239"/>
                {/* Coin slot on top */}
                <rect x="40" y="15" width="10" height="3" rx="1.5" fill="#9F1239"/>
                {/* Ear */}
                <path d="M24 24 L16 10 L30 18 Z" fill="#FDA4AF"/>
                <path d="M66 24 L74 10 L60 18 Z" fill="#FDA4AF"/>
                {/* Tail */}
                <path d="M78 55 Q88 50 84 40" stroke="#FDA4AF" strokeWidth="4" strokeLinecap="round" fill="none"/>
                {/* Legs */}
                <rect x="24" y="76" width="12" height="10" rx="6" fill="#F9A8D4"/>
                <rect x="38" y="78" width="12" height="10" rx="6" fill="#F9A8D4"/>
                <rect x="52" y="76" width="12" height="10" rx="6" fill="#F9A8D4"/>
              </svg>
            </div>
          </div>

          {/* Big progress */}
          <div className="progress-track mt-2" style={{ height: 16, borderRadius: 999 }}>
            <div className="progress-bar" style={{
              '--target-width': `${pct}%`,
              background: 'linear-gradient(90deg, #F472B6, #EC4899)',
              borderRadius: 999,
            } as any}/>
          </div>
          <div className="flex justify-between mt-2">
            <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.4)', fontWeight: 700 }}>Накоплено {Math.round(pct)}%</span>
            <span style={{ fontSize: 12, color: '#F9A8D4', fontWeight: 700 }}>Осталось {goal - total}₽</span>
          </div>

          <button
            onClick={() => setAdding(true)}
            style={{
              width: '100%', marginTop: 20, padding: '16px',
              background: 'linear-gradient(135deg, #EC4899, #BE185D)',
              border: 'none', borderRadius: 16, cursor: 'pointer',
              fontFamily: "'Fredoka One'", fontSize: 18, color: 'white',
              boxShadow: '0 8px 24px rgba(236,72,153,0.4)',
            }}
          >
            + Пополнить копилку
          </button>
        </div>

        {/* Transaction history */}
        <div className="mt-6">
          <h3 style={{ fontFamily: "'Fredoka One'", color: 'white', margin: '0 0 14px', fontSize: 20 }}>История</h3>
          {TRANSACTIONS.map((tx, i) => (
            <div
              key={tx.id}
              className="card-glass flex items-center gap-3 mb-3"
              style={{ padding: '14px 16px', animationDelay: `${i * 0.06}s` }}
            >
              <div style={{ width: 40, height: 40, borderRadius: 14, background: 'rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20 }}>
                {tx.emoji}
              </div>
              <div className="flex-1">
                <div style={{ fontWeight: 700, color: 'white', fontSize: 13 }}>{tx.label}</div>
                <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.35)', fontWeight: 600, marginTop: 2 }}>{tx.date}</div>
              </div>
              <div style={{ fontFamily: "'Fredoka One'", fontSize: 18, color: tx.amount > 0 ? '#34D399' : '#F87171' }}>
                {tx.amount > 0 ? '+' : ''}{tx.amount}₽
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Add money modal */}
      {adding && (
        <div
          style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: 24 }}
          onClick={() => setAdding(false)}
        >
          <div
            className="animate-bounce-in"
            style={{ width: '100%', background: 'linear-gradient(180deg, #2D1165, #1A0533)', borderRadius: 28, padding: '28px 24px', border: '1px solid rgba(255,255,255,0.1)' }}
            onClick={e => e.stopPropagation()}
          >
            <h3 style={{ fontFamily: "'Fredoka One'", color: 'white', fontSize: 24, textAlign: 'center', margin: '0 0 20px' }}>Сколько кладём? 🐷</h3>
            <input
              value={amount}
              onChange={e => setAmount(e.target.value.replace(/\D/g, ''))}
              placeholder="Введи сумму"
              style={{
                width: '100%', padding: '16px', borderRadius: 16,
                background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.15)',
                color: 'white', fontFamily: "'Fredoka One'", fontSize: 24,
                textAlign: 'center', outline: 'none', marginBottom: 16,
              }}
              type="number"
              autoFocus
            />
            <div className="flex gap-3 mb-4">
              {[10, 20, 50, 100].map(v => (
                <button key={v} onClick={() => setAmount(String(v))} style={{
                  flex: 1, padding: '10px 0',
                  background: amount === String(v) ? '#7C3AED' : 'rgba(255,255,255,0.06)',
                  border: '1px solid rgba(255,255,255,0.1)', borderRadius: 12,
                  color: 'white', fontFamily: "'Fredoka One'", fontSize: 16, cursor: 'pointer',
                }}>
                  {v}₽
                </button>
              ))}
            </div>
            <button
              onClick={handleAdd}
              style={{
                width: '100%', padding: '16px', background: 'linear-gradient(135deg, #EC4899, #BE185D)',
                border: 'none', borderRadius: 16, cursor: 'pointer',
                fontFamily: "'Fredoka One'", fontSize: 20, color: 'white',
              }}
            >
              Положить! ✨
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

function ShopScreen() {
  const [owned, setOwned] = useState<number[]>([2])
  const [coins] = useState(480)
  const [bought, setBought] = useState<number | null>(null)

  const handleBuy = (item: typeof SHOP_ITEMS[0]) => {
    if (!owned.includes(item.id) && coins >= item.price) {
      setOwned(prev => [...prev, item.id])
      setBought(item.id)
      setTimeout(() => setBought(null), 2000)
    }
  }

  return (
    <div style={{ background: 'linear-gradient(160deg, #0A1018 0%, #0D0120 100%)', minHeight: '100%', paddingBottom: 100 }}>
      <StarsBg/>
      <div style={{ padding: '56px 24px 0' }}>
        <div className="flex justify-between items-center mb-2">
          <h1 style={{ fontFamily: "'Fredoka One'", fontSize: 30, color: 'white', margin: 0 }}>Магазин 🛍️</h1>
          <div className="coin-badge animate-pulse-glow">
            <CoinIcon size={14}/> {coins}₽
          </div>
        </div>
        <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, fontWeight: 600, margin: '0 0 24px' }}>
          Укрась своего Финни!
        </p>

        {/* Finni preview */}
        <div className="card-glass flex justify-center mb-6" style={{ padding: 16, position: 'relative', overflow: 'hidden' }}>
          <div style={{ textAlign: 'center' }}>
            <FinniCharacter mood="happy"/>
            <div style={{ fontFamily: "'Fredoka One'", color: 'white', fontSize: 14, marginTop: 4 }}>
              {owned.includes(2) ? '🌈 Радужный плащ' : 'Нет аксессуаров'}
            </div>
          </div>
        </div>

        {/* Item grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {SHOP_ITEMS.map((item, i) => {
            const isOwned = owned.includes(item.id)
            const canBuy = !isOwned && coins >= item.price
            const isBought = bought === item.id
            return (
              <div
                key={item.id}
                className={`card-glass ${isBought ? 'animate-tada' : ''}`}
                style={{
                  padding: '18px 14px',
                  textAlign: 'center',
                  cursor: canBuy ? 'pointer' : 'default',
                  border: isOwned ? '1.5px solid #7C3AED' : '1px solid rgba(255,255,255,0.08)',
                  animationDelay: `${i * 0.07}s`,
                  transition: 'transform 0.2s',
                  position: 'relative',
                  overflow: 'hidden',
                }}
                onClick={() => handleBuy(item)}
              >
                {isOwned && (
                  <div style={{
                    position: 'absolute', top: 8, right: 8,
                    width: 20, height: 20, borderRadius: '50%',
                    background: '#7C3AED', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 10, color: 'white', fontWeight: 900
                  }}>✓</div>
                )}
                <div style={{ fontSize: 40, marginBottom: 10 }}>{item.emoji}</div>
                <div style={{ fontWeight: 800, color: 'white', fontSize: 13, marginBottom: 8, lineHeight: 1.2 }}>{item.name}</div>
                <div
                  style={{
                    borderRadius: 12, padding: '8px 0',
                    background: isOwned
                      ? 'rgba(124,58,237,0.2)'
                      : canBuy
                        ? 'linear-gradient(135deg, #FBBF24, #D97706)'
                        : 'rgba(255,255,255,0.05)',
                    color: isOwned ? '#A78BFA' : canBuy ? 'white' : 'rgba(255,255,255,0.3)',
                    fontFamily: "'Fredoka One'",
                    fontSize: 15,
                  }}
                >
                  {isOwned ? 'Куплено' : <><CoinIcon size={13}/> {item.price}₽</>}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}

/* ─────────────── App Shell ─────────────── */

const TABS = [
  { icon: '🏠', label: 'Главная' },
  { icon: '🗺️', label: 'Квесты' },
  { icon: '🐷', label: 'Копилка' },
  { icon: '🛍️', label: 'Магазин' },
]

export default function App() {
  const [tab, setTab] = useState(0)

  const screens = [
    <HomeScreen setTab={setTab}/>,
    <QuestsScreen/>,
    <PiggyScreen/>,
    <ShopScreen/>,
  ]

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'radial-gradient(ellipse at 30% 20%, #2D1165 0%, #0D0120 40%, #080010 100%)',
      padding: '20px',
    }}>
      {/* Ambient glow */}
      <div style={{
        position: 'fixed', width: 600, height: 600, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(124,58,237,0.15) 0%, transparent 70%)',
        top: '50%', left: '50%', transform: 'translate(-50%,-50%)',
        pointerEvents: 'none',
      }}/>

      <div className="mobile-frame">
        {/* Screen content */}
        <div className="screen" style={{ background: '#0D0120' }}>
          {screens[tab]}
        </div>

        {/* Tab bar */}
        <div className="tab-bar">
          {TABS.map((t, i) => (
            <div
              key={t.label}
              className={`tab-item${tab === i ? ' active' : ''}`}
              onClick={() => setTab(i)}
            >
              <div className="tab-icon">{t.icon}</div>
              <div className="tab-label">{t.label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
