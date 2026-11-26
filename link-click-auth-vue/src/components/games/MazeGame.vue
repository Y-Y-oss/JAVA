<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { getRecord, saveRecord } from '../../utils/gameScore'
import WinStage from './WinStage.vue'

/**
 * 时光迷宫 · 闯关小游戏
 * 5 关随机迷宫（递归回溯生成 + 少量环路），逐关变大。
 * 每关要先集齐散落的「时光碎片」出口才会开启，走到出口即过关。
 * 全程计时 / 步数 / 最高关卡 / 最快通关时间记录在本机。
 */
const LEVELS = [
  { size: 11, shards: 2 },
  { size: 13, shards: 3 },
  { size: 15, shards: 3 },
  { size: 17, shards: 4 },
  { size: 21, shards: 4 }
]
const TOTAL = LEVELS.length
const CANVAS_W = 420

const canvasRef = ref(null)
const level = ref(1)
const moves = ref(0)
const elapsed = ref(0)
const shardsLeft = ref(0)
const status = ref('用方向键 / WASD 或下方按钮移动，收集碎片后抵达出口')
const phase = ref('play') // play | levelClear | allClear
const hintOn = ref(false)
const record = ref(getRecord('maze'))

const bestText = computed(() => {
  const r = record.value
  if (r.bestTime) return `最快全通 ${r.bestTime}s · 通关 ${r.clears || 0} 次`
  if (r.maxLevel) return `最高第 ${r.maxLevel} 关`
  return '尚无记录'
})
const fmt = (s) => {
  const v = Math.max(0, Math.floor(s || 0))
  return v >= 60 ? `${Math.floor(v / 60)}:${String(v % 60).padStart(2, '0')}` : `${v}s`
}

let ctx = null
let maze = []
let player = { r: 1, c: 1 }
let exit = { r: 1, c: 1 }
let shards = []
let trail = []
let cell = 20
let hintPath = []
let timer = null
let timeBase = 0

function roundRect(c, x, y, w, h, r) {
  c.beginPath()
  c.moveTo(x + r, y)
  c.arcTo(x + w, y, x + w, y + h, r)
  c.arcTo(x + w, y + h, x, y + h, r)
  c.arcTo(x, y + h, x, y, r)
  c.arcTo(x, y, x + w, y, r)
  c.closePath()
}

/** 递归回溯生成完美迷宫，再随机打通若干墙形成环路，减少死路 */
function genMaze(size) {
  const g = Array.from({ length: size }, () => Array(size).fill(1))
  const stack = [[1, 1]]
  g[1][1] = 0
  const dirs = [[0, 2], [2, 0], [0, -2], [-2, 0]]
  while (stack.length) {
    const [r, c] = stack[stack.length - 1]
    const opts = []
    for (const [dr, dc] of dirs) {
      const nr = r + dr, nc = c + dc
      if (nr > 0 && nr < size - 1 && nc > 0 && nc < size - 1 && g[nr][nc] === 1) {
        opts.push([nr, nc, r + dr / 2, c + dc / 2])
      }
    }
    if (!opts.length) { stack.pop(); continue }
    const [nr, nc, mr, mc] = opts[(Math.random() * opts.length) | 0]
    g[mr][mc] = 0
    g[nr][nc] = 0
    stack.push([nr, nc])
  }
  for (let i = 0, extra = Math.floor(size * size * 0.05); i < extra; i++) {
    const r = 1 + ((Math.random() * (size - 2)) | 0)
    const c = 1 + ((Math.random() * (size - 2)) | 0)
    if (g[r][c] !== 1) continue
    const horiz = g[r][c - 1] === 0 && g[r][c + 1] === 0
    const vert = g[r - 1][c] === 0 && g[r + 1][c] === 0
    if (horiz || vert) g[r][c] = 0
  }
  return g
}

