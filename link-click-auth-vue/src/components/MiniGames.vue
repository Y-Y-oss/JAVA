<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'

const emit = defineEmits(['close'])

/* ===================== 标签页 ===================== */
const tab = ref('gomoku') // gomoku | snake

/* =====================================================================
 * 五子棋：玩家执黑(先手)，AI 执白。点击落子，五连即胜。
 * ===================================================================== */
const SIZE = 15            // 15x15 棋盘
const CELL = 32            // 每格像素
const PAD = 20             // 边距
const BOARD_PX = PAD * 2 + CELL * (SIZE - 1)

const gomokuCanvas = ref(null)
let gctx = null
// board[r][c]: 0 空 / 1 黑(玩家) / 2 白(AI)
let gBoard = []
let gCurrent = 1           // 当前轮到谁落子
let gOver = false
let gWinLine = null        // 胜利连线坐标数组
const gStatus = ref('轮到你落子（黑子）')
let gomokuStarted = false

function gReset() {
  gBoard = Array.from({ length: SIZE }, () => Array(SIZE).fill(0))
  gCurrent = 1
  gOver = false
  gWinLine = null
  gStatus.value = '轮到你落子（黑子）'
  gomokuStarted = true
  gDraw()
}

function gDraw() {
  if (!gctx) return
  const c = gctx
  c.clearRect(0, 0, BOARD_PX, BOARD_PX)
  // 背景
  const grad = c.createLinearGradient(0, 0, BOARD_PX, BOARD_PX)
  grad.addColorStop(0, '#16213e')
  grad.addColorStop(1, '#0f1830')
  c.fillStyle = grad
  c.fillRect(0, 0, BOARD_PX, BOARD_PX)
  // 网格
  c.strokeStyle = 'rgba(122,245,247,.28)'
  c.lineWidth = 1
  for (let i = 0; i < SIZE; i++) {
    c.beginPath(); c.moveTo(PAD, PAD + i * CELL); c.lineTo(PAD + (SIZE - 1) * CELL, PAD + i * CELL); c.stroke()
    c.beginPath(); c.moveTo(PAD + i * CELL, PAD); c.lineTo(PAD + i * CELL, PAD + (SIZE - 1) * CELL); c.stroke()
  }
  // 星位
  const stars = [3, 7, 11]
  c.fillStyle = 'rgba(122,245,247,.5)'
  for (const r of stars) for (const cc of stars) {
    c.beginPath(); c.arc(PAD + cc * CELL, PAD + r * CELL, 3, 0, Math.PI * 2); c.fill()
  }
  // 棋子
  for (let r = 0; r < SIZE; r++) for (let cc = 0; cc < SIZE; cc++) {
    if (gBoard[r][cc]) gStone(cc, r, gBoard[r][cc])
  }
  // 胜利连线
  if (gWinLine) {
    c.strokeStyle = '#ff9ae0'
    c.lineWidth = 3
    c.beginPath()
    c.moveTo(PAD + gWinLine[0][0] * CELL, PAD + gWinLine[0][1] * CELL)
    for (let i = 1; i < gWinLine.length; i++) c.lineTo(PAD + gWinLine[i][0] * CELL, PAD + gWinLine[i][1] * CELL)
    c.stroke()
  }
}

function gStone(cx, cy, who) {
  const x = PAD + cx * CELL, y = PAD + cy * CELL
  const rad = CELL * 0.4
  const g = gctx.createRadialGradient(x - rad * 0.3, y - rad * 0.3, rad * 0.2, x, y, rad)
  if (who === 1) { g.addColorStop(0, '#3a3f5a'); g.addColorStop(1, '#05070f') }
  else { g.addColorStop(0, '#ffffff'); g.addColorStop(1, '#c6ccdf') }
  gctx.fillStyle = g
  gctx.beginPath(); gctx.arc(x, y, rad, 0, Math.PI * 2); gctx.fill()
}

