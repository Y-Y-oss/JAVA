<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount, inject } from 'vue'
import { fetchFriends } from '../api/friends'
import { inviteGomoku, fetchMyGames, acceptGomoku, declineGomoku, fetchGomokuGame, moveGomoku, resignGomoku } from '../api/gomoku'

const SIZE = 15
const CELL = 26
const PAD = 18
const EMPTY = 0
const BLACK = 1 // 玩家 / 黑方
const WHITE = 2 // AI / 白方

const notify = inject('appNotify', null)

const canvasRef = ref(null)
// 对弈模式：ai=人机（玩家黑 vs AI 白）；pvp=双人同屏轮流落子；net=邀请好友在线对弈
const mode = ref('ai')
const statusText = ref('你执黑先手 · 点击棋盘落子')
const gameOver = ref(false)
const winner = ref(0) // 0 未结束 / 1 黑胜 / 2 白胜 / 3 平局

const winnerText = computed(() => {
  if (winner.value === 1) return netLabel('黑方获胜！', '你赢了！', '对手获胜')
  if (winner.value === 2) return netLabel('白方获胜！', 'AI 获胜', '你赢了！')
  if (winner.value === 3) return '平局'
  return ''
})
const winnerEmoji = computed(() => {
  if (winner.value === 1) return mode.value === 'net' ? (iAmBlack.value ? '🎉' : '😢') : mode.value === 'ai' ? '🎉' : '⚫'
  if (winner.value === 2) return mode.value === 'net' ? (!iAmBlack.value ? '🎉' : '😢') : mode.value === 'ai' ? '🤖' : '⚪'
  if (winner.value === 3) return '🤝'
  return ''
})
const winnerSub = computed(() => {
  if (winner.value === 1) return netLabel('黑方五子连珠', '五子连珠 · 恭喜过关！', '对手五子连珠 · 再接再厉')
  if (winner.value === 2) return netLabel('白方五子连珠', '再接再厉，下一局翻盘', '五子连珠 · 恭喜过关！')
  if (winner.value === 3) return '棋盘已下满'
  return ''
})
/** 网络模式按"我执的颜色"换算输赢文案；其他模式用固定文案 */
function netLabel(netText, aiText, pvpText) {
  if (mode.value !== 'net') return mode.value === 'ai' ? aiText : pvpText
  const iWin = (winner.value === 1 && iAmBlack.value) || (winner.value === 2 && !iAmBlack.value)
  return netText + (iWin ? ' · 你赢了！' : ' · 再接再厉')
}
const winnerClass = computed(() => {
  if (winner.value === 3) return 'draw'
  if (mode.value === 'net') {
    const iWin = (winner.value === 1 && iAmBlack.value) || (winner.value === 2 && !iAmBlack.value)
    return iWin ? 'win' : 'lose'
  }
  if (winner.value === 1) return 'win'
  return 'lose'
})

let ctx = null
let board = []
let current = BLACK
let aiThinking = false
let aiTimer = null
let over = false
let lastMove = null

/* ========================= 落子 / 胜利 视觉特效 ========================= */
/* 纯 Canvas + CSS 动画，不改动任何对弈逻辑；人机 / 双人 / 联机三种模式通用 */
/* 星尘 + 能量碎片：持续运动的舞台粒子（CSS 驱动，无限循环） */
const stardust = Array.from({ length: 34 }, (_, i) => ({
  left: (i * 29 + Math.random() * 40) % 100,
  top: (i * 17 + Math.random() * 60) % 100,
  size: 1.5 + Math.random() * 2.8,
  dur: (1.4 + Math.random() * 2).toFixed(2),
  delay: (Math.random() * 2.5).toFixed(2),
  color: ['#7af5f7', '#ffffff', '#ff8ad8', '#ffd166'][i % 4]
}))
const shards = Array.from({ length: 26 }, (_, i) => ({
  left: (i * 41 + Math.random() * 30) % 100,
  w: 2 + Math.random() * 3,
  h: 12 + Math.random() * 22,
  color: ['#2de2e6', '#7af5f7', '#8a5cff', '#ff48c4', '#ffd166', '#ffffff'][i % 6],
  delay: (Math.random() * 3.5).toFixed(2),
  dur: (2.6 + Math.random() * 2.2).toFixed(2)
}))
function starStyle(s) {
  return {
    left: s.left + '%', top: s.top + '%', width: s.size + 'px', height: s.size + 'px',
    background: s.color, boxShadow: `0 0 8px 2px ${s.color}`,
    '--dur': s.dur + 's', '--delay': s.delay + 's'
  }
}
function shardStyle(c) {
  return {
    left: c.left + '%', width: c.w + 'px', height: c.h + 'px',
    background: c.color, color: c.color,
    '--dur': c.dur + 's', '--delay': c.delay + 's'
  }
}

let fxRaf = null
let ripples = []      // 落子 / 胜利光环
let sparks = []       // 迸发粒子
let winLine = []      // 五连坐标
let winBorn = 0
let dropAnim = null   // 最后一手的弹入动画

const easeOutBack = (t) => {
  const c1 = 1.70158, c3 = c1 + 1
  return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2)
}
function fxColor(color) { return color === BLACK ? '#2de2e6' : '#ff48c4' }

function spawnDrop(x, y, color) {
  const now = performance.now()
  const cx = PAD + x * CELL, cy = PAD + y * CELL
  dropAnim = { x, y, born: now }
  ripples.push({ x: cx, y: cy, color: fxColor(color), born: now })
  for (let i = 0; i < 14; i++) {
    const a = (Math.PI * 2 * i) / 14 + Math.random() * .3
    const sp = 1.4 + Math.random() * 2.6
    sparks.push({
      x: cx, y: cy, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp,
      color: i % 2 ? fxColor(color) : '#ffffff', born: now, life: 1
    })
  }
  ensureFxLoop()
}