function bfs(from, to) {
  const n = maze.length
  const k = (r, c) => r * n + c
  const q = [from]
  const prev = new Map()
  const seen = new Set([k(from.r, from.c)])
  while (q.length) {
    const cur = q.shift()
    if (cur.r === to.r && cur.c === to.c) {
      const path = []
      let node = cur, key = k(cur.r, cur.c)
      while (node) {
        path.unshift({ r: node.r, c: node.c })
        node = prev.get(key)
        if (node) key = k(node.r, node.c)
      }
      return path
    }
    for (const [dr, dc] of [[0, 1], [1, 0], [0, -1], [-1, 0]]) {
      const r = cur.r + dr, c = cur.c + dc
      if (r < 0 || c < 0 || r >= n || c >= n || maze[r][c] === 1 || seen.has(k(r, c))) continue
      seen.add(k(r, c))
      prev.set(k(r, c), cur)
      q.push({ r, c })
    }
  }
  return []
}

/** 提示目标：还有碎片时指向最近的碎片，否则指向出口 */
function targetCell() {
  if (!shards.length) return exit
  let best = null, bestLen = Infinity
  for (const s of shards) {
    const p = bfs(player, s)
    if (p.length && p.length < bestLen) { bestLen = p.length; best = s }
  }
  return best || exit
}

function refreshHint() {
  hintPath = hintOn.value ? bfs(player, targetCell()) : []
}

function setupLevel(n) {
  const conf = LEVELS[n - 1]
  maze = genMaze(conf.size)
  cell = Math.floor(CANVAS_W / conf.size)
  player = { r: 1, c: 1 }
  exit = { r: conf.size - 2, c: conf.size - 2 }
  maze[1][1] = 0
  maze[exit.r][exit.c] = 0

  const pool = []
  for (let r = 1; r < conf.size - 1; r++) {
    for (let c = 1; c < conf.size - 1; c++) {
      if (maze[r][c] !== 0) continue
      if (r === 1 && c === 1) continue
      if (r === exit.r && c === exit.c) continue
      if (Math.abs(r - 1) + Math.abs(c - 1) < 4) continue
      pool.push({ r, c })
    }
  }
  for (let i = pool.length - 1; i > 0; i--) {
    const j = (Math.random() * (i + 1)) | 0
    ;[pool[i], pool[j]] = [pool[j], pool[i]]
  }
  shards = pool.slice(0, conf.shards).map((p) => ({ ...p }))
  shardsLeft.value = shards.length

  trail = []
  moves.value = 0
  hintOn.value = false
  hintPath = []
  phase.value = 'play'
  status.value = `第 ${n} / ${TOTAL} 关 · 收集 ${shards.length} 枚时光碎片，开启出口`
  saveRecord('maze', { maxLevel: Math.max(record.value.maxLevel || 0, n) })
  record.value = getRecord('maze')

  nextTick(fitCanvas)
  draw()
  startTimer()
}

function startTimer() {
  if (timer) clearInterval(timer)
  timeBase = Date.now() - elapsed.value * 1000
  timer = setInterval(() => {
    if (phase.value === 'play') elapsed.value = Math.floor((Date.now() - timeBase) / 1000)
  }, 200)
}

function fitCanvas() {
  const cv = canvasRef.value
  if (!cv) return
  const size = maze.length * cell
  cv.width = size
  cv.height = size
  cv.style.maxWidth = size + 'px'
  ctx = cv.getContext('2d')
  draw()
}