function gOnClick(e) {
  if (gOver || gCurrent !== 1 || !gomokuStarted) return
  const rect = gomokuCanvas.value.getBoundingClientRect()
  const scaleX = BOARD_PX / rect.width
  const scaleY = BOARD_PX / rect.height
  const x = (e.clientX - rect.left) * scaleX
  const y = (e.clientY - rect.top) * scaleY
  const cc = Math.round((x - PAD) / CELL)
  const r = Math.round((y - PAD) / CELL)
  if (r < 0 || r >= SIZE || cc < 0 || cc >= SIZE) return
  if (gBoard[r][cc] !== 0) return
  place(r, cc, 1)
  if (gOver) return
  gStatus.value = 'AI 思考中…'
  // 让 UI 先刷新再算 AI，避免卡顿感
  setTimeout(gAiMove, 60)
}

function place(r, cc, who) {
  gBoard[r][cc] = who
  const line = gWinningLine(r, cc, who)
  gDraw()
  if (line) {
    gWinLine = line
    gOver = true
    gDraw()
    gStatus.value = who === 1 ? '🎉 你赢了！五连成线' : 'AI 获胜，再试一局？'
    return true
  }
  gCurrent = who === 1 ? 2 : 1
  return false
}

// 判断 (r,cc) 处 who 落子后是否五连，返回连线坐标或 null
function gWinningLine(r, cc, who) {
  const dirs = [[0, 1], [1, 0], [1, 1], [1, -1]]
  for (const [dr, dc] of dirs) {
    const line = [[cc, r]]
    for (let s = 1; s < 5; s++) {
      const nr = r + dr * s, nc = cc + dc * s
      if (nr < 0 || nr >= SIZE || nc < 0 || nc >= SIZE || gBoard[nr][nc] !== who) break
      line.push([nc, nr])
    }
    for (let s = 1; s < 5; s++) {
      const nr = r - dr * s, nc = cc - dc * s
      if (nr < 0 || nr >= SIZE || nc < 0 || nc >= SIZE || gBoard[nr][nc] !== who) break
      line.unshift([nc, nr])
    }
    if (line.length >= 5) return line.slice(0, 5)
  }
  return null
}

// 找 who 能否一步五连（用于 AI 进攻 / 拦截玩家）
function gFindFive(who) {
  for (let r = 0; r < SIZE; r++) for (let cc = 0; cc < SIZE; cc++) {
    if (gBoard[r][cc] !== 0) continue
    gBoard[r][cc] = who
    const w = gWinningLine(r, cc, who)
    gBoard[r][cc] = 0
    if (w) return [r, cc]
  }
  return null
}

// 单点落子后的连线强度评分（进攻/防守用）
function gLineScore(r, cc, who) {
  const dirs = [[0, 1], [1, 0], [1, 1], [1, -1]]
  let total = 0
  for (const [dr, dc] of dirs) {
    let count = 1, left = 0, right = 0
    for (let s = 1; s < 5; s++) { const nr = r + dr * s, nc = cc + dc * s; if (nr<0||nr>=SIZE||nc<0||nc>=SIZE||gBoard[nr][nc]!==who){break} count++; }
    for (let s = 1; s < 5; s++) { const nr = r - dr * s, nc = cc - dc * s; if (nr<0||nr>=SIZE||nc<0||nc>=SIZE||gBoard[nr][nc]!==who){break} count++; }
    // 开口数
    const lr = r - dr * count, lc = cc - dc * count
    const rr = r + dr * count, rc = cc + dc * count
    const leftOpen = (lr>=0&&lr<SIZE&&lc>=0&&lc<SIZE&&gBoard[lr][lc]===0)?1:0
    const rightOpen = (rr>=0&&rr<SIZE&&rc>=0&&rc<SIZE&&gBoard[rr][rc]===0)?1:0
    if (count >= 5) total += 1000000
    else if (count === 4) total += leftOpen + rightOpen >= 2 ? 5000 : (leftOpen+rightOpen>=1?600:0)
    else if (count === 3) total += leftOpen + rightOpen >= 2 ? 500 : (leftOpen+rightOpen>=1?60:0)
    else if (count === 2) total += leftOpen + rightOpen >= 2 ? 40 : (leftOpen+rightOpen>=1?8:0)
    else total += leftOpen + rightOpen >= 2 ? 3 : 1
  }
  return total
}

