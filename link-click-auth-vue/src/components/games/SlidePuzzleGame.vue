<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { getRecord, saveRecord } from '../../utils/gameScore'
import WinStage from './WinStage.vue'

/** 数字华容道 · 3×3 / 4×4 / 5×5，把数字还原成顺序即通关 */
const SIZES = [3, 4, 5]
const size = ref(3)
const board = ref([])
const moves = ref(0)
const elapsed = ref(0)
const won = ref(false)
const status = ref('点击空格旁边的数字块移动，还原顺序即可通关')
const record = ref(getRecord('slide'))
const target = computed(() => Array.from({ length: size.value ** 2 - 1 }, (_, i) => i + 1))
const bestText = computed(() => record.value.clears ? `累计通关 ${record.value.clears} 次` : '尚无通关记录')
const fmt = (s) => { const v = Math.max(0, Math.floor(s || 0)); return v >= 60 ? `${Math.floor(v / 60)}:${String(v % 60).padStart(2, '0')}` : `${v}s` }

let timer = null, timeBase = 0

function solvedBoard() {
  return [...target.value, 0]
}
function shuffle() {
  const b = solvedBoard()
  let blank = b.length - 1
  const n = size.value
  const steps = n * n * 40
  for (let s = 0; s < steps; s++) {
    const opts = []
    const r = Math.floor(blank / n), c = blank % n
    if (r > 0) opts.push(blank - n)
    if (r < n - 1) opts.push(blank + n)
    if (c > 0) opts.push(blank - 1)
    if (c < n - 1) opts.push(blank + 1)
    const pick = opts[(Math.random() * opts.length) | 0]
    ;[b[blank], b[pick]] = [b[pick], b[blank]]
    blank = pick
  }
  // 极小概率洗回已完成状态，再走几步
  if (b.every((v, i) => v === solvedBoard()[i])) {
    ;[b[0], b[1]] = [b[1], b[0]]
  }
  return b
}

function reset() {
  if (timer) { clearInterval(timer); timer = null }
  board.value = shuffle()
  moves.value = 0
  elapsed.value = 0
  won.value = false
  status.value = '点击空格旁边的数字块移动，还原顺序即可通关'
  startTimer()
}
function startTimer() {
  if (timer) clearInterval(timer)
  timeBase = Date.now() - elapsed.value * 1000
  timer = setInterval(() => {
    if (!won.value) elapsed.value = Math.floor((Date.now() - timeBase) / 1000)
  }, 200)
}
function setSize(n) { size.value = n; reset() }

function adjacent(i, blank) {
  const n = size.value
  const r = Math.floor(i / n), c = i % n
  const br = Math.floor(blank / n), bc = blank % n
  return Math.abs(r - br) + Math.abs(c - bc) === 1
}

function swapAt(i) {
  if (won.value) return
  const blank = board.value.indexOf(0)
  if (!adjacent(i, blank)) { status.value = '只能移动空格旁边的数字块'; return }
  const b = board.value.slice()
  ;[b[i], b[blank]] = [b[blank], b[i]]
  board.value = b
  moves.value++
  status.value = `已走 ${moves.value} 步 · 用时 ${fmt(elapsed.value)}`
  checkWin()
}

/** 方向键 = 空格移动方向 */
function moveBlank(dr, dc) {
  const n = size.value
  const blank = board.value.indexOf(0)
  const r = Math.floor(blank / n) + dr, c = (blank % n) + dc
  if (r < 0 || c < 0 || r >= n || c >= n) return
  swapAt(r * n + c)
}

function checkWin() {
  if (!board.value.every((v, i) => v === solvedBoard()[i])) return
  won.value = true
  if (timer) { clearInterval(timer); timer = null }
  const field = `best_${size.value}`
  const patch = { clears: (record.value.clears || 0) + 1 }
  if (!record.value[field] || moves.value < record.value[field]) patch[field] = moves.value
  saveRecord('slide', patch)
  record.value = getRecord('slide')
  status.value = `🎉 通关！${moves.value} 步还原，用时 ${fmt(elapsed.value)}`
}

function onKey(e) {
  const map = { arrowup: [-1, 0], w: [-1, 0], arrowdown: [1, 0], s: [1, 0], arrowleft: [0, -1], a: [0, -1], arrowright: [0, 1], d: [0, 1] }
  const k = e.key.toLowerCase()
  if (map[k]) { e.preventDefault(); moveBlank(map[k][0], map[k][1]) }
  else if (k === 'r') reset()
}

onMounted(() => { window.addEventListener('keydown', onKey); reset() })
onBeforeUnmount(() => { window.removeEventListener('keydown', onKey); if (timer) clearInterval(timer) })
</script>