function spawnWinBurst(line, color) {
  const now = performance.now()
  winBorn = now
  line.forEach((p, idx) => {
    const born = now + idx * 110
    const cx = PAD + p.x * CELL, cy = PAD + p.y * CELL
    ripples.push({ x: cx, y: cy, color: '#2de2e6', born, big: true })
    ripples.push({ x: cx, y: cy, color: '#ff48c4', born: born + 90, big: true })
    for (let i = 0; i < 16; i++) {
      const a = Math.random() * Math.PI * 2, sp = 1.2 + Math.random() * 4.5
      sparks.push({
        x: cx, y: cy, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp - 1.2,
        color: ['#ffd166', '#ff48c4', '#2de2e6', '#7af5f7', '#ffffff'][i % 5],
        born, life: 2.2
      })
    }
  })
  ensureFxLoop()
}

function hasActiveFx(now) {
  if (winLine.length) return true // 胜线持续流光，直到重开
  if (dropAnim && now - dropAnim.born < 300) return true
  if (ripples.some((r) => now - r.born < (r.big ? 1100 : 620))) return true
  if (sparks.some((s) => (now - s.born) / 1000 < s.life * .62)) return true
  return false
}

function ensureFxLoop() {
  if (fxRaf) return
  fxRaf = requestAnimationFrame((ts) => {
    fxRaf = null
    draw(ts)
    if (hasActiveFx(ts || performance.now())) ensureFxLoop()
  })
}

function drawEffects(now) {
  ripples = ripples.filter((r) => now - r.born < (r.big ? 1100 : 620))
  for (const r of ripples) {
    const dur = r.big ? 1100 : 620
    const t = (now - r.born) / dur
    if (t < 0 || t > 1) continue
    ctx.save()
    ctx.globalAlpha = (1 - t) * .85
    ctx.strokeStyle = r.color
    ctx.lineWidth = (r.big ? 3.5 : 2.5) * (1 - t * .6)
    ctx.shadowColor = r.color
    ctx.shadowBlur = 14
    ctx.beginPath()
    ctx.arc(r.x, r.y, (r.big ? CELL * 1.9 : CELL * 1.15) * t + 3, 0, Math.PI * 2)
    ctx.stroke()
    ctx.restore()
  }

  sparks = sparks.filter((s) => (now - s.born) / 1000 < s.life * .62)
  for (const s of sparks) {
    const age = (now - s.born) / 1000
    const t = age / (s.life * .62)
    if (t < 0 || t > 1) continue
    const x = s.x + s.vx * age * 60
    const y = s.y + s.vy * age * 60 + 30 * age * age
    ctx.save()
    ctx.globalAlpha = 1 - t
    ctx.fillStyle = s.color
    ctx.shadowColor = s.color
    ctx.shadowBlur = 8
    ctx.beginPath(); ctx.arc(x, y, 2.4 * (1 - t * .5), 0, Math.PI * 2); ctx.fill()
    ctx.restore()
  }
}

/** 胜利能量束：持续呼吸的光带 + 沿线奔跑的光点 + 放射光束 + 循环扫描线（全程动态） */
function drawWinLine(now) {
  const pts = winLine.map((p) => ({ x: PAD + p.x * CELL, y: PAD + p.y * CELL }))
  const a = pts[0], b = pts[pts.length - 1]
  const t = (now - winBorn) / 1000
  const W = SIZE * CELL + PAD * 2

  ctx.save()
  // 1. 底层青色宽光带（呼吸）
  const pulse = .55 + .45 * Math.sin(t * 4)
  ctx.globalAlpha = .3 + .25 * pulse
  ctx.strokeStyle = '#2de2e6'
  ctx.lineWidth = 20 + pulse * 8
  ctx.lineCap = 'round'
  ctx.shadowColor = '#2de2e6'
  ctx.shadowBlur = 34
  ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke()
  // 2. 品红中层
  ctx.globalAlpha = .8
  ctx.strokeStyle = '#ff48c4'
  ctx.lineWidth = 8
  ctx.shadowColor = '#ff48c4'
  ctx.shadowBlur = 20
  ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke()
  // 3. 白亮核心
  ctx.globalAlpha = 1
  ctx.strokeStyle = '#ffffff'
  ctx.lineWidth = 2.5
  ctx.shadowColor = '#ffffff'
  ctx.shadowBlur = 12
  ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke()
  // 4. 沿线循环奔跑的光点
  for (let k = 0; k < 6; k++) {
    const p = (t * .55 + k / 6) % 1
    const x = a.x + (b.x - a.x) * p, y = a.y + (b.y - a.y) * p
    ctx.fillStyle = k % 2 ? '#ffd166' : '#ffffff'
    ctx.shadowColor = ctx.fillStyle
    ctx.shadowBlur = 16
    ctx.beginPath(); ctx.arc(x, y, 3.4, 0, Math.PI * 2); ctx.fill()
  }
  ctx.restore()

  // 五连棋子：依次点亮的能量环 + 脉冲光晕
  pts.forEach((p, i) => {
    const local = t - i * .11
    ctx.save()
    ctx.strokeStyle = `rgba(255,209,102,${.5 + .4 * Math.sin(t * 6 + i)})`
    ctx.lineWidth = 2.5
    ctx.shadowColor = '#ffd166'
    ctx.shadowBlur = 20
    ctx.beginPath(); ctx.arc(p.x, p.y, CELL / 2 + 5 + Math.sin(t * 5 + i) * 2, 0, Math.PI * 2); ctx.stroke()
    if (local >= 0 && local < .7) {
      const bt = local / .7
      ctx.globalAlpha = 1 - bt
      ctx.strokeStyle = '#ffffff'
      ctx.lineWidth = 3
      ctx.beginPath(); ctx.arc(p.x, p.y, CELL * .4 + bt * CELL * 1.5, 0, Math.PI * 2); ctx.stroke()
    }
    ctx.restore()
  })

  // 胜利瞬间：旋转放射光束 + 中心闪光
  if (t < 1.4) {
    const ft = t / 1.4
    ctx.save()
    ctx.globalAlpha = (1 - ft) * .5
    ctx.translate(W / 2, W / 2)
    ctx.rotate(t * .5)
    for (let i = 0; i < 16; i++) {
      ctx.rotate(Math.PI * 2 / 16)
      const g = ctx.createLinearGradient(0, 0, W * .75, 0)
      g.addColorStop(0, 'rgba(122,245,247,.55)')
      g.addColorStop(1, 'rgba(122,245,247,0)')
      ctx.fillStyle = g
      ctx.beginPath(); ctx.moveTo(0, -7); ctx.lineTo(W * .75, 0); ctx.lineTo(0, 7); ctx.closePath(); ctx.fill()
    }
    ctx.restore()
    const flash = ctx.createRadialGradient(a.x, a.y, 0, a.x, a.y, W * .6)
    flash.addColorStop(0, `rgba(255,255,255,${(1 - ft) * .5})`)
    flash.addColorStop(1, 'rgba(255,255,255,0)')
    ctx.fillStyle = flash
    ctx.fillRect(0, 0, W, W)
  }

  // 持续循环的扫描线
  const scanY = ((t * 90) % (W + 80)) - 40
  const sg = ctx.createLinearGradient(0, scanY - 24, 0, scanY + 24)
  sg.addColorStop(0, 'rgba(45,226,230,0)')
  sg.addColorStop(.5, 'rgba(45,226,230,.16)')
  sg.addColorStop(1, 'rgba(45,226,230,0)')
  ctx.fillStyle = sg
  ctx.fillRect(0, scanY - 24, W, 48)
}

