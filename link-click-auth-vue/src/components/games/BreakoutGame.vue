<script setup>
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { getRecord, saveRecord } from '../../utils/gameScore'
import WinStage from './WinStage.vue'
import { getGameTheme } from '../../utils/gameThemes'

// 画布内绘制不走 CSS 变量，直接取主题色，避免"外框熔岩、里面青紫"
const T = getGameTheme('breakout')

/** 打砖块 · 3 关，消完所有砖块过关，3 条命 */
const TOTAL = 3
const W = 400, H = 440
const PAD_W = 76, PAD_H = 10, BALL_R = 6

const canvasRef = ref(null)
const level = ref(1)
const lives = ref(3)
const score = ref(0)
const phase = ref('ready') // ready | playing | levelClear | allClear | gameOver
const status = ref('点击「开始」或画布开球，鼠标 / ← → 移动挡板')
const record = ref(getRecord('breakout'))
const bestText = computed(() => record.value.bestScore ? `最高 ${record.value.bestScore} 分 · 通关 ${record.value.clears || 0} 次` : '尚无记录')

let ctx = null
let paddleX = (W - PAD_W) / 2
let ball = { x: W / 2, y: H - 40, vx: 0, vy: 0, r: BALL_R }
let bricks = []
let keys = { left: false, right: false }
let raf = null
let speed = 3.6
let particleBurst = []

function makeBricks(n) {
  const rows = 3 + n, cols = 8
  const bw = (W - 24 - (cols - 1) * 6) / cols
  const bh = 18
  const colors = [T.main, T.accent, '#ff5b7f', T.second, T.accent, T.main]
  const out = []
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      out.push({
        x: 12 + c * (bw + 6), y: 46 + r * (bh + 6), w: bw, h: bh,
        alive: true, color: colors[(r + c) % colors.length]
      })
    }
  }
  return out
}

function resetBall() {
  ball = { x: paddleX + PAD_W / 2, y: H - 34, vx: 0, vy: 0, r: BALL_R }
}
function startLevel(n) {
  level.value = n
  bricks = makeBricks(n)
  speed = 3.4 + n * 0.65
  paddleX = (W - PAD_W) / 2
  resetBall()
  phase.value = 'ready'
  status.value = `第 ${n} / ${TOTAL} 关 · 消掉全部 ${bricks.length} 块砖即可过关`
  draw()
}
function restartAll() {
  lives.value = 3
  score.value = 0
  particleBurst = []
  startLevel(1)
}
function launch() {
  if (phase.value !== 'ready') return
  const angle = (Math.random() * 0.5 - 0.25) - Math.PI / 2
  ball.vx = Math.cos(angle) * speed
  ball.vy = Math.sin(angle) * speed
  phase.value = 'playing'
  status.value = '进行中 · 别让球掉下去！'
  loop()
}
function nextLevel() { startLevel(level.value + 1) }

function spawnBurst(x, y, color) {
  for (let i = 0; i < 10; i++) {
    const a = Math.random() * Math.PI * 2, s = 1 + Math.random() * 2.6
    particleBurst.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, life: 1, color })
  }
}

function loop() {
  if (phase.value !== 'playing') return
  if (keys.left) paddleX -= 6
  if (keys.right) paddleX += 6
  paddleX = Math.max(0, Math.min(W - PAD_W, paddleX))

  if (phase.value === 'ready') resetBall()
  else {
    ball.x += ball.vx
    ball.y += ball.vy
    if (ball.x - ball.r < 0) { ball.x = ball.r; ball.vx *= -1 }
    if (ball.x + ball.r > W) { ball.x = W - ball.r; ball.vx *= -1 }
    if (ball.y - ball.r < 0) { ball.y = ball.r; ball.vy *= -1 }

    // 挡板碰撞
    const padY = H - 30
    if (ball.vy > 0 && ball.y + ball.r >= padY && ball.y - ball.r <= padY + PAD_H &&
        ball.x >= paddleX - ball.r && ball.x <= paddleX + PAD_W + ball.r) {
      ball.y = padY - ball.r
      const hit = (ball.x - (paddleX + PAD_W / 2)) / (PAD_W / 2)
      const angle = hit * 0.9 - Math.PI / 2
      ball.vx = Math.cos(angle) * speed
      ball.vy = Math.sin(angle) * speed
      spawnBurst(ball.x, padY, T.main)
    }

    // 砖块碰撞
    for (const b of bricks) {
      if (!b.alive) continue
      if (ball.x + ball.r < b.x || ball.x - ball.r > b.x + b.w ||
          ball.y + ball.r < b.y || ball.y - ball.r > b.y + b.h) continue
      b.alive = false
      score.value += 10
      spawnBurst(b.x + b.w / 2, b.y + b.h / 2, b.color)
      // 判断从哪个方向撞击
      const overlapX = Math.min(ball.x + ball.r - b.x, b.x + b.w - (ball.x - ball.r))
      const overlapY = Math.min(ball.y + ball.r - b.y, b.y + b.h - (ball.y - ball.r))
      if (overlapX < overlapY) ball.vx *= -1
      else ball.vy *= -1
      break
    }

    if (bricks.every((b) => !b.alive)) { onClear(); return }
    if (ball.y - ball.r > H) { onMiss(); return }
  }

  particleBurst = particleBurst.filter((p) => p.life > 0)
  particleBurst.forEach((p) => { p.x += p.vx; p.y += p.vy; p.vy += .06; p.life -= .035 })
  draw()
  raf = requestAnimationFrame(loop)
}

