<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'

const COLS = 20
const ROWS = 20
const CELL = 18
const HS_KEY = 'lc_snake_highscore'

const canvasRef = ref(null)
const score = ref(0)
const highScore = ref(Number(localStorage.getItem(HS_KEY) || 0))
const running = ref(false)
const paused = ref(false)
const gameOver = ref(false)
const won = ref(false)
const statusText = ref('点击棋盘或「开始」开局')

let ctx = null
let snake = []
let dir = { x: 1, y: 0 }
let nextDir = { x: 1, y: 0 }
let food = null
let timer = null
const speed = 130

function reset() {
  snake = [
    { x: 8, y: 10 },
    { x: 7, y: 10 },
    { x: 6, y: 10 }
  ]
  dir = { x: 1, y: 0 }
  nextDir = { x: 1, y: 0 }
  score.value = 0
  gameOver.value = false
  won.value = false
  paused.value = false
  placeFood()
  draw()
}

function placeFood() {
  const free = []
  for (let y = 0; y < ROWS; y++)
    for (let x = 0; x < COLS; x++)
      if (!snake.some((s) => s.x === x && s.y === y)) free.push({ x, y })
  food = free.length ? free[(Math.random() * free.length) | 0] : null
}

function roundRect(c, x, y, w, h, r) {
  c.beginPath()
  c.moveTo(x + r, y)
  c.arcTo(x + w, y, x + w, y + h, r)
  c.arcTo(x + w, y + h, x, y + h, r)
  c.arcTo(x, y + h, x, y, r)
  c.arcTo(x, y, x + w, y, r)
  c.closePath()
}

function draw() {
  if (!ctx) return
  const W = COLS * CELL
  const H = ROWS * CELL
  ctx.fillStyle = '#0c1130'
  ctx.fillRect(0, 0, W, H)
  ctx.strokeStyle = 'rgba(255,255,255,0.06)'
  ctx.lineWidth = 1
  for (let i = 0; i <= COLS; i++) {
    ctx.beginPath(); ctx.moveTo(i * CELL, 0); ctx.lineTo(i * CELL, H); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(0, i * CELL); ctx.lineTo(W, i * CELL); ctx.stroke()
  }
  if (food) {
    ctx.fillStyle = '#ff48c4'
    ctx.shadowColor = '#ff48c4'
    ctx.shadowBlur = 12
    ctx.beginPath()
    ctx.arc(food.x * CELL + CELL / 2, food.y * CELL + CELL / 2, CELL / 2 - 2, 0, Math.PI * 2)
    ctx.fill()
    ctx.shadowBlur = 0
  }
  snake.forEach((s, i) => {
    const isHead = i === 0
    ctx.fillStyle = isHead ? '#2de2e6' : i % 2 ? '#8a5cff' : '#5fd3ff'
    ctx.shadowColor = '#2de2e6'
    ctx.shadowBlur = isHead ? 14 : 0
    roundRect(ctx, s.x * CELL + 1, s.y * CELL + 1, CELL - 2, CELL - 2, 4)
    ctx.fill()
    ctx.shadowBlur = 0
  })
}

function step() {
  dir = nextDir
  const head = { x: snake[0].x + dir.x, y: snake[0].y + dir.y }
  if (head.x < 0 || head.y < 0 || head.x >= COLS || head.y >= ROWS) return endGame()
  if (snake.some((s) => s.x === head.x && s.y === head.y)) return endGame()
  snake.unshift(head)
  if (food && head.x === food.x && head.y === food.y) {
    score.value += 10
    if (score.value > highScore.value) {
      highScore.value = score.value
      localStorage.setItem(HS_KEY, String(highScore.value))
    }
    placeFood()
    if (snake.length >= COLS * ROWS) return winGame()
  } else {
    snake.pop()
  }
  draw()
}

function startLoop() {
  if (timer) clearInterval(timer)
  timer = setInterval(step, speed)
}

function startGame() {
  reset()
  running.value = true
  statusText.value = '进行中 · 方向键 / WASD / 屏幕按钮控制'
  startLoop()
}