function drawLastMove(now) {
  const cx = PAD + lastMove.x * CELL, cy = PAD + lastMove.y * CELL
  const pulse = .5 + .5 * Math.sin(now / 260)
  ctx.save()
  ctx.strokeStyle = `rgba(45,226,230,${.45 + .35 * pulse})`
  ctx.lineWidth = 2
  ctx.shadowColor = '#2de2e6'
  ctx.shadowBlur = 10
  ctx.beginPath(); ctx.arc(cx, cy, 6 + pulse * 3, 0, Math.PI * 2); ctx.stroke()
  ctx.restore()
}

/** 联机模式只拿到 winner，扫描棋盘找出五连坐标用于胜利特效 */
function findAnyWinLine(color) {
  const dirs = [[1, 0], [0, 1], [1, 1], [1, -1]]
  for (let y = 0; y < SIZE; y++) for (let x = 0; x < SIZE; x++) {
    if (board[y][x] !== color) continue
    for (const [dx, dy] of dirs) {
      const line = [{ x, y }]
      for (let s = 1; s < 5; s++) {
        const nx = x + dx * s, ny = y + dy * s
        if (inBounds(nx, ny) && board[ny][nx] === color) line.push({ x: nx, y: ny })
        else break
      }
      if (line.length >= 5) return line.slice(0, 5)
    }
  }
  return []
}

/* ========================= 网络对弈状态 ========================= */
const myFriends = ref([])            // 好友列表（邀请对象）
const inviteFriendId = ref(null)     // 选中的好友
const inviteColor = ref('black')     // 我执的颜色
const inviting = ref(false)
const toAccept = ref([])             // 收到的对弈邀请
const currentGame = ref(null)        // 进行中/等待中的对局详情
const myGamesPoll = ref(null)        // 轮询定时器
let lastSyncedBoard = ''             // 上次同步到的棋盘串（变了才重绘）

const iAmBlack = computed(() => {
  const u = userRef.value
  return !!(u && currentGame.value && currentGame.value.blackUserId === u.id)
})
const currentOpponentName = computed(() => {
  const g = currentGame.value
  if (!g) return ''
  const u = userRef.value
  if (!u) return ''
  return g.blackUserId === u.id ? g.whiteUsername : g.blackUsername
})
const isMyTurn = computed(() => {
  const g = currentGame.value
  const u = userRef.value
  if (!g || !u || g.status !== 1) return false
  const myColor = g.blackUserId === u.id ? 1 : 2
  return g.turn === myColor && g.winner === 0
})

// 当前登录用户（App.vue provide 注入）
const userRef = inject('appUser', null)

function boardFromServer(str) {
  const arr = newBoard()
  if (!str || str.length !== SIZE * SIZE) return arr
  for (let y = 0; y < SIZE; y++) for (let x = 0; x < SIZE; x++) {
    arr[y][x] = Number(str[y * SIZE + x]) || 0
  }
  return arr
}

async function loadFriends() {
  try {
    const res = await fetchFriends()
    myFriends.value = res.data || []
    if (!inviteFriendId.value && myFriends.value.length) {
      inviteFriendId.value = myFriends.value[0].friendId
    }
  } catch (_) { /* 未登录等情况忽略 */ }
}

async function sendInvite() {
  if (!inviteFriendId.value || inviting.value) return
  inviting.value = true
  try {
    const res = await inviteGomoku(inviteFriendId.value, inviteColor.value)
    currentGame.value = res.data
    lastSyncedBoard = currentGame.value.board
    board = boardFromServer(currentGame.value.board)
    lastMove = null
    over = false
    gameOver.value = false
    winner.value = 0
    statusText.value = '邀请已发送，等待 @' + currentOpponentName.value + ' 接受…'
    draw()
    if (notify) notify('✓ ' + (res.message || '邀请已发送'))
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '邀请失败'))
  } finally {
    inviting.value = false
  }
}

async function doAcceptInvite(g) {
  try {
    const res = await acceptGomoku(g.id)
    enterPlaying(res.data)
    if (notify) notify('✓ 对弈开始，黑方先手')
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '接受失败'))
    pollOnce()
  }
}

async function doDeclineInvite(g) {
  try {
    await declineGomoku(g.id)
    pollOnce()
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '拒绝失败'))
  }
}

/** 邀请人取消还没被接受的邀请（后端 decline 双方未开始时均可调） */
async function cancelWaiting() {
  const g = currentGame.value
  if (!g || g.status !== 0) return
  try {
    await declineGomoku(g.id)
    currentGame.value = null
    lastSyncedBoard = ''
    reset()
    if (notify) notify('已取消对弈邀请')
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '取消失败'))
  }
}

/** 切入对弈中的画面 */
function enterPlaying(game) {
  currentGame.value = game
  lastSyncedBoard = game.board
  board = boardFromServer(game.board)
  lastMove = game.lastMoveX != null && game.lastMoveY != null
    ? { x: game.lastMoveX, y: game.lastMoveY }
    : null
  over = false
  gameOver.value = false
  winner.value = 0
  syncNetStatusText(game)
  draw()
}