function onMiss() {
  lives.value--
  if (lives.value <= 0) {
    phase.value = 'gameOver'
    status.value = '💥 球全掉了，最终得分 ' + score.value
    draw()
    return
  }
  phase.value = 'ready'
  resetBall()
  status.value = `还剩 ${lives.value} 条命，点击「开始」继续`
  draw()
}

function onClear() {
  if (raf) cancelAnimationFrame(raf)
  if (level.value >= TOTAL) {
    phase.value = 'allClear'
    const patch = { clears: (record.value.clears || 0) + 1, maxLevel: TOTAL }
    if (!record.value.bestScore || score.value > record.value.bestScore) patch.bestScore = score.value
    saveRecord('breakout', patch)
    record.value = getRecord('breakout')
    status.value = `🏆 全部 ${TOTAL} 关通关！得分 ${score.value}`
  } else {
    phase.value = 'levelClear'
    status.value = `🎉 第 ${level.value} 关通过！`
  }
  draw()
}

function draw() {
  if (!ctx) return
  const c = ctx
  const bg = c.createLinearGradient(0, 0, 0, H)
  bg.addColorStop(0, '#25081a'); bg.addColorStop(1, '#160812')
  c.fillStyle = bg; c.fillRect(0, 0, W, H)

  bricks.forEach((b) => {
    if (!b.alive) return
    c.save()
    c.shadowColor = b.color; c.shadowBlur = 8
    c.fillStyle = b.color
    c.globalAlpha = .82
    c.beginPath()
    c.roundRect ? c.roundRect(b.x, b.y, b.w, b.h, 4) : c.rect(b.x, b.y, b.w, b.h)
    c.fill(); c.restore()
  })

  particleBurst.forEach((p) => {
    c.globalAlpha = Math.max(0, p.life)
    c.fillStyle = p.color
    c.fillRect(p.x, p.y, 3, 3)
  })
  c.globalAlpha = 1

  // 挡板
  const padY = H - 30
  c.save()
  c.shadowColor = T.main; c.shadowBlur = 14
  const pg = c.createLinearGradient(paddleX, 0, paddleX + PAD_W, 0)
  pg.addColorStop(0, T.main); pg.addColorStop(.5, T.accent); pg.addColorStop(1, T.second)
  c.fillStyle = pg
  c.beginPath()
  c.roundRect ? c.roundRect(paddleX, padY, PAD_W, PAD_H, 6) : c.rect(paddleX, padY, PAD_W, PAD_H)
  c.fill(); c.restore()

  // 球
  c.save()
  c.shadowColor = T.main; c.shadowBlur = 16
  c.fillStyle = T.accent
  c.beginPath(); c.arc(ball.x, ball.y, ball.r, 0, Math.PI * 2); c.fill()
  c.restore()

  // 待发球时的引导线
  if (phase.value === 'ready') {
    c.strokeStyle = `rgba(${T.rgb},.32)`; c.setLineDash([5, 6]); c.lineWidth = 1
    c.beginPath(); c.moveTo(ball.x, ball.y); c.lineTo(ball.x, 100); c.stroke(); c.setLineDash([])
  }
}

function onMouse(e) {
  const cv = canvasRef.value
  if (!cv) return
  const rect = cv.getBoundingClientRect()
  const x = (e.clientX - rect.left) / rect.width * W
  paddleX = Math.max(0, Math.min(W - PAD_W, x - PAD_W / 2))
  if (phase.value === 'playing') draw()
}
function onMouseTouch(e) {
  const t = e.touches && e.touches[0]
  if (t) onMouse({ clientX: t.clientX, clientY: t.clientY })
}
function onKey(e) {
  const k = e.key.toLowerCase()
  if (k === 'arrowleft' || k === 'a') { keys.left = true; e.preventDefault() }
  else if (k === 'arrowright' || k === 'd') { keys.right = true; e.preventDefault() }
  else if (k === ' ' || e.code === 'Space') { e.preventDefault(); if (phase.value === 'ready') launch() }
}
function onKeyUp(e) {
  const k = e.key.toLowerCase()
  if (k === 'arrowleft' || k === 'a') keys.left = false
  else if (k === 'arrowright' || k === 'd') keys.right = false
}
function movePad(dx) {
  paddleX = Math.max(0, Math.min(W - PAD_W, paddleX + dx))
  if (phase.value !== 'playing') draw()
}

