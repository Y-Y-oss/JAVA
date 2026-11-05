<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'

const SIZE = 15
const CELL = 26
const PAD = 18
const EMPTY = 0
const BLACK = 1 // 玩家
const WHITE = 2 // AI

const canvasRef = ref(null)
const statusText = ref('你执黑先手 · 点击棋盘落子')
const gameOver = ref(false)
const winner = ref(0) // 0 未结束 / 1 黑胜 / 2 白胜 / 3 平局

const winnerText = computed(() => {
  if (winner.value === 1) return '你赢了！'
  if (winner.value === 2) return 'AI 获胜'
  if (winner.value === 3) return '平局'
  return ''
})
const winnerEmoji = computed(() => {
  if (winner.value === 1) return '🎉'
  if (winner.value === 2) return '🤖'
  if (winner.value === 3) return '🤝'
  return ''
})
const winnerSub = computed(() => {
  if (winner.value === 1) return '五子连珠 · 恭喜过关！'
  if (winner.value === 2) return '再接再厉，下一局翻盘'
  if (winner.value === 3) return '棋盘已下满'
  return ''
})
const winnerClass = computed(() => {
  if (winner.value === 1) return 'win'
  if (winner.value === 2) return 'lose'
  if (winner.value === 3) return 'draw'
  return ''
})

let ctx = null
let board = []
let current = BLACK
let aiThinking = false
let over = false
let lastMove = null

function inBounds(x, y) { return x >= 0 && y >= 0 && x < SIZE && y < SIZE }
function newBoard() { return Array.from({ length: SIZE }, () => Array(SIZE).fill(EMPTY)) }

function reset() {
  board = newBoard()
  current = BLACK
  over = false
  gameOver.value = false
  winner.value = 0
  aiThinking = false
  lastMove = null
  statusText.value = '你执黑先手 · 点击棋盘落子'
  draw()
}

function draw() {
  if (!ctx) return
  const W = SIZE * CELL + PAD * 2
  const H = W
  ctx.fillStyle = '#e9d9b8'
  ctx.fillRect(0, 0, W, H)
  ctx.strokeStyle = 'rgba(80,60,30,0.55)'
  ctx.lineWidth = 1
  for (let i = 0; i < SIZE; i++) {
    ctx.beginPath(); ctx.moveTo(PAD + i * CELL, PAD); ctx.lineTo(PAD + i * CELL, PAD + (SIZE - 1) * CELL); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(PAD, PAD + i * CELL); ctx.lineTo(PAD + (SIZE - 1) * CELL, PAD + i * CELL); ctx.stroke()
  }
  // 星位
  const stars = [3, 7, 11]
  ctx.fillStyle = 'rgba(80,60,30,0.7)'
  for (const sx of stars) for (const sy of stars) {
    ctx.beginPath(); ctx.arc(PAD + sx * CELL, PAD + sy * CELL, 3.2, 0, Math.PI * 2); ctx.fill()
  }
  // 棋子
  for (let y = 0; y < SIZE; y++) for (let x = 0; x < SIZE; x++) {
    if (board[y][x] !== EMPTY) drawStone(x, y, board[y][x])
  }
  // 最后一手标记
  if (lastMove) {
    ctx.strokeStyle = lastMove.color === BLACK ? '#ff48c4' : '#2de2e6'
    ctx.lineWidth = 2
    ctx.beginPath()
    ctx.arc(PAD + lastMove.x * CELL, PAD + lastMove.y * CELL, 4, 0, Math.PI * 2)
    ctx.stroke()
  }
}

function drawStone(x, y, color) {
  const cx = PAD + x * CELL
  const cy = PAD + y * CELL
  const r = CELL / 2 - 2
  const g = ctx.createRadialGradient(cx - r / 3, cy - r / 3, r / 4, cx, cy, r)
  if (color === BLACK) { g.addColorStop(0, '#5a6478'); g.addColorStop(1, '#0b0e1a') }
  else { g.addColorStop(0, '#ffffff'); g.addColorStop(1, '#c4ccdd') }
  ctx.fillStyle = g
  ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
  ctx.strokeStyle = 'rgba(0,0,0,0.25)'; ctx.lineWidth = 1; ctx.stroke()
}