function togglePause() {
  if (!running.value || gameOver.value) return
  paused.value = !paused.value
  if (paused.value) {
    clearInterval(timer); timer = null
    statusText.value = '已暂停 · 点继续或空格'
  } else {
    statusText.value = '进行中 · 方向键 / WASD / 屏幕按钮控制'
    startLoop()
  }
}

function endGame() {
  running.value = false
  gameOver.value = true
  won.value = false
  clearInterval(timer); timer = null
  statusText.value = '游戏结束 · 得分 ' + score.value + '（点「重新开始」再来）'
}

function winGame() {
  running.value = false
  gameOver.value = true
  won.value = true
  clearInterval(timer); timer = null
  statusText.value = '🎉 通关！你填满了整个棋盘 · 得分 ' + score.value
}

// 屏幕方向按钮 / 点击棋盘也可控制
function move(dx, dy) {
  if (!running.value || paused.value || gameOver.value) return
  if (dx !== 0 && dir.x !== -dx) nextDir = { x: dx, y: 0 }
  if (dy !== 0 && dir.y !== -dy) nextDir = { x: 0, y: dy }
}

function onKey(e) {
  const k = e.key.toLowerCase()
  if (k === ' ' || e.code === 'Space') {
    e.preventDefault()
    if (gameOver.value) startGame()
    else if (!running.value) startGame()
    else togglePause()
    return
  }
  if (!running.value || paused.value || gameOver.value) return
  if (k === 'arrowup' || k === 'w') { if (dir.y !== 1) nextDir = { x: 0, y: -1 } }
  else if (k === 'arrowdown' || k === 's') { if (dir.y !== -1) nextDir = { x: 0, y: 1 } }
  else if (k === 'arrowleft' || k === 'a') { if (dir.x !== 1) nextDir = { x: -1, y: 0 } }
  else if (k === 'arrowright' || k === 'd') { if (dir.x !== -1) nextDir = { x: 1, y: 0 } }
  if (['arrowup', 'arrowdown', 'arrowleft', 'arrowright'].includes(k)) e.preventDefault()
}

const primaryLabel = () =>
  gameOver.value ? '重新开始' : running.value ? (paused.value ? '继续' : '暂停') : '开始'

onMounted(() => {
  ctx = canvasRef.value.getContext('2d')
  reset()
  window.addEventListener('keydown', onKey)
})
onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey)
  if (timer) clearInterval(timer)
})
</script>

<template>
  <div class="game-box">
    <div class="game-head">
      <span class="g-score">得分 <b>{{ score }}</b></span>
      <span class="g-high">最高 <b>{{ highScore }}</b></span>
      <span class="g-status">{{ statusText }}</span>
    </div>

    <div class="canvas-wrap">
      <canvas ref="canvasRef" :width="COLS * CELL" :height="ROWS * CELL" class="g-canvas"
        @click="!running && !gameOver ? startGame() : null"></canvas>
      <div v-if="!running && !gameOver" class="start-overlay" @click="startGame">
        <div class="so-title">🐍 贪吃蛇</div>
        <div class="so-btn">点击开始</div>
        <div class="so-hint">方向键 / WASD 或下方按钮控制 · 空格暂停</div>
      </div>
      <div v-if="paused" class="pause-overlay">已暂停</div>
      <div v-if="gameOver" class="result-overlay" :class="{ win: won }" @click="startGame">
        <div class="r-emoji">{{ won ? '🎉' : '💥' }}</div>
        <div class="r-title">{{ won ? '通关！' : '游戏结束' }}</div>
        <div class="r-sub">{{ won ? '你填满了整个棋盘' : '得分 ' + score }}</div>
        <div class="r-btn">再来一局</div>
      </div>
    </div>

    <!-- 屏幕方向键：不依赖键盘焦点，手机/预览也能玩 -->
    <div class="dpad" :class="{ disabled: !running || gameOver }">
      <button class="dbtn up" @click="move(0, -1)" aria-label="上">▲</button>
      <button class="dbtn left" @click="move(-1, 0)" aria-label="左">◀</button>
      <button class="dbtn right" @click="move(1, 0)" aria-label="右">▶</button>
      <button class="dbtn down" @click="move(0, 1)" aria-label="下">▼</button>
    </div>

    <div class="g-actions">
      <button class="g-btn" @click="running && !gameOver ? togglePause() : startGame()">
        {{ primaryLabel() }}
      </button>
      <button class="g-btn ghost" @click="startGame">重置</button>
    </div>
    <p class="g-tip">方向键 / WASD / 屏幕按钮移动 · 空格 开始 / 暂停</p>
  </div>
