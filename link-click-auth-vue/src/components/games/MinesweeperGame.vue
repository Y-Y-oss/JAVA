<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { getRecord, saveRecord } from '../../utils/gameScore'
import WinStage from './WinStage.vue'

/** 扫雷 · 三档难度，翻开所有非雷格即通关；首次点击永远安全 */
const LEVELS = [
  { key: 'easy', label: '初级', size: 9, mines: 10 },
  { key: 'medium', label: '中级', size: 12, mines: 20 },
  { key: 'hard', label: '高级', size: 16, mines: 40 }
]
const levelIdx = ref(0)
const conf = computed(() => LEVELS[levelIdx.value])
const cells = ref([])
const phase = ref('ready') // ready | play | won | lost
const flagMode = ref(false)
const elapsed = ref(0)
const status = ref('左键翻开，右键（或开启插旗模式）标记地雷')
const record = ref(getRecord('mines'))
const flagged = computed(() => cells.value.filter((c) => c.flagged).length)
const revealed = computed(() => cells.value.filter((c) => c.revealed).length)
const leftMines = computed(() => conf.value.mines - flagged.value)
const bestText = computed(() => {
  const r = record.value
  return r.clears ? `累计通关 ${r.clears} 次` : '尚无通关记录'
})
const fmt = (s) => { const v = Math.max(0, Math.floor(s || 0)); return v >= 60 ? `${Math.floor(v / 60)}:${String(v % 60).padStart(2, '0')}` : `${v}s` }

let timer = null, timeBase = 0, started = false

function neighbors(i) {
  const n = conf.value.size, r = Math.floor(i / n), c = i % n, out = []
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      if (!dr && !dc) continue
      const nr = r + dr, nc = c + dc
      if (nr >= 0 && nr < n && nc >= 0 && nc < n) out.push(nr * n + nc)
    }
  }
  return out
}

function reset() {
  if (timer) { clearInterval(timer); timer = null }
  cells.value = Array.from({ length: conf.value.size ** 2 }, () => ({ mine: false, revealed: false, flagged: false, adj: 0 }))
  phase.value = 'ready'
  started = false
  elapsed.value = 0
  flagMode.value = false
  status.value = '左键翻开，右键（或开启插旗模式）标记地雷'
}

function placeMines(safe) {
  const n = conf.value.size, total = n * n
  const banned = new Set([safe, ...neighbors(safe)])
  const pool = []
  for (let i = 0; i < total; i++) if (!banned.has(i)) pool.push(i)
  for (let i = pool.length - 1; i > 0; i--) {
    const j = (Math.random() * (i + 1)) | 0
    ;[pool[i], pool[j]] = [pool[j], pool[i]]
  }
  const mineSet = new Set(pool.slice(0, conf.value.mines))
  cells.value.forEach((c, i) => { c.mine = mineSet.has(i) })
  cells.value.forEach((c, i) => {
    if (c.mine) return
    c.adj = neighbors(i).filter((j) => cells.value[j].mine).length
  })
  started = true
  phase.value = 'play'
  startTimer()
}

function startTimer() {
  if (timer) clearInterval(timer)
  timeBase = Date.now() - elapsed.value * 1000
  timer = setInterval(() => {
    if (phase.value === 'play') elapsed.value = Math.floor((Date.now() - timeBase) / 1000)
  }, 200)
}

function reveal(i) {
  if (phase.value === 'won' || phase.value === 'lost') return
  const c = cells.value[i]
  if (!c || c.revealed || c.flagged) return
  if (!started) placeMines(i)
  if (c.mine) { onLose(i); return }
  const stack = [i]
  while (stack.length) {
    const k = stack.pop()
    const cell = cells.value[k]
    if (cell.revealed || cell.flagged || cell.mine) continue
    cell.revealed = true
    if (cell.adj === 0) neighbors(k).forEach((j) => {
      if (!cells.value[j].revealed && !cells.value[j].mine && !cells.value[j].flagged) stack.push(j)
    })
  }
  checkWin()
}