function syncNetStatusText(g) {
  if (!g) return
  if (g.status === 0) {
    statusText.value = '邀请已发送，等待 @' + currentOpponentName.value + ' 接受…'
  } else if (g.status === 1 && g.winner === 0) {
    statusText.value = isMyTurn.value
      ? (iAmBlack.value ? '轮到你（黑●）落子' : '轮到你（白○）落子')
      : '等待 @' + currentOpponentName.value + ' 落子…'
  } else if (g.status === 2 || g.winner !== 0) {
    over = true
    gameOver.value = true
    winner.value = g.winner
    if ((g.winner === 1 || g.winner === 2) && !winLine.length) {
      const line = findAnyWinLine(g.winner)
      if (line.length) { winLine = line; spawnWinBurst(line, g.winner); ensureFxLoop() }
    }
  }
}

/** 轮询一次：刷新邀请列表；进行中的对局同步棋盘 */
async function pollOnce() {
  if (mode.value !== 'net') return
  try {
    const res = await fetchMyGames()
    const d = res.data || {}
    toAccept.value = d.toAccept || []
    const active = (d.playing || [])[0] || null
    const waiting = (d.waiting || [])[0] || null

    if (active) {
      // 对弈中：拉详情，有变化才更新
      const detail = await fetchGomokuGame(active.id)
      const g = detail.data
      if (!g) return
      const isNew = !currentGame.value || currentGame.value.id !== g.id
      const changed = g.board !== lastSyncedBoard
        || g.status !== (currentGame.value && currentGame.value.status)
        || g.winner !== (currentGame.value && currentGame.value.winner)
      if (isNew) {
        enterPlaying(g)
      } else if (changed) {
        currentGame.value = g
        board = boardFromServer(g.board)
        lastSyncedBoard = g.board
        lastMove = g.lastMoveX != null ? { x: g.lastMoveX, y: g.lastMoveY } : null
        if (lastMove && board[lastMove.y] && board[lastMove.y][lastMove.x]) {
          spawnDrop(lastMove.x, lastMove.y, board[lastMove.y][lastMove.x])
        }
        syncNetStatusText(g)
        draw()
      }
    } else if (waiting && (!currentGame.value || currentGame.value.id !== waiting.id)) {
      // 我发起的邀请还在等待中
      currentGame.value = waiting
      board = boardFromServer(waiting.board)
      lastMove = null
      statusText.value = '邀请已发送，等待 @' + currentOpponentName.value + ' 接受…'
      draw()
    } else if (!active && !waiting && currentGame.value && currentGame.value.status === 0) {
      // 等待中的局消失了（对方拒绝/取消）→ 回到准备界面并提示
      currentGame.value = null
      lastSyncedBoard = ''
      reset()
      if (notify) notify('对方已拒绝或取消了这次对弈邀请')
    }
  } catch (_) { /* 网络抖动忽略本轮 */ }
}

function startNetPolling() {
  stopNetPolling()
  loadFriends()
  pollOnce()
  myGamesPoll.value = setInterval(pollOnce, 1500)
}

function stopNetPolling() {
  if (myGamesPoll.value) { clearInterval(myGamesPoll.value); myGamesPoll.value = null }
}

async function netMove(x, y) {
  const g = currentGame.value
  if (!g || !isMyTurn.value) return
  try {
    const res = await moveGomoku(g.id, x, y)
    const ng = res.data
    currentGame.value = ng
    lastSyncedBoard = ng.board
    board = boardFromServer(ng.board)
    lastMove = ng.lastMoveX != null ? { x: ng.lastMoveX, y: ng.lastMoveY } : null
    if (lastMove && board[lastMove.y] && board[lastMove.y][lastMove.x]) {
      spawnDrop(lastMove.x, lastMove.y, board[lastMove.y][lastMove.x])
    }
    syncNetStatusText(ng)
    draw()
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '落子失败'))
  }
}

async function netResign() {
  const g = currentGame.value
  if (!g) return
  try {
    const res = await resignGomoku(g.id)
    currentGame.value = res.data
    syncNetStatusText(res.data)
    draw()
    if (notify) notify('已认输')
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '操作失败'))
  }
}

/** 网络对局结束后点「再来一局」→ 回到准备界面 */
function netBackToSetup() {
  currentGame.value = null
  lastSyncedBoard = ''
  reset()
}

/* ========================= 本地模式（人机/双人） ========================= */

function inBounds(x, y) { return x >= 0 && y >= 0 && x < SIZE && y < SIZE }
function newBoard() { return Array.from({ length: SIZE }, () => Array(SIZE).fill(EMPTY)) }

function reset() {
  board = newBoard()
  current = BLACK
  over = false
  gameOver.value = false
  winner.value = 0
  aiThinking = false
  if (aiTimer) { clearTimeout(aiTimer); aiTimer = null }
  lastMove = null
  winLine = []
  ripples = []
  sparks = []
  dropAnim = null
  winBorn = 0
  if (fxRaf) { cancelAnimationFrame(fxRaf); fxRaf = null }
  if (mode.value === 'net') {
    statusText.value = currentGame.value && currentGame.value.status === 0
      ? '邀请已发送，等待 @' + currentOpponentName.value + ' 接受…'
      : '选择好友并选择执子颜色，发起对弈邀请'
  } else {
    statusText.value = mode.value === 'ai' ? '你执黑先手 · 点击棋盘落子' : '双人对战 · 黑方先手'
  }
  draw()
}

/** 切换对弈模式：人机 / 双人 / 网络邀请，切换后重开 */
function switchMode(m) {
  if (mode.value === m) return
  mode.value = m
  if (m === 'net') {
    currentGame.value = null
    lastSyncedBoard = ''
    startNetPolling()
  } else {
    stopNetPolling()
  }
  reset()
}

