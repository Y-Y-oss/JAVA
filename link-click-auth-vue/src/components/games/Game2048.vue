<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { getRecord, saveRecord, updateBest } from '../../utils/gameScore'
import WinStage from './WinStage.vue'

/** 2048：合出 2048 即通关，可继续挑战更高分。支持键盘 / 滑动 / 屏幕按钮 / 撤销一步 */
const SIZE = 4
const cells = ref(Array(SIZE * SIZE).fill(0))
const score = ref(0)
const best = ref(getRecord('2048').bestScore || 0)
const over = ref(false)
const won = ref(false)
const keepPlaying = ref(false)
const status = ref('方向键 / WASD 或滑动合并，凑出 2048 即通关')
const record = ref(getRecord('2048'))
const maxTile = ref(record.value.maxTile || 0)
let prev = null
let touchStart = null

function addRandom() {
  const free = []
  for (let i = 0; i < cells.value.length; i++) if (!cells.value[i]) free.push(i)
  if (!free.length) return false
  const i = free[(Math.random() * free.length) | 0]
  cells.value[i] = Math.random() < .9 ? 2 : 4
  return true
}

function reset() {
  cells.value = Array(SIZE * SIZE).fill(0)
  score.value = 0
  over.value = false
  won.value = false
  keepPlaying.value = false
  prev = null
  addRandom(); addRandom()
  status.value = '方向键 / WASD 或滑动合并，凑出 2048 即通关'
}

function compress(line) {
  const arr = line.filter((v) => v !== 0)
  for (let i = 0; i < arr.length - 1; i++) {
    if (arr[i] === arr[i + 1]) {
      arr[i] *= 2
      score.value += arr[i]
      arr.splice(i + 1, 1)
    }
  }
  while (arr.length < SIZE) arr.push(0)
  return arr
}

function groups(dir) {
  const out = []
  for (let i = 0; i < SIZE; i++) {
    const line = [], coords = []
    for (let j = 0; j < SIZE; j++) {
      let r, c
      if (dir === 'left') { r = i; c = j }
      else if (dir === 'right') { r = i; c = SIZE - 1 - j }
      else if (dir === 'up') { r = j; c = i }
      else { r = SIZE - 1 - j; c = i }
      line.push(cells.value[r * SIZE + c])
      coords.push(r * SIZE + c)
    }
    out.push({ line, coords })
  }
  return out
}

function canMove() {
  for (let i = 0; i < cells.value.length; i++) if (!cells.value[i]) return true
  for (let r = 0; r < SIZE; r++) {
    for (let c = 0; c < SIZE; c++) {
      const v = cells.value[r * SIZE + c]
      if (c < SIZE - 1 && cells.value[r * SIZE + c + 1] === v) return true
      if (r < SIZE - 1 && cells.value[(r + 1) * SIZE + c] === v) return true
    }
  }
  return false
}

function move(dir) {
  if (over.value || (won.value && !keepPlaying.value)) return
  const snap = { cells: cells.value.slice(), score: score.value }
  const next = cells.value.slice()
  let changed = false
  groups(dir).forEach((g) => {
    const res = compress(g.line)
    res.forEach((v, j) => {
      if (next[g.coords[j]] !== v) changed = true
      next[g.coords[j]] = v
    })
  })
  if (!changed) return
  prev = snap
  cells.value = next
  addRandom()

  if (score.value > best.value) {
    best.value = score.value
    updateBest('2048', 'bestScore', score.value)
  }
  const max = Math.max(...cells.value)
  if (max > maxTile.value) { maxTile.value = max; updateBest('2048', 'maxTile', max) }

  if (max >= 2048 && !won.value) {
    won.value = true
    record.value = saveRecord('2048', { clears: (record.value.clears || 0) + 1 })
    status.value = '🎉 通关！你合出了 2048'
  } else {
    status.value = `最高方块 ${max} · 得分 ${score.value}`
  }
  if (!canMove()) { over.value = true; status.value = '没有可移动的方向了，最终得分 ' + score.value }
}

function undo() {
  if (!prev) return
  cells.value = prev.cells.slice()
  score.value = prev.score
  prev = null
  over.value = false
  won.value = false
  keepPlaying.value = false
  status.value = '已撤销上一步'
}

function onKey(e) {
  const map = {
    arrowleft: 'left', a: 'left', arrowright: 'right', d: 'right',
    arrowup: 'up', w: 'up', arrowdown: 'down', s: 'down'
  }
  const k = e.key.toLowerCase()
  if (map[k]) { e.preventDefault(); move(map[k]) }
  else if (k === 'r') reset()
  else if (k === 'z' || k === 'u') undo()
}

function onTouchStart(e) {
  const t = e.changedTouches[0]
  touchStart = { x: t.clientX, y: t.clientY }
}
function onTouchEnd(e) {
  if (!touchStart) return
  const t = e.changedTouches[0]
  const dx = t.clientX - touchStart.x, dy = t.clientY - touchStart.y
  touchStart = null
  if (Math.max(Math.abs(dx), Math.abs(dy)) < 24) return
  if (Math.abs(dx) > Math.abs(dy)) move(dx > 0 ? 'right' : 'left')
  else move(dy > 0 ? 'down' : 'up')
}