function checkWin(x, y, color) {
  const dirs = [[1, 0], [0, 1], [1, 1], [1, -1]]
  for (const [dx, dy] of dirs) {
    let count = 1
    for (let s = 1; s < 5; s++) {
      const nx = x + dx * s, ny = y + dy * s
      if (inBounds(nx, ny) && board[ny][nx] === color) count++; else break
    }
    for (let s = 1; s < 5; s++) {
      const nx = x - dx * s, ny = y - dy * s
      if (inBounds(nx, ny) && board[ny][nx] === color) count++; else break
    }
    if (count >= 5) return true
  }
  return false
}

function place(x, y, color) {
  board[y][x] = color
  lastMove = { x, y }
  draw()
  if (checkWin(x, y, color)) {
    over = true
    gameOver.value = true
    winner.value = color
    statusText.value = color === BLACK ? '🎉 你赢了！' : 'AI 赢了，再来一局？'
    draw()
    return true
  }
  // 平局
  let full = true
  for (let yy = 0; yy < SIZE; yy++) for (let xx = 0; xx < SIZE; xx++)
    if (board[yy][xx] === EMPTY) { full = false; break }
  if (full) { over = true; gameOver.value = true; winner.value = 3; statusText.value = '平局！'; draw(); return true }
  return false
}

function lineScore(count, open) {
  if (count >= 5) return 100000
  if (count === 4) return open === 2 ? 12000 : open === 1 ? 1500 : 0
  if (count === 3) return open === 2 ? 1200 : open === 1 ? 150 : 0
  if (count === 2) return open === 2 ? 120 : open === 1 ? 20 : 0
  if (count === 1) return open === 2 ? 12 : 2
  return 0
}

// 只防守「已存在的三/四」的端点（相邻已有 >=3 子），不预堵「二」的延伸点 → 玩家可用 3-3 fork 取胜
function blockScore(x, y, color) {
  const dirs = [[1, 0], [0, 1], [1, 1], [1, -1]]
  let best = 0
  for (const [dx, dy] of dirs) {
    let c = 0
    let nx = x + dx, ny = y + dy
    while (inBounds(nx, ny) && board[ny][nx] === color) { c++; nx += dx; ny += dy }
    const openA = inBounds(nx, ny) && board[ny][nx] === EMPTY
    nx = x - dx; ny = y - dy
    while (inBounds(nx, ny) && board[ny][nx] === color) { c++; nx -= dx; ny -= dy }
    const openB = inBounds(nx, ny) && board[ny][nx] === EMPTY
    if (c >= 3) best = Math.max(best, lineScore(c + 1, (openA ? 1 : 0) + (openB ? 1 : 0)))
  }
  return best
}

function aiMove() {
  aiThinking = true
  statusText.value = 'AI 思考中…'
  setTimeout(() => {
    let best = null
    let bestScore = -1
    for (let y = 0; y < SIZE; y++) for (let x = 0; x < SIZE; x++) {
      if (board[y][x] !== EMPTY) continue
      // 只看离已有棋子 2 格内的点，减少无意义落子
      let near = false
      for (let dy = -2; dy <= 2 && !near; dy++)
        for (let dx = -2; dx <= 2; dx++) {
          const nx = x + dx, ny = y + dy
          if (inBounds(nx, ny) && board[ny][nx] !== EMPTY) { near = true; break }
        }
      if (!near) continue
      // 进攻：只延伸自己已有的三/四（顺势取胜），不主动造新三
      const offense = blockScore(x, y, WHITE)
      // 防守：堵玩家已有的三/四端点
      const defense = blockScore(x, y, BLACK)
      const c = (SIZE - 1) / 2
      const center = Math.max(0, 8 - (Math.abs(x - c) + Math.abs(y - c)) / 2)
      const s = offense + defense * 2.0 + center * 0.1
      if (s > bestScore) { bestScore = s; best = { x, y } }
    }
    if (!best) {
      // 兜底：找离中心最近的空点
      outer:
      for (let r = 0; r < SIZE; r++)
        for (let y = 0; y < SIZE; y++) for (let x = 0; x < SIZE; x++)
          if (board[y][x] === EMPTY && Math.max(Math.abs(x - 7), Math.abs(y - 7)) <= r) { best = { x, y }; break outer }
    }
    aiThinking = false
    if (!place(best.x, best.y, WHITE)) {
      current = BLACK
      statusText.value = '轮到你了 · 执黑落子'
    }
  }, 220)
}