function gBestMove() {
  // 1) 自己能赢就赢
  const win = gFindFive(2)
  if (win) return win
  // 2) 玩家能赢就堵
  const block = gFindFive(1)
  if (block) return block
  // 3) 综合进攻 + 防守评分选最优
  let best = null, bestScore = -1
  for (let r = 0; r < SIZE; r++) for (let cc = 0; cc < SIZE; cc++) {
    if (gBoard[r][cc] !== 0) continue
    // 只在没有相邻棋子的远处下棋没意义
    if (!gHasNeighbor(r, cc)) continue
    const s = gLineScore(r, cc, 2) + gLineScore(r, cc, 1) * 0.9
    if (s > bestScore) { bestScore = s; best = [r, cc] }
  }
  if (!best) { // 兜底：落中心
    best = [7, 7]
  }
  return best
}

function gHasNeighbor(r, cc) {
  for (let dr = -2; dr <= 2; dr++) for (let dc = -2; dc <= 2; dc++) {
    if (dr===0&&dc===0) continue
    const nr=r+dr, nc=cc+dc
    if (nr>=0&&nr<SIZE&&nc>=0&&nc<SIZE&&gBoard[nr][nc]!==0) return true
  }
  return false
}

function gAiMove() {
  if (gOver) return
  const mv = gBestMove()
  if (!mv) { gOver = true; gStatus.value = '和棋'; return }
  const done = place(mv[0], mv[1], 2)
  if (!done) gStatus.value = '轮到你落子（黑子）'
}

/* =====================================================================
 * 贪吃蛇：方向键 / WASD 控制，吃到食物加分，撞墙或咬到自己结束。
 * ===================================================================== */
const GRID = 20
const SCELL = 22
const SCENE = GRID * SCELL
const snakeCanvas = ref(null)
let sctx = null
let sBody = []          // 数组，每元素 {x,y}，sBody[0] 为头
let sDir = { x: 1, y: 0 }
let sNextDir = { x: 1, y: 0 }
let sFood = { x: 10, y: 10 }
let sScore = 0
let sOver = false
let sTimer = null
let sSpeed = 130
let snakeStarted = false
const sStatus = ref('方向键 / WASD 控制，吃到光点得分')

function sReset() {
  sBody = [{ x: 8, y: 10 }, { x: 7, y: 10 }, { x: 6, y: 10 }]
  sDir = { x: 1, y: 0 }; sNextDir = { x: 1, y: 0 }
  sScore = 0; sOver = false; sSpeed = 130; snakeStarted = true
  sFood = { x: 14, y: 6 }
  sStatus.value = '方向键 / WASD 控制，吃到光点得分'
  if (sTimer) clearInterval(sTimer)
  sTimer = setInterval(sTick, sSpeed)
  sDraw()
}

function sSpawnFood() {
  let p
  do {
    p = { x: Math.floor(Math.random() * GRID), y: Math.floor(Math.random() * GRID) }
  } while (sBody.some(b => b.x === p.x && b.y === p.y))
  sFood = p
}

function sTick() {
  if (sOver) return
  sDir = sNextDir
  const head = { x: sBody[0].x + sDir.x, y: sBody[0].y + sDir.y }
  // 撞墙
  if (head.x < 0 || head.y < 0 || head.x >= GRID || head.y >= GRID) return sGameOver('撞到边界了')
  // 咬到自己
  if (sBody.some(b => b.x === head.x && b.y === head.y)) return sGameOver('咬到自己了')
  sBody.unshift(head)
  if (head.x === sFood.x && head.y === sFood.y) {
    sScore += 10
    sStatus.value = '得分 ' + sScore + ' · 速度提升中'
    if (sSpeed > 70) { sSpeed -= 4; clearInterval(sTimer); sTimer = setInterval(sTick, sSpeed) }
    sSpawnFood()
  } else {
    sBody.pop()
  }
  sDraw()
}

function sGameOver(msg) {
  sOver = true
  if (sTimer) clearInterval(sTimer)
  sStatus.value = msg + '，最终得分 ' + sScore + '（按「重开」再来一局）'
}