function onLose(i) {
  cells.value.forEach((c) => { if (c.mine) c.revealed = true })
  cells.value[i].boom = true
  phase.value = 'lost'
  if (timer) { clearInterval(timer); timer = null }
  status.value = '💥 踩到雷了，点「重新开始」再来一次'
}

function checkWin() {
  const total = cells.value.length
  if (revealed.value !== total - conf.value.mines) return
  phase.value = 'won'
  if (timer) { clearInterval(timer); timer = null }
  const bestField = 'best_' + conf.value.key
  const patch = { clears: (record.value.clears || 0) + 1, maxLevel: Math.max(record.value.maxLevel || 0, levelIdx.value + 1) }
  if (!record.value[bestField] || elapsed.value < record.value[bestField]) patch[bestField] = elapsed.value
  saveRecord('mines', patch)
  record.value = getRecord('mines')
  status.value = `🎉 排雷完成！用时 ${fmt(elapsed.value)}`
}

function toggleFlag(i) {
  if (phase.value === 'won' || phase.value === 'lost') return
  const c = cells.value[i]
  if (!c || c.revealed) return
  c.flagged = !c.flagged
}

function click(i) { if (flagMode.value) toggleFlag(i); else reveal(i) }
function setLevel(i) { levelIdx.value = i; reset() }

function cellText(c) {
  if (c.flagged) return '🚩'
  if (!c.revealed) return ''
  if (c.mine) return '💣'
  return c.adj ? String(c.adj) : ''
}
function cellClass(c) {
  return {
    revealed: c.revealed, mine: c.revealed && c.mine, boom: c.boom,
    flagged: c.flagged, [`n${c.adj}`]: c.revealed && c.adj > 0
  }
}

onMounted(reset)
onBeforeUnmount(() => { if (timer) clearInterval(timer) })
</script>

<template>
  <div class="ms">
    <div class="levels">
      <button
        v-for="(l, i) in LEVELS"
        :key="l.key"
        class="lv" :class="{ on: levelIdx === i }"
        @click="setLevel(i)"
      >{{ l.label }} {{ l.size }}×{{ l.size }}</button>
    </div>

    <div class="bar">
      <span>剩余雷 <b>{{ leftMines }}</b></span>
      <span>用时 <b>{{ fmt(elapsed) }}</b></span>
      <span>已翻开 <b>{{ revealed }}</b></span>
      <span class="best">{{ bestText }}</span>
    </div>
    <p class="status">{{ status }}</p>

    <div class="stage">
      <div class="grid" :style="{ gridTemplateColumns: `repeat(${conf.size}, 1fr)` }">
        <button
          v-for="(c, i) in cells"
          :key="i"
          class="cell"
          :class="cellClass(c)"
          @click="click(i)"
          @contextmenu.prevent="toggleFlag(i)"
        >{{ cellText(c) }}</button>
      </div>
      <div v-if="phase === 'won' || phase === 'lost'" class="overlay">
        <WinStage :theme="phase === 'won' ? 'grid' : 'fireworks'" />
        <div class="ov-emoji">{{ phase === 'won' ? '🎉' : '💥' }}</div>
        <h3>{{ phase === 'won' ? '通关！排雷完成' : '踩雷了' }}</h3>
        <p>{{ phase === 'won' ? `用时 ${fmt(elapsed)} · 试试更难的难度` : '别灰心，雷区已经全部显示出来了' }}</p>
        <button class="btn" @click="reset">再来一局</button>
      </div>
    </div>

    <div class="actions">
      <button class="btn ghost" :class="{ on: flagMode }" @click="flagMode = !flagMode">
        {{ flagMode ? '🚩 插旗模式（开）' : '插旗模式（关）' }}
      </button>
      <button class="btn" @click="reset">重新开始</button>
    </div>
    <p class="tip">左键翻开 / 右键插旗 · 手机可开「插旗模式」 · 翻开所有安全格即通关</p>
  </div>
</template>