function draw(ts) {
  if (!ctx) return
  const now = ts || performance.now()
  const W = SIZE * CELL + PAD * 2
  const H = W
  const wood = ctx.createLinearGradient(0, 0, W, H)
  wood.addColorStop(0, '#f0e0c0')
  wood.addColorStop(1, '#ddc9a3')
  ctx.fillStyle = wood
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
  // 棋子（最后一手带弹入回弹）
  for (let y = 0; y < SIZE; y++) for (let x = 0; x < SIZE; x++) {
    if (board[y][x] === EMPTY) continue
    let scale = 1
    if (dropAnim && dropAnim.x === x && dropAnim.y === y) {
      const t = Math.min(1, Math.max(0, (now - dropAnim.born) / 260))
      scale = 1.65 - .65 * easeOutBack(t)
    }
    drawStone(x, y, board[y][x], scale)
  }
  // 胜利：五连流光线 + 脉冲光环
  if (winLine.length) drawWinLine(now)
  // 最后一手脉冲圈
  if (lastMove && lastMove.x != null) drawLastMove(now)
  // 落子涟漪 / 粒子
  drawEffects(now)
  if (hasActiveFx(now)) ensureFxLoop()
}

function drawStone(x, y, color, scale = 1) {
  const cx = PAD + x * CELL
  const cy = PAD + y * CELL
  const r = (CELL / 2 - 2) * scale
  if (winLine.length && winLine.some((p) => p.x === x && p.y === y)) {
    ctx.save()
    ctx.shadowColor = '#ffd166'
    ctx.shadowBlur = 22
    ctx.fillStyle = 'rgba(255,209,102,.18)'
    ctx.beginPath(); ctx.arc(cx, cy, r + 4, 0, Math.PI * 2); ctx.fill()
    ctx.restore()
  }
  const g = ctx.createRadialGradient(cx - r / 3, cy - r / 3, r / 4, cx, cy, r)
  if (color === BLACK) { g.addColorStop(0, '#5a6478'); g.addColorStop(1, '#0b0e1a') }
  else { g.addColorStop(0, '#ffffff'); g.addColorStop(1, '#c4ccdd') }
  ctx.save()
  ctx.shadowColor = 'rgba(0,0,0,.45)'
  ctx.shadowBlur = 6
  ctx.shadowOffsetY = 2
  ctx.fillStyle = g
  ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
  ctx.restore()
  ctx.strokeStyle = 'rgba(0,0,0,0.25)'; ctx.lineWidth = 1
  ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
  // 高光点
  ctx.fillStyle = color === BLACK ? 'rgba(122,245,247,.32)' : 'rgba(255,255,255,.75)'
  ctx.beginPath(); ctx.arc(cx - r * .32, cy - r * .32, Math.max(1.2, r * .16), 0, Math.PI * 2); ctx.fill()
}

/** 返回五连坐标数组（用于胜利特效），未获胜返回 null */
function checkWin(x, y, color) {
  const dirs = [[1, 0], [0, 1], [1, 1], [1, -1]]
  for (const [dx, dy] of dirs) {
    const line = [{ x, y }]
    for (let s = 1; s < 5; s++) {
      const nx = x + dx * s, ny = y + dy * s
      if (inBounds(nx, ny) && board[ny][nx] === color) line.push({ x: nx, y: ny })
      else break
    }
    for (let s = 1; s < 5; s++) {
      const nx = x - dx * s, ny = y - dy * s
      if (inBounds(nx, ny) && board[ny][nx] === color) line.unshift({ x: nx, y: ny })
      else break
    }
    if (line.length >= 5) return line.slice(0, 5)
  }
  return null
}