function sDraw() {
  if (!sctx) return
  const c = sctx
  c.clearRect(0, 0, SCENE, SCENE)
  const grad = c.createLinearGradient(0, 0, SCENE, SCENE)
  grad.addColorStop(0, '#0f1830'); grad.addColorStop(1, '#101a36')
  c.fillStyle = grad; c.fillRect(0, 0, SCENE, SCENE)
  // 格子
  c.strokeStyle = 'rgba(122,245,247,.08)'; c.lineWidth = 1
  for (let i = 0; i <= GRID; i++) {
    c.beginPath(); c.moveTo(i*SCELL,0); c.lineTo(i*SCELL,SCENE); c.stroke()
    c.beginPath(); c.moveTo(0,i*SCELL); c.lineTo(SCENE,i*SCELL); c.stroke()
  }
  // 食物（光点）
  c.fillStyle = '#ff9ae0'
  c.beginPath(); c.arc(sFood.x*SCELL + SCELL/2, sFood.y*SCELL + SCELL/2, SCELL*0.3, 0, Math.PI*2); c.fill()
  // 蛇
  sBody.forEach((b, i) => {
    const g = c.createLinearGradient(b.x*SCELL, b.y*SCELL, b.x*SCELL+SCELL, b.y*SCELL+SCELL)
    if (i === 0) { g.addColorStop(0,'#7af5f7'); g.addColorStop(1,'#2de2e6') }
    else { g.addColorStop(0,'#8a5cff'); g.addColorStop(1,'#b39cff') }
    c.fillStyle = g
    const pad = 2
    roundRect(c, b.x*SCELL+pad, b.y*SCELL+pad, SCELL-pad*2, SCELL-pad*2, 5); c.fill()
  })
}

function roundRect(c, x, y, w, h, r) {
  c.beginPath()
  c.moveTo(x+r, y)
  c.arcTo(x+w, y, x+w, y+h, r)
  c.arcTo(x+w, y+h, x, y+h, r)
  c.arcTo(x, y+h, x, y, r)
  c.arcTo(x, y, x+w, y, r)
  c.closePath()
}

function sKey(e) {
  const k = e.key.toLowerCase()
  if (k === 'arrowup' || k === 'w') { if (sDir.y===0) sNextDir={x:0,y:-1}; e.preventDefault() }
  else if (k === 'arrowdown' || k === 's') { if (sDir.y===0) sNextDir={x:0,y:1}; e.preventDefault() }
  else if (k === 'arrowleft' || k === 'a') { if (sDir.x===0) sNextDir={x:-1,y:0}; e.preventDefault() }
  else if (k === 'arrowright' || k === 'd') { if (sDir.x===0) sNextDir={x:1,y:0}; e.preventDefault() }
}

/* ===================== 生命周期 ===================== */
function setupCanvas() {
  if (tab.value === 'gomoku' && gomokuCanvas.value) {
    gctx = gomokuCanvas.value.getContext('2d')
    fitDpr(gomokuCanvas.value, BOARD_PX, BOARD_PX)
    if (!gomokuStarted) gReset()
    else gDraw()
  }
  if (tab.value === 'snake' && snakeCanvas.value) {
    sctx = snakeCanvas.value.getContext('2d')
    fitDpr(snakeCanvas.value, SCENE, SCENE)
    if (!snakeStarted) sReset()
    else sDraw()
  }
}

function fitDpr(canvas, w, h) {
  const dpr = window.devicePixelRatio || 1
  canvas.width = w * dpr
  canvas.height = h * dpr
  canvas.style.width = w + 'px'
  canvas.style.height = h + 'px'
  const ctx = canvas.getContext('2d')
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
}

function onTab(name) {
  tab.value = name
  sNextDir = { ...sDir }
  nextTick(setupCanvas)
}

onMounted(() => {
  window.addEventListener('keydown', sKey)
  nextTick(setupCanvas)
})
onBeforeUnmount(() => {
  window.removeEventListener('keydown', sKey)
  if (sTimer) clearInterval(sTimer)
})
</script>