function draw() {
  if (!ctx || !maze.length) return
  const n = maze.length, size = n * cell
  const c = ctx
  c.clearRect(0, 0, size, size)
  const bg = c.createLinearGradient(0, 0, size, size)
  bg.addColorStop(0, '#0d1430')
  bg.addColorStop(1, '#161033')
  c.fillStyle = bg
  c.fillRect(0, 0, size, size)

  for (let r = 0; r < n; r++) {
    for (let col = 0; col < n; col++) {
      const x = col * cell, y = r * cell
      if (maze[r][col] === 1) {
        c.fillStyle = 'rgba(138,92,255,.30)'
        c.fillRect(x, y, cell, cell)
        c.strokeStyle = 'rgba(160,130,255,.16)'
        c.lineWidth = 1
        c.strokeRect(x + .5, y + .5, cell - 1, cell - 1)
      } else {
        c.fillStyle = 'rgba(45,226,230,.035)'
        c.fillRect(x, y, cell, cell)
      }
    }
  }

  // 走过的轨迹
  trail.forEach((p, i) => {
    c.fillStyle = `rgba(122,245,247,${((i + 1) / trail.length * .26).toFixed(3)})`
    c.fillRect(p.c * cell + cell * .38, p.r * cell + cell * .38, cell * .24, cell * .24)
  })

  // 路径提示
  if (hintOn.value && hintPath.length > 1) {
    c.strokeStyle = 'rgba(122,245,247,.5)'
    c.lineWidth = Math.max(2, cell * .2)
    c.lineJoin = 'round'
    c.lineCap = 'round'
    c.beginPath()
    hintPath.forEach((p, i) => {
      const x = p.c * cell + cell / 2, y = p.r * cell + cell / 2
      if (i) c.lineTo(x, y); else c.moveTo(x, y)
    })
    c.stroke()
  }

  // 时光碎片
  shards.forEach((s) => {
    const x = s.c * cell + cell / 2, y = s.r * cell + cell / 2, rad = Math.max(4, cell * .3)
    c.save()
    c.shadowColor = '#ff48c4'
    c.shadowBlur = 12
    c.fillStyle = '#ff8ad8'
    c.beginPath()
    c.moveTo(x, y - rad); c.lineTo(x + rad, y); c.lineTo(x, y + rad); c.lineTo(x - rad, y)
    c.closePath(); c.fill()
    c.restore()
  })

  // 出口
  const ex = exit.c * cell, ey = exit.r * cell, open = shards.length === 0
  c.save()
  if (open) { c.shadowColor = '#2de2e6'; c.shadowBlur = 14; c.fillStyle = 'rgba(45,226,230,.4)' }
  else { c.fillStyle = 'rgba(138,92,255,.28)' }
  roundRect(c, ex + 2, ey + 2, cell - 4, cell - 4, 4); c.fill()
  c.shadowBlur = 0
  c.strokeStyle = open ? '#7af5f7' : 'rgba(190,180,225,.6)'
  c.lineWidth = 1.5
  roundRect(c, ex + 2, ey + 2, cell - 4, cell - 4, 4); c.stroke()
  c.fillStyle = open ? '#04121f' : '#d6cfee'
  c.font = `bold ${Math.max(7, Math.floor(cell * .38))}px sans-serif`
  c.textAlign = 'center'; c.textBaseline = 'middle'
  c.fillText(open ? 'OUT' : 'LOCK', ex + cell / 2, ey + cell / 2)
  c.restore()

  // 玩家
  const px = player.c * cell + cell / 2, py = player.r * cell + cell / 2
  const rad = Math.max(4, cell * .33)
  const g = c.createRadialGradient(px - rad * .3, py - rad * .3, rad * .2, px, py, rad)
  g.addColorStop(0, '#ffffff'); g.addColorStop(.45, '#7af5f7'); g.addColorStop(1, '#2de2e6')
  c.save()
  c.shadowColor = '#2de2e6'; c.shadowBlur = 14
  c.fillStyle = g
  c.beginPath(); c.arc(px, py, rad, 0, Math.PI * 2); c.fill()
  c.restore()
}

function move(dr, dc) {
  if (phase.value !== 'play') return
  const nr = player.r + dr, nc = player.c + dc
  if (nr < 0 || nc < 0 || nr >= maze.length || nc >= maze.length) return
  if (maze[nr][nc] === 1) { status.value = '前面是墙，换条路试试'; return }
  player = { r: nr, c: nc }
  moves.value++
  trail.push({ r: nr, c: nc })
  if (trail.length > 14) trail.shift()

  const i = shards.findIndex((s) => s.r === nr && s.c === nc)
  if (i >= 0) {
    shards.splice(i, 1)
    shardsLeft.value = shards.length
    status.value = shards.length ? `拿到碎片！还差 ${shards.length} 枚` : '碎片集齐，出口已开启 ✨'
  }
  refreshHint()
  draw()

  if (nr === exit.r && nc === exit.c) {
    if (shards.length) { status.value = `出口还锁着，先找齐 ${shards.length} 枚碎片`; return }
    onLevelClear()
  }
}