const PALETTE = {
  2: ['#1b3a5c', '#7af5f7'], 4: ['#1d4a63', '#8be9ff'], 8: ['#2b3f8f', '#a9c4ff'],
  16: ['#4b2f8f', '#c9a9ff'], 32: ['#6b2f8f', '#e3a9ff'], 64: ['#8f2f7a', '#ffa9e0'],
  128: ['#a83b5c', '#ffc0cf'], 256: ['#b85a3a', '#ffd0a9'], 512: ['#c07a2a', '#ffe0a0'],
  1024: ['#cf9a20', '#fff0a8'], 2048: ['#ff48c4', '#ffffff']
}
function tileStyle(v) {
  if (!v) return {}
  const [bg, fg] = PALETTE[v] || ['#ff48c4', '#fff']
  return {
    background: `linear-gradient(150deg, ${bg}, rgba(10,14,39,.6))`,
    color: fg,
    fontSize: v >= 1024 ? '20px' : v >= 128 ? '24px' : '28px'
  }
}

onMounted(() => { window.addEventListener('keydown', onKey); reset() })
onBeforeUnmount(() => window.removeEventListener('keydown', onKey))
</script>

<template>
  <div class="g2048">
    <div class="bar">
      <span>得分 <b>{{ score }}</b></span>
      <span>最高 <b>{{ best }}</b></span>
      <span>最大方块 <b>{{ maxTile || 2 }}</b></span>
      <span class="rec">通关 {{ record.clears || 0 }} 次</span>
    </div>
    <p class="status">{{ status }}</p>

    <div class="stage" @touchstart.passive="onTouchStart" @touchend.passive="onTouchEnd">
      <div class="board">
        <div v-for="(v, i) in cells" :key="i" class="tile" :class="{ empty: !v, hot: v >= 128 }" :style="tileStyle(v)">
          {{ v || '' }}
        </div>
      </div>
      <div v-if="won && !keepPlaying" class="overlay win">
        <WinStage theme="numbers" />
        <div class="ov-emoji">🎉</div>
        <h3>通关！2048 达成</h3>
        <p>得分 {{ score }} · 还可以继续冲击更高分</p>
        <div class="ov-btns">
          <button class="btn" @click="keepPlaying = true; status = '继续挑战：凑出更大的方块吧'">继续挑战</button>
          <button class="btn ghost" @click="reset">再来一局</button>
        </div>
      </div>
      <div v-if="over" class="overlay">
        <div class="ov-emoji">💥</div>
        <h3>无路可走</h3>
        <p>最终得分 {{ score }}</p>
        <button class="btn" @click="reset">再来一局</button>
      </div>
    </div>

    <div class="dpad">
      <button class="d up" @click="move('up')" aria-label="上">▲</button>
      <button class="d left" @click="move('left')" aria-label="左">◀</button>
      <button class="d right" @click="move('right')" aria-label="右">▶</button>
      <button class="d down" @click="move('down')" aria-label="下">▼</button>
    </div>
    <div class="actions">
      <button class="btn ghost" @click="undo" :disabled="!prev">撤销一步</button>
      <button class="btn" @click="reset">重新开始 (R)</button>
    </div>
    <p class="tip">方向键 / WASD 或手指滑动 · Z 撤销 · 合出 2048 即通关</p>
  </div>
</template>

<style scoped>
.g2048 { display: flex; flex-direction: column; align-items: center; gap: 10px; width: 100%; max-width: 380px; }
.bar {
  width: 100%; display: flex; flex-wrap: wrap; gap: 12px; align-items: center;
  padding: 10px 14px; border-radius: 12px; font-size: 12.5px; color: #cdd6f4;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .14);
}
.bar b { color: #fff; font-size: 15px; }
.bar .rec { margin-left: auto; color: var(--cyan-soft); }
.status { font-size: 13px; color: #9fb0d8; text-align: center; margin: 0; min-height: 18px; }

.stage { position: relative; }
.board {
  width: 340px; max-width: 100%; aspect-ratio: 1;
  display: grid; grid-template-columns: repeat(4, 1fr); grid-template-rows: repeat(4, 1fr); gap: 9px;
  padding: 10px; border-radius: 16px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .9), rgba(12, 14, 38, .9));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .45);
  touch-action: none;
}
.tile {
  display: grid; place-items: center; border-radius: 10px; font-weight: 800;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .16), 0 3px 10px rgba(0, 0, 0, .3);
  transition: background .18s;
}
.tile.empty { background: rgba(255, 255, 255, .045); box-shadow: none; }
.tile.hot { animation: hotTile 2.4s ease-in-out infinite; }
@keyframes hotTile {
  0%, 100% { box-shadow: inset 0 1px 0 rgba(255,255,255,.28), 0 0 10px rgba(var(--game-rgb), .28) }
  50% { box-shadow: inset 0 1px 0 rgba(255,255,255,.4), 0 0 22px 3px rgba(var(--game-rgb), .6) }
}

.overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 16px;
  background: rgba(8, 11, 32, .94); backdrop-filter: blur(5px); animation: pop .24s ease-out;
}
.overlay.win { background: rgba(28, 16, 4, .94); }
.overlay > :not(.ws) { position: relative; z-index: 2; }
@keyframes pop { from { opacity: 0; transform: scale(.94) } to { opacity: 1; transform: none } }
.ov-emoji { font-size: 44px; line-height: 1; }
.overlay h3 { font-size: 23px; font-weight: 800; color: var(--magenta); }
.overlay.win h3 { color: var(--cyan); text-shadow: 0 0 18px rgba(45, 226, 230, .5); }
.overlay p { font-size: 13px; color: #cdd6f4; }
.ov-btns { display: flex; gap: 10px; margin-top: 4px; }

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
.btn:disabled { opacity: .4; cursor: not-allowed; transform: none; }
.btn.ghost { color: #cdd6f4; background: rgba(255, 255, 255, .08); border: 1px solid rgba(255, 255, 255, .18); box-shadow: none; }
.btn.ghost:hover { color: #fff; border-color: var(--cyan); }
.tip { font-size: 11.5px; color: #7e8ab0; text-align: center; margin: 0; }
</style>
