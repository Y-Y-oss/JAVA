<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { getRecord, saveRecord } from '../../utils/gameScore'

/** 记忆翻牌 · 4 关闯关：翻出所有配对即过关，关卡越大牌越多 */
const LEVELS = [
  { cols: 4, rows: 3, pairs: 6 },
  { cols: 4, rows: 4, pairs: 8 },
  { cols: 5, rows: 4, pairs: 10 },
  { cols: 6, rows: 6, pairs: 18 }
]
const TOTAL = LEVELS.length
const SYMBOLS = ['⏰', '📷', '🎞️', '🌟', '💫', '🔮', '🧩', '🎈', '🍀', '🌙', '🎧', '🕰️', '🗝️', '💌', '🎐', '🌈', '🪐', '⚡']

const level = ref(1)
const cards = ref([])
const cols = ref(4)
const moves = ref(0)
const elapsed = ref(0)
const phase = ref('play')
const status = ref('翻开两张相同的牌即可配对，全部配对进入下一关')
const record = ref(getRecord('memory'))
const matchedCount = computed(() => cards.value.filter((c) => c.matched).length)
const bestText = computed(() => record.value.clears ? `全通 ${record.value.clears} 次 · 最少 ${record.value.bestMoves} 步` : '尚无全通记录')
const fmt = (s) => { const v = Math.max(0, Math.floor(s || 0)); return v >= 60 ? `${Math.floor(v / 60)}:${String(v % 60).padStart(2, '0')}` : `${v}s` }

let first = -1, second = -1, lock = false, flipTimer = null, timer = null, timeBase = 0

function setupLevel(n) {
  const conf = LEVELS[n - 1]
  cols.value = conf.cols
  const syms = SYMBOLS.slice(0, conf.pairs)
  const deck = []
  syms.forEach((s, i) => {
    deck.push({ id: `${i}-a`, sym: s, flipped: false, matched: false })
    deck.push({ id: `${i}-b`, sym: s, flipped: false, matched: false })
  })
  for (let i = deck.length - 1; i > 0; i--) {
    const j = (Math.random() * (i + 1)) | 0
    ;[deck[i], deck[j]] = [deck[j], deck[i]]
  }
  cards.value = deck
  first = -1; second = -1; lock = false
  moves.value = 0
  phase.value = 'play'
  status.value = `第 ${n} / ${TOTAL} 关 · ${conf.pairs} 对牌，全部配对即可过关`
  saveRecord('memory', { maxLevel: Math.max(record.value.maxLevel || 0, n) })
  record.value = getRecord('memory')
  startTimer()
}

function startTimer() {
  if (timer) clearInterval(timer)
  timeBase = Date.now() - elapsed.value * 1000
  timer = setInterval(() => {
    if (phase.value === 'play') elapsed.value = Math.floor((Date.now() - timeBase) / 1000)
  }, 200)
}

function flip(i) {
  if (lock || phase.value !== 'play') return
  const c = cards.value[i]
  if (!c || c.flipped || c.matched) return
  c.flipped = true
  if (first < 0) { first = i; return }
  second = i
  moves.value++
  const a = cards.value[first], b = cards.value[second]
  if (a.sym === b.sym) {
    a.matched = true; b.matched = true
    first = -1; second = -1
    status.value = `配对成功！还剩 ${cards.value.length / 2 - matchedCount.value} 对`
    if (matchedCount.value === cards.value.length / 2) onLevelClear()
  } else {
    lock = true
    status.value = '不一样，记住位置再来～'
    flipTimer = setTimeout(() => {
      a.flipped = false; b.flipped = false
      first = -1; second = -1; lock = false
      status.value = `第 ${level.value} 关 · 继续找出相同的一对`
    }, 750)
  }
}

function onLevelClear() {
  if (timer) { clearInterval(timer); timer = null }
  if (level.value >= TOTAL) {
    phase.value = 'allClear'
    const patch = { clears: (record.value.clears || 0) + 1, maxLevel: TOTAL }
    if (!record.value.bestMoves || moves.value < record.value.bestMoves) patch.bestMoves = moves.value
    if (!record.value.bestTime || elapsed.value < record.value.bestTime) patch.bestTime = elapsed.value
    saveRecord('memory', patch)
    record.value = getRecord('memory')
    status.value = `🏆 全部 ${TOTAL} 关通关！用时 ${fmt(elapsed.value)}`
  } else {
    phase.value = 'levelClear'
    status.value = `🎉 第 ${level.value} 关通过！`
  }
}

function nextLevel() { level.value++; setupLevel(level.value) }
function restartAll() {
  if (timer) { clearInterval(timer); timer = null }
  if (flipTimer) clearTimeout(flipTimer)
  elapsed.value = 0
  level.value = 1
  setupLevel(1)
}

onMounted(() => setupLevel(1))
onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
  if (flipTimer) clearTimeout(flipTimer)
})
</script>

