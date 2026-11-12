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
let over = false
let lastMove = null

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
      // 等待中的局消失了（对方拒绝/被清理）→ 回到准备界面
      currentGame.value = null
      reset()
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
  lastMove = null
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
  if (lastMove && lastMove.x != null) {
    ctx.strokeStyle = lastMove.color === WHITE ? '#2de2e6' : '#ff48c4'
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
    statusText.value = mode.value === 'ai'
      ? (color === BLACK ? '🎉 你赢了！' : 'AI 赢了，再来一局？')
      : (color === BLACK ? '⚫ 黑方获胜！' : '⚪ 白方获胜！')
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
onBeforeUnmount(() => { stopNetPolling() })
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
        class="g-canvas" :class="{ 'g-wait': mode === 'net' && !isMyTurn }" @click="onBoardClick"></canvas>
      <div v-if="gameOver && mode !== 'net'" class="result-overlay" :class="winnerClass" @click="reset">
        <div class="r-emoji">{{ winnerEmoji }}</div>
        <div class="r-title">{{ winnerText }}</div>
        <div class="r-sub">{{ winnerSub }}</div>
        <div class="r-btn">再来一局</div>
      </div>
      <div v-else-if="gameOver && mode === 'net'" class="result-overlay" :class="winnerClass">
        <div class="r-emoji">{{ winnerEmoji }}</div>
        <div class="r-title">{{ winnerText }}</div>
        <div class="r-sub">{{ winnerSub }}</div>
        <div class="r-btn" @click="netBackToSetup">发起下一局</div>
      </div>
    </div>

    <!-- 网络对弈：准备面板（选好友 + 执子颜色） -->
    <div v-if="mode === 'net' && (!currentGame || currentGame.winner !== 0)" class="net-setup">
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
.g-canvas.g-wait { cursor: wait; opacity: .92; }
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
.net-vs { flex: 1; font-size: 12.5px; color: #9fb0d8; }
</style>