<template>
  <div class="games-mask" @click.self="emit('close')">
    <div class="games-panel">
      <button class="g-close" @click="emit('close')" aria-label="关闭">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>
      </button>

      <h2 class="g-title">🎮 社区小游戏</h2>
      <p class="g-sub">忙里偷闲，来一局吧～ 五子棋人机对战 / 经典贪吃蛇</p>

      <div class="g-tabs">
        <button class="g-tab" :class="{ on: tab==='gomoku' }" @click="onTab('gomoku')">五子棋</button>
        <button class="g-tab" :class="{ on: tab==='snake' }" @click="onTab('snake')">贪吃蛇</button>
      </div>

      <!-- 五子棋 -->
      <div v-show="tab==='gomoku'" class="g-stage">
        <div class="g-canvas-wrap">
          <canvas ref="gomokuCanvas" @click="gOnClick"></canvas>
        </div>
        <div class="g-side">
          <p class="g-status">{{ gStatus }}</p>
          <p class="g-tip">你执 <b style="color:#cfd6ff">黑子</b> 先手，AI 执白。点击交叉点落子，率先五连即胜。</p>
          <button class="g-btn" @click="gReset">重新开局</button>
        </div>
      </div>

      <!-- 贪吃蛇 -->
      <div v-show="tab==='snake'" class="g-stage">
        <div class="g-canvas-wrap">
          <canvas ref="snakeCanvas"></canvas>
        </div>
        <div class="g-side">
          <p class="g-status">{{ sStatus }}</p>
          <p class="g-tip">用 <b>方向键</b> 或 <b>W A S D</b> 控制方向，吃下粉色光点得分，别撞墙也别咬到自己。</p>
          <button class="g-btn" @click="sReset">重开一局</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.games-mask {
  position: fixed; inset: 0; z-index: 80; display: grid; place-items: center; padding: 20px;
  background: rgba(5, 8, 24, .72); backdrop-filter: blur(8px) saturate(140%);
}
.games-panel {
  position: relative; width: min(760px, 100%); max-height: 92vh; overflow-y: auto;
  border-radius: 22px; padding: 26px 28px 30px;
  background: linear-gradient(160deg, rgba(20,24,56,.96), rgba(11,13,38,.97));
  border: 1px solid rgba(255,255,255,.16);
  box-shadow: 0 30px 80px rgba(0,0,0,.6), 0 0 0 1px rgba(45,226,230,.12);
}
.g-close {
  position: absolute; top: 14px; right: 14px; z-index: 2; width: 36px; height: 36px; border-radius: 50%;
  cursor: pointer; display: grid; place-items: center; color: #eef2ff;
  background: rgba(10,14,39,.5); border: 1px solid rgba(255,255,255,.2); transition: .25s;
}
.g-close svg { width: 18px; height: 18px; }
.g-close:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 14px rgba(255,72,196,.45); }
.g-title { font-size: 24px; font-weight: 700; letter-spacing: 1px; background: linear-gradient(135deg,var(--cyan),var(--magenta)); -webkit-background-clip: text; background-clip: text; color: transparent; }
.g-sub { font-size: 13px; color: #9fb0d8; margin: 6px 0 18px; }
.g-tabs { display: flex; gap: 10px; margin-bottom: 18px; }
.g-tab {
  flex: 1; padding: 11px 0; border-radius: 12px; cursor: pointer; font-family: inherit; font-size: 14px; color: #cdd6f4;
  background: rgba(255,255,255,.05); border: 1px solid rgba(255,255,255,.16); transition: .22s;
}
.g-tab.on { color: #04121f; font-weight: 700; border-color: transparent; background: linear-gradient(135deg,var(--cyan),var(--purple) 60%,var(--magenta)); box-shadow: 0 6px 16px rgba(138,92,255,.35); }
.g-stage { display: flex; gap: 22px; flex-wrap: wrap; }
.g-canvas-wrap { flex-shrink: 0; }
.g-canvas-wrap canvas {
  border-radius: 14px; border: 1px solid rgba(255,255,255,.14); cursor: pointer;
  box-shadow: 0 14px 36px rgba(0,0,0,.45); touch-action: none;
}
.g-side { flex: 1; min-width: 200px; display: flex; flex-direction: column; gap: 12px; }
.g-status { font-size: 15px; font-weight: 600; color: #eef2ff; }
.g-tip { font-size: 13px; line-height: 1.7; color: #9fb0d8; }
.g-btn {
  margin-top: 4px; align-self: flex-start; border: 0; cursor: pointer; font-family: inherit; font-size: 14px; font-weight: 600;
  color: #04121f; padding: 11px 22px; border-radius: 12px; letter-spacing: 1px;
  background: linear-gradient(135deg,var(--cyan),var(--purple) 60%,var(--magenta)); box-shadow: 0 10px 26px rgba(138,92,255,.4); transition: .25s;
}
.g-btn:hover { transform: translateY(-1px); filter: brightness(1.06); }
</style>