<template>
  <div class="sp">
    <div class="levels">
      <button v-for="n in SIZES" :key="n" class="lv" :class="{ on: size === n }" @click="setSize(n)">{{ n }}×{{ n }}</button>
    </div>
    <div class="bar">
      <span>步数 <b>{{ moves }}</b></span>
      <span>用时 <b>{{ fmt(elapsed) }}</b></span>
      <span class="best">{{ bestText }}</span>
    </div>
    <p class="status">{{ status }}</p>

    <div class="stage">
      <div class="grid" :style="{ gridTemplateColumns: `repeat(${size}, 1fr)` }">
        <button
          v-for="(v, i) in board"
          :key="i"
          class="tile"
          :class="{ blank: v === 0, correct: v !== 0 && v === i + 1 }"
          @click="swapAt(i)"
        >{{ v || '' }}</button>
      </div>
      <div v-if="won" class="overlay">
        <WinStage theme="rainbow" />
        <div class="ov-emoji">🎉</div>
        <h3>还原成功！</h3>
        <p>{{ moves }} 步 · 用时 {{ fmt(elapsed) }}</p>
        <div class="ov-btns">
          <button class="btn" @click="reset">再来一局</button>
          <button v-if="size < 5" class="btn ghost" @click="setSize(size + 1)">挑战 {{ (size + 1) }}×{{ (size + 1) }}</button>
        </div>
      </div>
    </div>

    <div class="dpad">
      <button class="d up" @click="moveBlank(-1, 0)" aria-label="空格上移">▲</button>
      <button class="d left" @click="moveBlank(0, -1)" aria-label="空格左移">◀</button>
      <button class="d right" @click="moveBlank(0, 1)" aria-label="空格右移">▶</button>
      <button class="d down" @click="moveBlank(1, 0)" aria-label="空格下移">▼</button>
    </div>
    <div class="actions"><button class="btn ghost" @click="reset">重新打乱 (R)</button></div>
    <p class="tip">点击空格旁的方块，或用方向键移动空格 · 数字按顺序排列即通关</p>
  </div>
</template>

<style scoped>
.sp { width: 100%; max-width: 400px; display: flex; flex-direction: column; align-items: center; gap: 10px; }
.levels { display: flex; gap: 8px; }
.lv {
  border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .05);
  color: #cdd6f4; font-family: inherit; font-size: 12.5px; padding: 7px 16px;
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
  display: grid; gap: 6px; width: 100%; max-width: 340px; margin: 0 auto;
  padding: 10px; border-radius: 16px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .9), rgba(12, 14, 38, .9));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .45);
}
.tile {
  aspect-ratio: 1; border: 1px solid rgba(255, 255, 255, .18); border-radius: 10px; cursor: pointer;
  font-family: inherit; font-size: clamp(16px, 5vw, 24px); font-weight: 800; color: #eef2ff;
  display: grid; place-items: center;
  background: linear-gradient(150deg, rgba(45, 226, 230, .26), rgba(138, 92, 255, .28));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .2), 0 4px 12px rgba(0, 0, 0, .3);
  transition: transform .14s, box-shadow .18s, background .18s;
}
.tile:hover:not(.blank) { transform: translateY(-2px); box-shadow: 0 8px 18px rgba(var(--game-rgb), .45); }
.tile.correct {
  background: linear-gradient(150deg, rgba(var(--game-rgb), .62), rgba(var(--game-rgb), .3));
  border-color: rgba(var(--game-rgb), .75);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .35), 0 0 16px rgba(var(--game-rgb), .4);
  animation: correctPulse 2.2s ease-in-out infinite;
}
@keyframes correctPulse { 0%, 100% { filter: brightness(1) } 50% { filter: brightness(1.28) } }
.tile.blank { background: rgba(255, 255, 255, .035); border: 1px dashed rgba(255, 255, 255, .12); box-shadow: none; cursor: default; }

.overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 16px;
  background: rgba(6, 16, 32, .94); backdrop-filter: blur(5px); animation: pop .24s ease-out;
}
.overlay > :not(.ws) { position: relative; z-index: 2; }
@keyframes pop { from { opacity: 0; transform: scale(.94) } to { opacity: 1; transform: none } }
.ov-emoji { font-size: 44px; line-height: 1; }
.overlay h3 { font-size: 23px; font-weight: 800; color: var(--cyan); text-shadow: 0 0 18px rgba(45, 226, 230, .5); }
.overlay p { font-size: 13px; color: #cdd6f4; }
.ov-btns { display: flex; gap: 10px; flex-wrap: wrap; justify-content: center; margin-top: 4px; }

.dpad { display: grid; grid-template-columns: repeat(3, 42px); grid-template-rows: repeat(3, 42px); gap: 6px; }
.d {
  border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .06);
  color: #eef2ff; font-size: 16px; border-radius: 10px; cursor: pointer; transition: .15s; display: grid; place-items: center;
}
.d:hover { border-color: var(--cyan); }
.d:active { transform: scale(.93); background: rgba(45, 226, 230, .2); }
.d.up { grid-area: 1 / 2; } .d.left { grid-area: 2 / 1; } .d.right { grid-area: 2 / 3; } .d.down { grid-area: 3 / 2; }
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