</template>

<style scoped>
.game-box {
  display: flex; flex-direction: column; align-items: center; gap: 12px;
  padding: 16px; border-radius: 16px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14);
  box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
}
.game-head {
  width: 100%; display: flex; align-items: center; gap: 14px;
  font-size: 13px; color: #cdd6f4;
}
.g-score b, .g-high b { color: #fff; font-size: 15px; }
.g-high { color: #9fb0d8; }
.g-status { margin-left: auto; color: var(--cyan-soft); font-size: 12.5px; text-align: right; }

.canvas-wrap { position: relative; line-height: 0; }
.g-canvas {
  width: 360px; max-width: 100%; height: auto; border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, .12); background: #0c1130;
  touch-action: none; cursor: pointer; display: block;
}
.start-overlay, .pause-overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 12px;
  background: rgba(8, 11, 32, .78); cursor: pointer; backdrop-filter: blur(2px);
}
.pause-overlay { font-size: 20px; font-weight: 700; color: #fff; letter-spacing: 2px; }
.so-title { font-size: 22px; }
.so-btn {
  font-size: 16px; font-weight: 700; color: #04121f; padding: 10px 26px; border-radius: 12px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .4);
}
.so-hint { font-size: 12px; color: #aeb9dd; }

.result-overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 12px;
  background: rgba(8, 11, 32, .82); cursor: pointer; backdrop-filter: blur(3px);
  animation: pop .25s ease-out;
}
@keyframes pop { from { opacity: 0; transform: scale(.9); } to { opacity: 1; transform: scale(1); } }
.r-emoji { font-size: 44px; line-height: 1; }
.r-title { font-size: 24px; font-weight: 800; }
.r-title, .r-sub { color: #fff; text-align: center; }
.r-sub { font-size: 13px; color: #cdd6f4; }
.result-overlay.win .r-title { color: #2de2e6; text-shadow: 0 0 16px rgba(45,226,230,.6); }
.result-overlay:not(.win) .r-title { color: #ff48c4; }
.r-btn {
  margin-top: 6px; font-size: 15px; font-weight: 700; color: #04121f; padding: 10px 28px; border-radius: 12px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .4);
}

/* 屏幕方向键 */
.dpad {
  display: grid; grid-template-columns: repeat(3, 46px); grid-template-rows: repeat(3, 46px);
  gap: 6px; margin-top: 2px;
}
.dpad.disabled { opacity: .35; pointer-events: none; }
.dbtn {
  border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .06);
  color: #eef2ff; font-size: 18px; border-radius: 12px; cursor: pointer; transition: .15s;
  display: grid; place-items: center;
}
.dbtn:hover { border-color: var(--cyan); color: #fff; }
.dbtn:active { transform: scale(.94); background: rgba(45, 226, 230, .2); }
.dbtn.up { grid-area: 1 / 2; }
.dbtn.left { grid-area: 2 / 1; }
.dbtn.right { grid-area: 2 / 3; }
.dbtn.down { grid-area: 3 / 2; }

.g-actions { display: flex; gap: 10px; }
.g-btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 14px; font-weight: 600; color: #04121f;
  padding: 9px 22px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .35); transition: .25s;
}
.g-btn:hover { transform: translateY(-1px); }
.g-btn.ghost {
  color: #cdd6f4; background: rgba(255, 255, 255, .08); border: 1px solid rgba(255, 255, 255, .18);
  box-shadow: none;
}
.g-btn.ghost:hover { color: #fff; border-color: var(--cyan); }
.g-tip { font-size: 12px; color: #9fb0d8; margin: 0; }
</style>