<template>
  <div class="mg">
    <div class="bar">
      <span>关卡 <b>{{ level }}/{{ TOTAL }}</b></span>
      <span>配对 <b>{{ matchedCount }}/{{ cards.length / 2 }}</b></span>
      <span>翻牌 <b>{{ moves }}</b></span>
      <span>用时 <b>{{ fmt(elapsed) }}</b></span>
      <span class="best">{{ bestText }}</span>
    </div>
    <p class="status">{{ status }}</p>

    <div class="stage">
      <div class="grid" :style="{ gridTemplateColumns: `repeat(${cols}, 1fr)` }">
        <button
          v-for="(c, i) in cards"
          :key="c.id"
          class="card"
          :class="{ flipped: c.flipped || c.matched, matched: c.matched }"
          @click="flip(i)"
        >
          <span class="face back">✦</span>
          <span class="face front">{{ c.sym }}</span>
        </button>
      </div>
      <div v-if="phase !== 'play'" class="overlay">
        <div class="ov-emoji">{{ phase === 'allClear' ? '🏆' : '🎉' }}</div>
        <h3>{{ phase === 'allClear' ? '全部通关！' : '第 ' + level + ' 关通过' }}</h3>
        <p>{{ phase === 'allClear' ? `用时 ${fmt(elapsed)} · ${moves} 次翻牌` : '牌会更多，记忆力跟得上吗？' }}</p>
        <div class="ov-btns">
          <button v-if="phase === 'levelClear'" class="btn" @click="nextLevel">下一关 →</button>
          <button class="btn ghost" @click="restartAll">从第 1 关重来</button>
        </div>
      </div>
    </div>

    <div class="actions">
      <button class="btn ghost" @click="restartAll">重新开始</button>
    </div>
    <p class="tip">点击翻开两张牌 · 全部配对即过关 · 4 关全通即大通关</p>
  </div>
</template>

<style scoped>
.mg { width: 100%; max-width: 460px; display: flex; flex-direction: column; align-items: center; gap: 10px; }
.bar {
  width: 100%; display: flex; flex-wrap: wrap; gap: 12px; align-items: center;
  padding: 10px 14px; border-radius: 12px; font-size: 12.5px; color: #cdd6f4;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .14);
}
.bar b { color: #fff; font-size: 14px; }
.bar .best { margin-left: auto; color: var(--cyan-soft); font-size: 11.5px; }
.status { font-size: 13px; color: #9fb0d8; text-align: center; margin: 0; min-height: 18px; }

.stage { position: relative; width: 100%; }
.grid {
  display: grid; gap: 8px; width: 100%; max-width: 400px; margin: 0 auto;
  padding: 12px; border-radius: 16px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .85), rgba(12, 14, 38, .9));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .45);
}
.card {
  position: relative; aspect-ratio: .82; border: 0; padding: 0; cursor: pointer;
  background: transparent; perspective: 600px; font-family: inherit;
}
.face {
  position: absolute; inset: 0; display: grid; place-items: center; border-radius: 10px;
  backface-visibility: hidden; transition: transform .32s cubic-bezier(.2, .8, .2, 1), box-shadow .2s;
  font-size: clamp(16px, 4.4vw, 26px);
}
.back {
  color: #7af5f7; background: linear-gradient(150deg, rgba(45, 226, 230, .22), rgba(138, 92, 255, .24));
  border: 1px solid rgba(122, 245, 247, .35); box-shadow: inset 0 1px 0 rgba(255, 255, 255, .16);
}
.card:hover .back { box-shadow: 0 0 14px rgba(45, 226, 230, .4); }
.front {
  transform: rotateY(180deg); color: #04121f;
  background: linear-gradient(150deg, #7af5f7, #b39cff);
  border: 1px solid rgba(255, 255, 255, .4);
}
.card.flipped .back { transform: rotateY(180deg); }
.card.flipped .front { transform: rotateY(360deg); }
.card.matched .front { background: linear-gradient(150deg, #2de2e6, #ff8ad8); box-shadow: 0 0 16px rgba(45, 226, 230, .45); }
.card.matched { cursor: default; }

.overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 16px;
  background: rgba(8, 11, 32, .87); backdrop-filter: blur(4px); animation: pop .24s ease-out;
}
@keyframes pop { from { opacity: 0; transform: scale(.94) } to { opacity: 1; transform: none } }
.ov-emoji { font-size: 44px; line-height: 1; }
.overlay h3 { font-size: 23px; font-weight: 800; color: var(--cyan); text-shadow: 0 0 18px rgba(45, 226, 230, .5); }
.overlay p { font-size: 13px; color: #cdd6f4; text-align: center; }
.ov-btns { display: flex; gap: 10px; margin-top: 4px; flex-wrap: wrap; justify-content: center; }

.actions { display: flex; gap: 10px; }
.btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13.5px; font-weight: 600; color: #04121f;
  padding: 9px 20px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .35); transition: .22s;
}
.btn:hover { transform: translateY(-1px); }
.btn.ghost { color: #cdd6f4; background: rgba(255, 255, 255, .08); border: 1px solid rgba(255, 255, 255, .18); box-shadow: none; }
.btn.ghost:hover { color: #fff; border-color: var(--cyan); }
.tip { font-size: 11.5px; color: #7e8ab0; text-align: center; margin: 0; }
</style>