function place(x, y, color) {
  board[y][x] = color
  lastMove = { x, y }
  spawnDrop(x, y, color)
  const line = checkWin(x, y, color)
  if (line) {
    over = true
    gameOver.value = true
    winner.value = color
    winLine = line
    spawnWinBurst(line, color)
    statusText.value = mode.value === 'ai'
      ? (color === BLACK ? '🎉 你赢了！' : 'AI 赢了，再来一局？')
      : (color === BLACK ? '⚫ 黑方获胜！' : '⚪ 白方获胜！')
    ensureFxLoop()
    return true
  }
  // 平局
  let full = true
  for (let yy = 0; yy < SIZE; yy++) for (let xx = 0; xx < SIZE; xx++)
    if (board[yy][xx] === EMPTY) { full = false; break }
  if (full) { over = true; gameOver.value = true; winner.value = 3; statusText.value = '平局！'; return true }
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
  if (over) return
  const rect = canvasRef.value.getBoundingClientRect()
  const sx = (e.clientX - rect.left) * (canvasRef.value.width / rect.width)
  const sy = (e.clientY - rect.top) * (canvasRef.value.height / rect.height)
  const gx = Math.round((sx - PAD) / CELL)
  const gy = Math.round((sy - PAD) / CELL)
  if (!inBounds(gx, gy) || board[gy][gx] !== EMPTY) return

  // 网络对弈：轮到我才发落子请求，落子成功后由服务端返回新局面
  if (mode.value === 'net') {
    if (isMyTurn.value) netMove(gx, gy)
    return
  }

  if (mode.value === 'pvp') {
    // 双人对战：黑白轮流落子，无需等待 AI
    if (!place(gx, gy, current)) {
      current = current === BLACK ? WHITE : BLACK
      statusText.value = current === BLACK ? '轮到黑方（●）落子' : '轮到白方（○）落子'
    }
    return
  }

  // 人机对弈：玩家执黑，AI 执白
  if (aiThinking || current !== BLACK) return
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
onBeforeUnmount(() => {
  stopNetPolling()
  if (fxRaf) { cancelAnimationFrame(fxRaf); fxRaf = null }
})
</script>

<template>
  <div class="game-box">
    <div class="game-head">
      <span class="g-status">{{ statusText }}</span>
      <!-- 模式切换：人机 / 双人 / 网络邀请 -->
      <div class="g-modes">
        <button class="g-mode" :class="{ on: mode === 'ai' }" @click="switchMode('ai')">🤖 人机</button>
        <button class="g-mode" :class="{ on: mode === 'pvp' }" @click="switchMode('pvp')">👥 双人</button>
        <button class="g-mode" :class="{ on: mode === 'net' }" @click="switchMode('net')">🌐 好友对弈</button>
      </div>
    </div>
    <div class="canvas-wrap">
      <canvas ref="canvasRef" :width="SIZE * CELL + PAD * 2" :height="SIZE * CELL + PAD * 2"
        class="g-canvas" @click="onBoardClick"></canvas>
      <div v-if="gameOver && mode !== 'net'" class="result-overlay" :class="winnerClass" @click="reset">
        <div class="fx-stage" aria-hidden="true">
          <div class="fx-grid"></div>
          <div v-if="winnerClass === 'win'" class="fx-rays"></div>
          <div class="fx-ring r1"></div>
          <div class="fx-ring r2"></div>
          <div class="fx-beam b1"></div>
          <div class="fx-beam b2"></div>
          <span v-for="(s, i) in stardust" :key="'s' + i" class="fx-star" :style="starStyle(s)"></span>
          <template v-if="winnerClass === 'win'">
            <span v-for="(c, i) in shards" :key="'c' + i" class="fx-shard" :style="shardStyle(c)"></span>
          </template>
        </div>
        <div class="fx-content">
          <div v-if="winnerClass === 'win'" class="fx-victory">VICTORY</div>
          <div class="fx-emblem">{{ winnerEmoji }}</div>
          <div class="fx-title">{{ winnerText }}</div>
          <div class="fx-sub">{{ winnerSub }}</div>
          <div v-if="winnerClass === 'win'" class="fx-badge-line"><i></i>五 子 连 珠 · 全 场 瞩 目<i></i></div>
          <div class="fx-btn">再来一局</div>
        </div>
      </div>
      <div v-else-if="gameOver && mode === 'net'" class="result-overlay" :class="winnerClass">
        <div class="fx-stage" aria-hidden="true">
          <div class="fx-grid"></div>
          <div v-if="winnerClass === 'win'" class="fx-rays"></div>
          <div class="fx-ring r1"></div>
          <div class="fx-ring r2"></div>
          <div class="fx-beam b1"></div>
          <div class="fx-beam b2"></div>
          <span v-for="(s, i) in stardust" :key="'s' + i" class="fx-star" :style="starStyle(s)"></span>
          <template v-if="winnerClass === 'win'">
            <span v-for="(c, i) in shards" :key="'c' + i" class="fx-shard" :style="shardStyle(c)"></span>
          </template>
        </div>
        <div class="fx-content">
          <div v-if="winnerClass === 'win'" class="fx-victory">VICTORY</div>
          <div class="fx-emblem">{{ winnerEmoji }}</div>
          <div class="fx-title">{{ winnerText }}</div>
          <div class="fx-sub">{{ winnerSub }}</div>
          <div v-if="winnerClass === 'win'" class="fx-badge-line"><i></i>五 子 连 珠 · 全 场 瞩 目<i></i></div>
          <div class="fx-btn" @click="netBackToSetup">发起下一局</div>
        </div>
      </div>
    </div>

    <!-- 网络对弈：等待对方接受（邀请人可随时取消，不必干等） -->
    <div v-if="mode === 'net' && currentGame && currentGame.status === 0 && !gameOver" class="net-waiting">
      <span class="net-vs">⏳ 已向 @{{ currentOpponentName }} 发出邀请，等待接受…（对方也可拒绝）</span>
      <button class="f-mini no" @click="cancelWaiting">取消邀请</button>
    </div>

    <!-- 网络对弈：准备面板（选好友 + 执子颜色） -->
    <div v-if="mode === 'net' && !currentGame" class="net-setup">
      <div class="ns-row">
        <label class="ns-label">对手</label>
        <select v-model="inviteFriendId" class="ns-select">
          <option v-for="f in myFriends" :key="f.friendId" :value="f.friendId">@{{ f.username }}</option>
        </select>
        <div class="ns-colors">
          <button class="ns-color" :class="{ on: inviteColor === 'black' }" @click="inviteColor = 'black'">● 我执黑（先手）</button>
          <button class="ns-color" :class="{ on: inviteColor === 'white' }" @click="inviteColor = 'white'">○ 我执白</button>
        </div>
        <button class="g-btn ns-go" :disabled="!inviteFriendId || inviting" @click="sendInvite">
          {{ inviting ? '发送中…' : '发起邀请' }}
        </button>
      </div>
      <p v-if="!myFriends.length" class="ns-hint">还没有好友：先去社区概览的「我的好友」里添加并等对方验证，再回来约棋。</p>

      <!-- 收到的对弈邀请 -->
      <div v-if="toAccept.length" class="ns-invites">
        <span class="ns-sec">收到的对弈邀请</span>
        <div v-for="g in toAccept" :key="g.id" class="ns-invite">
          <span class="ns-invite-name">@{{ g.hostUsername }} 邀请你对弈 · TA 执{{ g.blackUserId === g.guestUserId ? '白' : '黑' }}，你执{{ g.blackUserId === g.guestUserId ? '黑' : '白' }}</span>
          <button class="f-mini ok" @click="doAcceptInvite(g)">接受</button>
          <button class="f-mini no" @click="doDeclineInvite(g)">拒绝</button>
        </div>
      </div>
    </div>

    <!-- 网络对弈：对局中操作 -->
    <div v-if="mode === 'net' && currentGame && currentGame.status === 1 && !gameOver" class="net-ops">
      <span class="net-vs">
        {{ currentGame.blackUsername }}（●） vs {{ currentGame.whiteUsername }}（○） · 第 {{ (currentGame.board.match(/[^0]/g) || []).length + 1 }} 手
      </span>
      <button class="f-mini no" @click="netResign">认输</button>
    </div>

    <div class="g-actions" v-if="mode !== 'net'">
      <button class="g-btn" @click="reset">重新开局</button>
    </div>
    <p class="g-tip">
      {{ mode === 'ai' ? '你执黑（●）先手 · 五子连珠即胜 · AI 执白（○）'
        : mode === 'pvp' ? '黑方（●）先手，双方轮流落子 · 五子连珠即胜'
        : '邀请已验证的好友在线对弈 · 邀请人可选执黑（先手）或执白 · 双方页面自动同步' }}
    </p>
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
.game-head { width: 100%; display: flex; align-items: center; justify-content: space-between; gap: 10px; flex-wrap: wrap; }
.g-status { font-size: 13.5px; color: var(--cyan-soft); }
.g-modes { display: flex; gap: 6px; }
.g-mode {
  border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit; font-size: 12.5px;
  color: #cdd6f4; background: rgba(255, 255, 255, .05); padding: 5px 12px; border-radius: 999px; transition: .22s;
}
.g-mode:hover { color: #fff; border-color: var(--cyan); }
.g-mode.on {
  color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
}
.g-canvas {
  width: 426px; max-width: 100%; height: auto; border-radius: 12px; border: 1px solid rgba(255, 255, 255, .12);
  background: #e9d9b8; touch-action: none; cursor: pointer; display: block;
}
.canvas-wrap { position: relative; line-height: 0; }
.result-overlay {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  border-radius: 12px; cursor: pointer; overflow: hidden;
  background: rgba(6, 9, 26, .5);
  backdrop-filter: blur(2px) saturate(150%);
  animation: pop .25s ease-out;
}
@keyframes pop { from { opacity: 0; transform: scale(.92); } to { opacity: 1; transform: scale(1); } }
.g-actions { display: flex; gap: 10px; }
.g-btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 14px; font-weight: 600; color: #04121f;
  padding: 9px 22px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 20px rgba(138, 92, 255, .35); transition: .25s;
}
.g-btn:hover { transform: translateY(-1px); }
.g-btn:disabled { opacity: .5; cursor: not-allowed; }
.g-tip { font-size: 12px; color: #9fb0d8; margin: 0; text-align: center; }

/* ===== 网络对弈面板 ===== */
.net-setup { width: 100%; display: flex; flex-direction: column; gap: 10px; }
.ns-row { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.ns-label { font-size: 12.5px; color: #9fb0d8; }
.ns-select {
  flex: 1; min-width: 130px; max-width: 220px; padding: 8px 10px; font-family: inherit; font-size: 13px;
  color: #fff; background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .18);
  border-radius: 10px; outline: none;
}
.ns-select option { background: #141a34; color: #fff; }
.ns-colors { display: flex; gap: 6px; }
.ns-color {
  border: 1px solid rgba(255, 255, 255, .18); cursor: pointer; font-family: inherit; font-size: 12px;
  color: #cdd6f4; background: rgba(255, 255, 255, .05); padding: 7px 10px; border-radius: 999px; transition: .22s;
}
.ns-color.on { color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--magenta)); }
.ns-go { padding: 8px 16px; font-size: 13px; }
.ns-hint { font-size: 12px; color: #9fb0d8; margin: 0; }
.ns-invites { display: flex; flex-direction: column; gap: 8px; }
.ns-sec { font-size: 12px; color: #9fb0d8; letter-spacing: 1px; }
.ns-invite {
  display: flex; align-items: center; gap: 8px; padding: 9px 12px; border-radius: 11px;
  background: rgba(255, 72, 196, .1); border: 1px solid rgba(255, 72, 196, .3);
}
.ns-invite-name { flex: 1; font-size: 13px; color: #eef2ff; }
.f-mini {
  border: 1px solid rgba(255, 255, 255, .2); cursor: pointer; font-family: inherit; font-size: 12px;
  padding: 6px 14px; border-radius: 9px; transition: .2s;
}
.f-mini.ok { color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); }
.f-mini.no { color: #cdd6f4; background: transparent; }
.f-mini.no:hover { color: #ff8aa8; border-color: var(--magenta); }
.net-ops { width: 100%; display: flex; align-items: center; gap: 10px; }
.net-waiting { width: 100%; display: flex; align-items: center; gap: 10px; }
.net-vs { flex: 1; font-size: 12.5px; color: #9fb0d8; }

/* ===== 五子棋专属胜利舞台：赛博霓虹 · 全程动态 ===== */
.result-overlay.lose { background: rgba(14, 6, 26, .58); }
.result-overlay.draw { background: rgba(10, 10, 24, .58); }

.fx-stage { position: absolute; inset: 0; overflow: hidden; pointer-events: none; z-index: 1; }

.fx-grid {
  position: absolute; left: -50%; right: -50%; bottom: -40%; height: 92%;
  background-image:
    linear-gradient(rgba(45, 226, 230, .16) 1px, transparent 1px),
    linear-gradient(90deg, rgba(138, 92, 255, .16) 1px, transparent 1px);
  background-size: 34px 34px;
  transform: perspective(260px) rotateX(62deg);
  -webkit-mask-image: linear-gradient(180deg, transparent, #000 55%, transparent);
  mask-image: linear-gradient(180deg, transparent, #000 55%, transparent);
  animation: gridFlow 3.2s linear infinite;
}
@keyframes gridFlow { from { background-position: 0 0 } to { background-position: 0 34px } }

.fx-rays {
  position: absolute; top: 50%; left: 50%; width: 800px; height: 800px; margin: -400px 0 0 -400px;
  background: repeating-conic-gradient(from 0deg, rgba(122, 245, 247, .16) 0deg 3deg, transparent 3deg 24deg);
  -webkit-mask: radial-gradient(circle, #000 8%, transparent 62%);
  mask: radial-gradient(circle, #000 8%, transparent 62%);
  animation: raysSpin 12s linear infinite;
}
@keyframes raysSpin { to { transform: rotate(360deg) } }

.fx-ring {
  position: absolute; top: 50%; left: 50%; border-radius: 50%;
  background: conic-gradient(from 0deg, transparent 0deg, #2de2e6 60deg, #8a5cff 130deg, #ff48c4 200deg, transparent 260deg, transparent 360deg);
  -webkit-mask: radial-gradient(circle, transparent 62%, #000 64%);
  mask: radial-gradient(circle, transparent 62%, #000 64%);
  animation: ringSpin 4.5s linear infinite;
  filter: drop-shadow(0 0 12px rgba(45, 226, 230, .7));
}
.fx-ring.r1 { width: 330px; height: 330px; margin: -165px 0 0 -165px; opacity: .85; }
.fx-ring.r2 { width: 250px; height: 250px; margin: -125px 0 0 -125px; opacity: .6; animation-duration: 3s; animation-direction: reverse; }
@keyframes ringSpin { to { transform: rotate(360deg) } }

.fx-beam {
  position: absolute; top: -60%; width: 90px; height: 220%;
  background: linear-gradient(180deg, transparent, rgba(122, 245, 247, .28), rgba(255, 72, 196, .22), transparent);
  filter: blur(7px);
  animation: beamSweep 5.5s ease-in-out infinite;
}
.fx-beam.b1 { left: -20%; }
.fx-beam.b2 { left: 60%; animation-delay: -2.7s;
  background: linear-gradient(180deg, transparent, rgba(255, 72, 196, .24), rgba(138, 92, 255, .2), transparent); }
@keyframes beamSweep {
  0%, 100% { transform: translateX(-40px) rotate(22deg); opacity: .2 }
  50% { transform: translateX(220px) rotate(22deg); opacity: .9 }
}

.fx-star { position: absolute; border-radius: 50%; animation: starTwinkle var(--dur) ease-in-out var(--delay) infinite alternate; }
@keyframes starTwinkle {
  0% { opacity: .1; transform: scale(.4) translateY(0) }
  100% { opacity: 1; transform: scale(1.5) translateY(-14px) }
}

.fx-shard {
  position: absolute; top: -30px; border-radius: 2px; opacity: 0;
  box-shadow: 0 0 10px currentColor;
  animation: shardFly var(--dur) linear var(--delay) infinite;
}
@keyframes shardFly {
  0% { transform: translate3d(0, -30px, 0) rotate(0deg); opacity: 0 }
  10% { opacity: 1 }
  85% { opacity: 1 }
  100% { transform: translate3d(60px, 500px, 0) rotate(560deg); opacity: 0 }
}

.fx-content { position: relative; z-index: 3; display: flex; flex-direction: column; align-items: center; gap: 8px; }
.fx-victory {
  position: absolute; top: -96px; left: 50%; transform: translateX(-50%);
  font-size: 62px; font-weight: 900; letter-spacing: 12px; white-space: nowrap;
  color: transparent; -webkit-text-stroke: 1.5px rgba(122, 245, 247, .32);
  animation: victoryFloat 4s ease-in-out infinite;
}
@keyframes victoryFloat {
  0%, 100% { opacity: .5; transform: translateX(-50%) translateY(0) }
  50% { opacity: 1; transform: translateX(-50%) translateY(-8px) }
}
.fx-emblem {
  font-size: 52px; line-height: 1;
  filter: drop-shadow(0 0 20px rgba(255, 209, 102, .85));
  animation: emblemIn .8s cubic-bezier(.2, 1.6, .4, 1) both, emblemFloat 2.8s ease-in-out .8s infinite;
}
@keyframes emblemIn { from { transform: scale(0) rotate(-60deg); opacity: 0 } to { transform: scale(1) rotate(0); opacity: 1 } }
@keyframes emblemFloat { 0%, 100% { transform: translateY(0) } 50% { transform: translateY(-9px) } }

.fx-title {
  font-size: 34px; font-weight: 900; letter-spacing: 3px; line-height: 1.2; text-align: center;
  background: linear-gradient(100deg, #2de2e6 0%, #fff 28%, #ff8ad8 50%, #fff 72%, #2de2e6 100%);
  background-size: 220% 100%;
  -webkit-background-clip: text; background-clip: text; color: transparent;
  filter: drop-shadow(0 0 12px rgba(45, 226, 230, .75)) drop-shadow(0 0 26px rgba(255, 72, 196, .45));
  animation: titleShine 3s linear infinite, titleIn .65s .1s cubic-bezier(.2, 1.3, .3, 1) both;
}
@keyframes titleShine { from { background-position: 200% 0 } to { background-position: -20% 0 } }
@keyframes titleIn { from { opacity: 0; transform: scale(.7) translateY(18px) } to { opacity: 1; transform: none } }
.result-overlay.lose .fx-title { background-image: linear-gradient(100deg, #ff48c4, #fff 45%, #8a5cff); }
.result-overlay.draw .fx-title { background-image: linear-gradient(100deg, #ffd166, #fff 45%, #7af5f7); }

.fx-sub { font-size: 13px; color: #cdd6f4; letter-spacing: 1px; text-shadow: 0 0 10px rgba(122, 245, 247, .5); animation: fadeUp .6s .25s both; }
@keyframes fadeUp { from { opacity: 0; transform: translateY(12px) } to { opacity: 1; transform: none } }

.fx-badge-line { display: flex; align-items: center; gap: 10px; font-size: 11.5px; letter-spacing: 3px; color: #ffd166;
  animation: fadeUp .6s .35s both, glory 1.8s ease-in-out .9s infinite; }
.fx-badge-line i { display: block; width: 42px; height: 1px; background: linear-gradient(90deg, transparent, #ffd166); box-shadow: 0 0 8px #ffd166; }
.fx-badge-line i:last-child { background: linear-gradient(90deg, #ffd166, transparent); }
@keyframes glory { 0%, 100% { opacity: .65 } 50% { opacity: 1; text-shadow: 0 0 16px rgba(255, 209, 102, .9) } }

.fx-btn {
  position: relative; overflow: hidden; margin-top: 12px; cursor: pointer;
  font-size: 14.5px; font-weight: 800; letter-spacing: 2px; color: #04121f;
  padding: 11px 32px; border-radius: 12px;
  background: linear-gradient(120deg, #2de2e6, #8a5cff 55%, #ff48c4);
  background-size: 180% 100%;
  box-shadow: 0 0 22px rgba(45, 226, 230, .55), 0 10px 26px rgba(138, 92, 255, .4);
  animation: btnShine 3s linear infinite, fadeUp .6s .4s both;
}
.fx-btn::after {
  content: ""; position: absolute; top: 0; left: -120%; width: 55%; height: 100%;
  background: linear-gradient(100deg, transparent, rgba(255, 255, 255, .75), transparent);
  transform: skewX(-20deg); animation: btnSheen 2.6s ease-in-out infinite;
}
@keyframes btnShine { 0%, 100% { background-position: 0 0 } 50% { background-position: 100% 0 } }
@keyframes btnSheen { 0% { left: -120% } 55%, 100% { left: 140% } }
.fx-btn:hover { transform: scale(1.06); box-shadow: 0 0 34px rgba(255, 72, 196, .7); }
</style>