function onLevelClear() {
  if (timer) { clearInterval(timer); timer = null }
  if (level.value >= TOTAL) {
    phase.value = 'allClear'
    const patch = { clears: (record.value.clears || 0) + 1, maxLevel: TOTAL }
    if (!record.value.bestTime || elapsed.value < record.value.bestTime) patch.bestTime = elapsed.value
    if (!record.value.bestMoves || moves.value < record.value.bestMoves) patch.bestMoves = moves.value
    saveRecord('maze', patch)
    record.value = getRecord('maze')
    status.value = `🏆 全部 ${TOTAL} 关通关！用时 ${fmt(elapsed.value)} · ${moves.value} 步`
  } else {
    phase.value = 'levelClear'
    status.value = `🎉 第 ${level.value} 关通过！用时 ${fmt(elapsed.value)}`
  }
}

function nextLevel() {
  level.value++
  setupLevel(level.value)
}
function restartAll() {
  if (timer) { clearInterval(timer); timer = null }
  elapsed.value = 0
  level.value = 1
  setupLevel(1)
}
function toggleHint() {
  hintOn.value = !hintOn.value
  status.value = hintOn.value ? '已显示通往下一个目标的最短路径' : '提示已隐藏'
  refreshHint()
  draw()
}

function onKey(e) {
  const map = {
    arrowup: [-1, 0], w: [-1, 0], arrowdown: [1, 0], s: [1, 0],
    arrowleft: [0, -1], a: [0, -1], arrowright: [0, 1], d: [0, 1]
  }
  const k = e.key.toLowerCase()
  if (map[k]) { e.preventDefault(); move(map[k][0], map[k][1]) }
  else if (k === 'h') toggleHint()
  else if (k === 'r') restartAll()
}

onMounted(() => {
  window.addEventListener('keydown', onKey)
  setupLevel(1)
})
onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey)
  if (timer) clearInterval(timer)
})
</script>

<template>
  <div class="mz">
    <div class="mz-bar">
      <span>关卡 <b>{{ level }}/{{ TOTAL }}</b></span>
      <span>碎片 <b>{{ shardsLeft }}</b></span>
      <span>步数 <b>{{ moves }}</b></span>
      <span>用时 <b>{{ fmt(elapsed) }}</b></span>
      <span class="mz-best">{{ bestText }}</span>
    </div>
    <p class="mz-status">{{ status }}</p>

    <div class="mz-stage">
      <canvas ref="canvasRef" class="mz-canvas"></canvas>
      <div v-if="phase !== 'play'" class="mz-overlay">
        <WinStage theme="space" />
        <div class="mz-ov-emoji">{{ phase === 'allClear' ? '🏆' : '🎉' }}</div>
        <h3>{{ phase === 'allClear' ? '全部通关！' : '第 ' + level + ' 关通过' }}</h3>
        <p>
          {{ phase === 'allClear'
            ? `用时 ${fmt(elapsed)} · ${moves} 步，五座迷宫全部走通`
            : '准备好挑战更大的迷宫了吗？' }}
        </p>
        <div class="mz-ov-btns">
          <button v-if="phase === 'levelClear'" class="mz-btn" @click="nextLevel">下一关 →</button>
          <button class="mz-btn ghost" @click="restartAll">从第 1 关重来</button>
        </div>
      </div>
    </div>

    <div class="mz-dpad">
      <button class="mz-d up" @click="move(-1, 0)" aria-label="上">▲</button>
      <button class="mz-d left" @click="move(0, -1)" aria-label="左">◀</button>
      <button class="mz-d right" @click="move(0, 1)" aria-label="右">▶</button>
      <button class="mz-d down" @click="move(1, 0)" aria-label="下">▼</button>
    </div>

    <div class="mz-actions">
      <button class="mz-btn" @click="toggleHint">{{ hintOn ? '隐藏提示' : '路径提示 (H)' }}</button>
      <button class="mz-btn ghost" @click="restartAll">重新开始 (R)</button>
    </div>
    <p class="mz-tip">方向键 / WASD 或屏幕按钮移动 · 集齐碎片出口才开启 · 通关全部 5 关即大通关</p>
  </div>