function onBoardClick(e) {
  if (over || aiThinking || current !== BLACK) return
  const rect = canvasRef.value.getBoundingClientRect()
  const sx = (e.clientX - rect.left) * (canvasRef.value.width / rect.width)
  const sy = (e.clientY - rect.top) * (canvasRef.value.height / rect.height)
  const gx = Math.round((sx - PAD) / CELL)
  const gy = Math.round((sy - PAD) / CELL)
  if (!inBounds(gx, gy) || board[gy][gx] !== EMPTY) return
  if (!place(gx, gy, BLACK)) {
    current = WHITE
    statusText.value = 'AI 落子中…'
    aiMove()
  }
}

onMounted(() => {
  ctx = canvasRef.value.getContext('2d')
  reset()
})
onBeforeUnmount(() => { /* 无定时器需清理 */ })
</script>

<template>
  <div class="game-box">
    <div class="game-head">
      <span class="g-status">{{ statusText }}</span>
    </div>
    <div class="canvas-wrap">
      <canvas ref="canvasRef" :width="SIZE * CELL + PAD * 2" :height="SIZE * CELL + PAD * 2"
        class="g-canvas" @click="onBoardClick"></canvas>
      <div v-if="gameOver" class="result-overlay" :class="winnerClass" @click="reset">
        <div class="r-emoji">{{ winnerEmoji }}</div>
        <div class="r-title">{{ winnerText }}</div>
        <div class="r-sub">{{ winnerSub }}</div>
        <div class="r-btn">再来一局</div>
      </div>
    </div>
    <div class="g-actions">
      <button class="g-btn" @click="reset">重新开局</button>
    </div>
    <p class="g-tip">你执黑（●）先手 · 五子连珠即胜 · AI 执白（○）</p>
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
.game-head { width: 100%; display: flex; align-items: center; }
.g-status { font-size: 13.5px; color: var(--cyan-soft); }
.g-canvas {
  width: 426px; max-width: 100%; height: auto; border-radius: 12px; border: 1px solid rgba(255, 255, 255, .12);
  background: #e9d9b8; touch-action: none; cursor: pointer; display: block;
}
.canvas-wrap { position: relative; line-height: 0; }
.result-overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 12px;
  background: rgba(8, 11, 32, .82); cursor: pointer; backdrop-filter: blur(3px);
  animation: pop .25s ease-out;
}
@keyframes pop { from { opacity: 0; transform: scale(.9); } to { opacity: 1; transform: scale(1); } }
.r-emoji { font-size: 46px; line-height: 1; }
.r-title { font-size: 26px; font-weight: 800; letter-spacing: 1px; }
.r-title, .r-sub { color: #fff; text-align: center; }
.r-sub { font-size: 13px; color: #cdd6f4; }
.result-overlay.win .r-title { color: #2de2e6; text-shadow: 0 0 16px rgba(45,226,230,.6); }
.result-overlay.lose .r-title { color: #ff48c4; }
.result-overlay.draw .r-title { color: #ffd166; }
.r-btn {
  margin-top: 6px; font-size: 15px; font-weight: 700; color: #04121f; padding: 10px 28px; border-radius: 12px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .4);
}
.g-actions { display: flex; gap: 10px; }
.g-btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 14px; font-weight: 600; color: #04121f;
  padding: 9px 22px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .35); transition: .25s;
}
.g-btn:hover { transform: translateY(-1px); }
.g-tip { font-size: 12px; color: #9fb0d8; margin: 0; }
</style>