<style scoped>
.ms { width: 100%; max-width: 430px; display: flex; flex-direction: column; align-items: center; gap: 10px; }
.levels { display: flex; gap: 8px; flex-wrap: wrap; justify-content: center; }
.lv {
  border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .05);
  color: #cdd6f4; font-family: inherit; font-size: 12.5px; padding: 7px 14px;
  border-radius: 999px; cursor: pointer; transition: .22s;
}
.lv:hover { color: #fff; border-color: var(--cyan); }
.lv.on { color: #04121f; font-weight: 700; border-color: transparent; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); }

.bar {
  width: 100%; display: flex; flex-wrap: wrap; gap: 12px; align-items: center;
  padding: 10px 14px; border-radius: 12px; font-size: 12.5px; color: #cdd6f4;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .14);
}
.bar b { color: #fff; font-size: 15px; }
.bar .best { margin-left: auto; color: var(--cyan-soft); font-size: 11.5px; }
.status { font-size: 13px; color: #9fb0d8; text-align: center; margin: 0; min-height: 18px; }

.stage { position: relative; width: 100%; }
.grid {
  display: grid; gap: 2px; width: 100%; max-width: 400px; margin: 0 auto;
  padding: 8px; border-radius: 14px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .9), rgba(12, 14, 38, .9));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .45);
}
.cell {
  aspect-ratio: 1; border: 0; border-radius: 4px; cursor: pointer; font-family: inherit;
  font-size: clamp(10px, 2.6vw, 15px); font-weight: 800; line-height: 1;
  display: grid; place-items: center; color: #eef2ff;
  background: linear-gradient(150deg, rgba(var(--game-rgb), .22), rgba(var(--game-rgb), .08));
  border: 1px solid rgba(255, 255, 255, .12); transition: .12s;
}
.cell:hover { filter: brightness(1.3); }
.cell.revealed { background: rgba(10, 14, 39, .6); border-color: rgba(255, 255, 255, .06); cursor: default; }
.cell.flagged { background: rgba(255, 72, 196, .22); }
.cell.mine { background: rgba(255, 72, 196, .3); }
.cell.boom {
  position: relative; background: var(--game-main);
  box-shadow: 0 0 20px rgba(var(--game-rgb), .9);
  animation: boomFlash .55s ease-out;
}
.cell.boom::after {
  content: ''; position: absolute; inset: 0; border-radius: 50%;
  border: 2px solid var(--game-accent);
  animation: boomWave .7s ease-out forwards;
}
@keyframes boomFlash { 0% { transform: scale(.6); filter: brightness(2) } 45% { transform: scale(1.25) } 100% { transform: scale(1) } }
@keyframes boomWave { from { transform: scale(.4); opacity: 1 } to { transform: scale(3.6); opacity: 0 } }
.cell.n1 { color: #7af5f7; } .cell.n2 { color: #8be9ff; } .cell.n3 { color: #b39cff; }
.cell.n4 { color: #ff8ad8; } .cell.n5 { color: #ffb36b; } .cell.n6 { color: #ff6b8a; }
.cell.n7 { color: #fff; } .cell.n8 { color: #cdd6f4; }

.overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 14px;
  background: rgba(22, 6, 10, .94); backdrop-filter: blur(5px); animation: pop .24s ease-out;
}
.overlay > :not(.ws) { position: relative; z-index: 2; }
@keyframes pop { from { opacity: 0; transform: scale(.94) } to { opacity: 1; transform: none } }
.ov-emoji { font-size: 44px; line-height: 1; }
.overlay h3 { font-size: 23px; font-weight: 800; color: var(--cyan); }
.overlay p { font-size: 13px; color: #cdd6f4; text-align: center; }

.actions { display: flex; gap: 10px; flex-wrap: wrap; justify-content: center; }
.btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13.5px; font-weight: 600; color: #04121f;
  padding: 9px 20px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .35); transition: .22s;
}
.btn:hover { transform: translateY(-1px); }
.btn.ghost { color: #cdd6f4; background: rgba(255, 255, 255, .08); border: 1px solid rgba(255, 255, 255, .18); box-shadow: none; }
.btn.ghost:hover { color: #fff; border-color: var(--cyan); }
.btn.ghost.on { color: #04121f; background: var(--cyan); border-color: transparent; }
.tip { font-size: 11.5px; color: #7e8ab0; text-align: center; margin: 0; }
</style>