</template>

<style scoped>
.mz { width: 100%; max-width: 460px; display: flex; flex-direction: column; align-items: center; gap: 10px; }
.mz-bar {
  width: 100%; display: flex; flex-wrap: wrap; align-items: center; gap: 14px;
  font-size: 12.5px; color: #cdd6f4; padding: 10px 14px; border-radius: 12px;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .14);
}
.mz-bar b { color: #fff; font-size: 14px; }
.mz-best { margin-left: auto; color: var(--cyan-soft); font-size: 11.5px; }
.mz-status { font-size: 13px; color: #9fb0d8; text-align: center; margin: 0; min-height: 18px; }

.mz-stage { position: relative; width: 100%; display: flex; justify-content: center; line-height: 0; }
.mz-canvas {
  width: 100%; height: auto; display: block; border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .45);
  touch-action: none;
}
.mz-overlay {
  position: absolute; inset: 0; z-index: 2; line-height: 1.5;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px;
  border-radius: 14px; background: rgba(8, 11, 32, .86); backdrop-filter: blur(4px);
  animation: mzPop .26s ease-out;
}
@keyframes mzPop { from { opacity: 0; transform: scale(.94) } to { opacity: 1; transform: none } }
.mz-ov-emoji { font-size: 46px; line-height: 1; }
.mz-overlay h3 { font-size: 24px; font-weight: 800; color: var(--cyan); text-shadow: 0 0 18px rgba(45, 226, 230, .5); }
.mz-overlay p { font-size: 13px; color: #cdd6f4; text-align: center; padding: 0 14px; }
.mz-ov-btns { display: flex; gap: 10px; margin-top: 6px; flex-wrap: wrap; justify-content: center; }

.mz-dpad { display: grid; grid-template-columns: repeat(3, 44px); grid-template-rows: repeat(3, 44px); gap: 6px; }
.mz-d {
  border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .06);
  color: #eef2ff; font-size: 17px; border-radius: 11px; cursor: pointer; transition: .15s;
  display: grid; place-items: center;
}
.mz-d:hover { border-color: var(--cyan); color: #fff; }
.mz-d:active { transform: scale(.93); background: rgba(45, 226, 230, .2); }
.mz-d.up { grid-area: 1 / 2; } .mz-d.left { grid-area: 2 / 1; }
.mz-d.right { grid-area: 2 / 3; } .mz-d.down { grid-area: 3 / 2; }

.mz-actions { display: flex; gap: 10px; flex-wrap: wrap; justify-content: center; }
.mz-btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13.5px; font-weight: 600; color: #04121f;
  padding: 9px 20px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .35); transition: .22s;
}
.mz-btn:hover { transform: translateY(-1px); }
.mz-btn.ghost { color: #cdd6f4; background: rgba(255, 255, 255, .08); border: 1px solid rgba(255, 255, 255, .18); box-shadow: none; }
.mz-btn.ghost:hover { color: #fff; border-color: var(--cyan); }
.mz-tip { font-size: 11.5px; color: #7e8ab0; text-align: center; margin: 0; line-height: 1.6; }
/* 时空隧道胜利舞台：内容浮在装饰层之上 */
.mz-overlay { background: rgba(8, 11, 32, .68); }
.mz-overlay > :not(.ws) { position: relative; z-index: 2; }
</style>