onMounted(() => {
  nextTick(() => {
    const cv = canvasRef.value
    if (cv) { cv.width = W; cv.height = H; ctx = cv.getContext('2d') }
    startLevel(1)
  })
  window.addEventListener('keydown', onKey)
  window.addEventListener('keyup', onKeyUp)
})
onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey)
  window.removeEventListener('keyup', onKeyUp)
  if (raf) cancelAnimationFrame(raf)
})
</script>

<template>
  <div class="bo">
    <div class="bar">
      <span>关卡 <b>{{ level }}/{{ TOTAL }}</b></span>
      <span>生命 <b>{{ '❤'.repeat(lives) || '—' }}</b></span>
      <span>得分 <b>{{ score }}</b></span>
      <span class="best">{{ bestText }}</span>
    </div>
    <p class="status">{{ status }}</p>

    <div class="stage">
      <canvas
        ref="canvasRef" class="canvas"
        @mousemove="onMouse" @touchmove.prevent="onMouseTouch" @click="launch"
      ></canvas>
      <div v-if="phase === 'ready' || phase === 'levelClear' || phase === 'allClear' || phase === 'gameOver'" class="overlay">
        <WinStage v-if="phase !== 'ready'" theme="fireworks" />
        <template v-if="phase === 'ready'">
          <div class="ov-emoji">🧱</div>
          <h3>第 {{ level }} 关</h3>
          <p>点击开始 · 鼠标 / ← → 移动挡板</p>
          <button class="btn" @click.stop="launch">开始</button>
        </template>
        <template v-else-if="phase === 'levelClear'">
          <div class="ov-emoji">🎉</div>
          <h3>第 {{ level }} 关通过</h3>
          <p>剩余生命 {{ lives }} · 下一关砖块更多、球更快</p>
          <button class="btn" @click.stop="nextLevel">下一关 →</button>
        </template>
        <template v-else-if="phase === 'allClear'">
          <div class="ov-emoji">🏆</div>
          <h3>全部通关！</h3>
          <p>最终得分 {{ score }}</p>
          <button class="btn" @click.stop="restartAll">再玩一次</button>
        </template>
        <template v-else>
          <div class="ov-emoji">💥</div>
          <h3>游戏结束</h3>
          <p>最终得分 {{ score }}</p>
          <button class="btn" @click.stop="restartAll">再来一局</button>
        </template>
      </div>
    </div>

    <div class="pad-ctrl">
      <button class="d" @click="movePad(-36)">◀ 左移</button>
      <button class="btn" @click="launch">{{ phase === 'ready' ? '开球 (空格)' : '进行中' }}</button>
      <button class="d" @click="movePad(36)">右移 ▶</button>
    </div>
    <div class="actions"><button class="btn ghost" @click="restartAll">从第 1 关重来</button></div>
    <p class="tip">鼠标 / 触摸 / ← → 控制挡板 · 空格开球 · 消完全部砖块过关</p>
  </div>
</template>

<style scoped>
.bo { width: 100%; max-width: 420px; display: flex; flex-direction: column; align-items: center; gap: 10px; }
.bar {
  width: 100%; display: flex; flex-wrap: wrap; gap: 12px; align-items: center;
  padding: 10px 14px; border-radius: 12px; font-size: 12.5px; color: #cdd6f4;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .14);
}
.bar b { color: #fff; font-size: 15px; }
.bar .best { margin-left: auto; color: var(--cyan-soft); font-size: 11.5px; }
.status { font-size: 13px; color: #9fb0d8; text-align: center; margin: 0; min-height: 18px; }

.stage { position: relative; width: 100%; display: flex; justify-content: center; }
.canvas {
  width: 100%; max-width: 400px; height: auto; display: block; border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .45);
  touch-action: none; cursor: pointer;
}
.overlay {
  position: absolute; inset: 0; display: flex; flex-direction: column;
  align-items: center; justify-content: center; gap: 10px; border-radius: 14px;
  background: rgba(30, 6, 18, .94); backdrop-filter: blur(5px); animation: pop .24s ease-out;
}
.overlay > :not(.ws) { position: relative; z-index: 2; }
@keyframes pop { from { opacity: 0; transform: scale(.94) } to { opacity: 1; transform: none } }
.ov-emoji { font-size: 44px; line-height: 1; }
.overlay h3 { font-size: 23px; font-weight: 800; color: var(--cyan); text-shadow: 0 0 18px rgba(45, 226, 230, .5); }
.overlay p { font-size: 13px; color: #cdd6f4; text-align: center; }

.pad-ctrl { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; justify-content: center; }
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
.d {
  border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .06);
  color: #eef2ff; font-family: inherit; font-size: 12.5px; padding: 9px 14px;
  border-radius: 10px; cursor: pointer; transition: .15s;
}
.d:hover { border-color: var(--cyan); }
.d:active { transform: scale(.95); background: rgba(45, 226, 230, .2); }
.tip { font-size: 11.5px; color: #7e8ab0; text-align: center; margin: 0; }
</style>
