<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import NavBar from '../components/NavBar.vue'
import GameFrame from '../components/games/GameFrame.vue'
import MazeGame from '../components/games/MazeGame.vue'
import Game2048 from '../components/games/Game2048.vue'
import MemoryGame from '../components/games/MemoryGame.vue'
import MinesweeperGame from '../components/games/MinesweeperGame.vue'
import SlidePuzzleGame from '../components/games/SlidePuzzleGame.vue'
import BreakoutGame from '../components/games/BreakoutGame.vue'
import SnakeGame from '../components/SnakeGame.vue'
import GomokuGame from '../components/GomokuGame.vue'
import { getAllRecords } from '../utils/gameScore'

/** 游戏专区：独立页面，与社区分开。所有小游戏在这里统一入口、统一记录 */
const games = [
  { key: 'maze', name: '时光迷宫', icon: '🌀', cat: '闯关', desc: '5 关随机迷宫，集齐时光碎片才能开启出口', tip: '方向键 / WASD 移动 · 5 关全通即大通关' },
  { key: 'breakout', name: '打砖块', icon: '🧱', cat: '闯关', desc: '3 关弹球挑战，消完砖块过关，球越来越快', tip: '鼠标 / ← → 控制挡板 · 空格开球' },
  { key: 'memory', name: '记忆翻牌', icon: '🃏', cat: '闯关', desc: '4 关翻牌配对，牌数逐关增加，考验记忆力', tip: '点击翻开两张相同牌 · 4 关全通即大通关' },
  { key: '2048', name: '2048', icon: '🔢', cat: '益智', desc: '滑动合并数字，合出 2048 即通关', tip: '方向键 / WASD / 滑动 · Z 撤销一步' },
  { key: 'mines', name: '扫雷', icon: '💣', cat: '益智', desc: '初 / 中 / 高 三档难度，排完所有雷即通关', tip: '左键翻开 · 右键插旗 · 首次点击必安全' },
  { key: 'slide', name: '数字华容道', icon: '🧩', cat: '益智', desc: '3×3 / 4×4 / 5×5，把数字还原成顺序', tip: '点击空格旁方块 · 方向键移动空格' },
  { key: 'snake', name: '贪吃蛇', icon: '🐍', cat: '经典', desc: '经典贪吃蛇，吃光点变长，填满棋盘即通关', tip: '方向键 / WASD / 屏幕按钮 · 空格暂停' },
  { key: 'gomoku', name: '五子棋', icon: '⚫', cat: '对战', desc: '人机 / 双人对弈，落子带炫酷光效，五连获胜', tip: '点击交叉点落子 · 顶部可切换对战模式' }
]

const COMPONENTS = {
  maze: MazeGame,
  breakout: BreakoutGame,
  memory: MemoryGame,
  '2048': Game2048,
  mines: MinesweeperGame,
  slide: SlidePuzzleGame,
  snake: SnakeGame,
  gomoku: GomokuGame
}
const CATS = ['全部', '闯关', '益智', '经典', '对战']

const route = useRoute()
const router = useRouter()
const cat = ref('全部')
const current = ref(null)
const keys = games.map((g) => g.key)
const records = ref(getAllRecords(keys))

const filtered = computed(() => cat.value === '全部' ? games : games.filter((g) => g.cat === cat.value))
const currentGame = computed(() => games.find((g) => g.key === current.value) || null)
const gameComponent = computed(() => COMPONENTS[current.value] || null)
const clearedGames = computed(() => games.filter((g) => (records.value[g.key]?.clears || 0) > 0).length)
const totalClears = computed(() => Object.values(records.value).reduce((s, r) => s + (r.clears || 0), 0))
const progress = computed(() => Math.round(clearedGames.value / games.length * 100))

function hasCleared(g) { return (records.value[g.key]?.clears || 0) > 0 }
function recordText(g) {
  const r = records.value[g.key] || {}
  switch (g.key) {
    case 'maze': return r.bestTime ? `最快全通 ${r.bestTime}s · 通关 ${r.clears} 次` : (r.maxLevel ? `最高第 ${r.maxLevel} 关` : '还没挑战过')
    case 'breakout': return r.bestScore ? `最高 ${r.bestScore} 分 · 通关 ${r.clears} 次` : (r.maxLevel ? `最高第 ${r.maxLevel} 关` : '还没挑战过')
    case 'memory': return r.clears ? `全通 ${r.clears} 次 · 最少 ${r.bestMoves} 步` : (r.maxLevel ? `最高第 ${r.maxLevel} 关` : '还没挑战过')
    case '2048': return r.bestScore ? `最高 ${r.bestScore} 分 · 最大 ${r.maxTile || 2}` : '还没挑战过'
    case 'mines': return r.clears ? `累计通关 ${r.clears} 次` : '还没挑战过'
    case 'slide': return r.clears ? `累计通关 ${r.clears} 次` : '还没挑战过'
    case 'snake': {
      const hs = Number(localStorage.getItem('lc_snake_highscore') || 0)
      return hs ? `本机最高 ${hs} 分` : '还没挑战过'
    }
    case 'gomoku': return '人机 / 双人 · 五连即胜'
    default: return '点开就能玩'
  }
}

function openGame(key) { current.value = key }
function closeGame() {
  current.value = null
  records.value = getAllRecords(keys)
  if (route.query.play) router.replace({ path: '/games' })
}
function goFun() { router.push('/fun') }

onMounted(() => {
  const play = route.query.play
  if (play && games.some((g) => g.key === play)) openGame(play)
})
</script>

<template>
  <div class="page">
    <NavBar />
    <main class="content">
      <header class="head">
        <span class="kicker">🎮 娱乐 · 独立页面</span>
        <h1>游戏专区</h1>
        <p>8 款小游戏，通关成绩自动保存在本机。从迷宫开始，一座一座闯过去吧。</p>
        <div class="head-links">
          <button class="link-btn" @click="goFun">🎉 去娱乐专区 →</button>
          <button class="link-btn ghost" @click="router.push('/community')">← 回社区</button>
        </div>
      </header>

      <!-- 成绩概览 -->
      <section class="stats">
        <div class="st"><span class="st-num">{{ games.length }}</span><span class="st-label">款小游戏</span></div>
        <div class="st"><span class="st-num">{{ clearedGames }}</span><span class="st-label">已通关</span></div>
        <div class="st"><span class="st-num">{{ totalClears }}</span><span class="st-label">累计通关次数</span></div>
        <div class="st st-progress">
          <span class="st-label">通关进度 <b>{{ progress }}%</b></span>
          <span class="st-track"><i :style="{ width: progress + '%' }"></i></span>
          <span class="st-hint">每通关一款游戏，这里就会亮起一枚徽章</span>
        </div>
      </section>

      <!-- 分类 -->
      <div class="cats">
        <button
          v-for="c in CATS" :key="c"
          class="chip" :class="{ on: cat === c }"
          @click="cat = c"
        >{{ c }}</button>
        <span class="cats-count">共 {{ filtered.length }} 款</span>
      </div>

      <!-- 游戏大厅 -->
      <div class="game-grid">
        <button v-for="g in filtered" :key="g.key" class="game-card" @click="openGame(g.key)">
          <div class="gc-top">
            <span class="gc-icon">{{ g.icon }}</span>
            <span class="gc-cat" :class="'cat-' + g.cat">{{ g.cat }}</span>
          </div>
          <h3 class="gc-name">{{ g.name }}</h3>
          <p class="gc-desc">{{ g.desc }}</p>
          <p class="gc-rec">🏅 {{ recordText(g) }}</p>
          <div class="gc-foot">
            <span v-if="hasCleared(g)" class="gc-clear">✓ 已通关</span>
            <span v-else class="gc-new">未通关</span>
            <span class="gc-play">开始游戏 →</span>
          </div>
        </button>
      </div>

      <!-- 成就墙 -->
      <section class="achv">
        <h2 class="achv-title">🏅 通关成就墙</h2>
        <p class="achv-sub">点亮所有徽章，成为时光游戏大师</p>
        <div class="achv-grid">
          <div v-for="g in games" :key="g.key" class="badge" :class="{ lit: hasCleared(g) }" :title="g.name">
            <span class="b-emoji">{{ hasCleared(g) ? g.icon : '🔒' }}</span>
            <span class="b-name">{{ g.name }}</span>
            <span class="b-times" v-if="hasCleared(g)">×{{ records[g.key].clears }}</span>
          </div>
        </div>
      </section>
    </main>

    <GameFrame
      v-if="currentGame"
      :title="currentGame.name"
      :icon="currentGame.icon"
      :subtitle="currentGame.tip"
      @close="closeGame"
    >
      <component :is="gameComponent" :key="current" />
    </GameFrame>
  </div>
</template>

<style scoped>
.page { position: relative; z-index: 2; height: 100vh; overflow-y: auto; color: #eef2ff; }
.content { max-width: 1120px; margin: 0 auto; padding: 36px 22px 70px; }
.head { text-align: center; margin-bottom: 26px; }
.kicker {
  display: inline-block; font-size: 11.5px; letter-spacing: 2px; color: var(--cyan-soft);
  padding: 5px 14px; border-radius: 999px; border: 1px solid rgba(45, 226, 230, .4);
  background: rgba(45, 226, 230, .08); margin-bottom: 12px;
}
.head h1 {
  font-size: 32px; font-weight: 700; letter-spacing: 3px;
  background: linear-gradient(135deg, var(--cyan), #fff 45%, var(--magenta));
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.head p { color: #9fb0d8; font-size: 13.5px; margin-top: 10px; }
.head-links { display: flex; gap: 10px; justify-content: center; margin-top: 16px; flex-wrap: wrap; }
.link-btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13px; font-weight: 600; color: #04121f;
  padding: 9px 20px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 8px 22px rgba(138, 92, 255, .36); transition: .22s;
}
.link-btn:hover { transform: translateY(-2px); }
.link-btn.ghost { color: #cdd6f4; background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .18); box-shadow: none; }
.link-btn.ghost:hover { color: #fff; border-color: var(--cyan); }

/* ===== 成绩概览 ===== */
.stats {
  display: grid; grid-template-columns: 140px 140px 160px 1fr; gap: 16px;
  padding: 18px 22px; margin-bottom: 24px; border-radius: 18px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
}
.st { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; border-right: 1px solid rgba(255, 255, 255, .1); }
.st:last-child { border-right: 0; }
.st-num { font-size: 32px; font-weight: 700; line-height: 1;
  background: linear-gradient(135deg, var(--cyan), var(--magenta)); -webkit-background-clip: text; background-clip: text; color: transparent; }
.st-label { font-size: 12.5px; color: #9fb0d8; letter-spacing: 1px; }
.st-progress { align-items: stretch; justify-content: center; gap: 8px; padding-left: 10px; }
.st-progress .st-label b { color: var(--cyan-soft); }
.st-track { height: 8px; border-radius: 999px; background: rgba(255, 255, 255, .08); overflow: hidden; }
.st-track i { display: block; height: 100%; border-radius: 999px; background: linear-gradient(90deg, var(--cyan), var(--purple) 60%, var(--magenta)); transition: width .5s; }
.st-hint { font-size: 11.5px; color: #7e8ab0; }

/* ===== 分类 ===== */
.cats { display: flex; align-items: center; gap: 9px; flex-wrap: wrap; margin-bottom: 18px; }
.chip {
  border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit;
  background: rgba(255, 255, 255, .05); color: #cdd6f4; font-size: 13px; padding: 7px 18px; border-radius: 999px; transition: .22s;
}
.chip:hover { color: #fff; border-color: var(--cyan); }
.chip.on { color: #04121f; font-weight: 600; border-color: transparent; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 6px 16px rgba(138, 92, 255, .35); }
.cats-count { margin-left: auto; font-size: 12px; color: #7e8ab0; }

/* ===== 游戏卡片 ===== */
.game-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(232px, 1fr)); gap: 16px; }
.game-card {
  text-align: left; cursor: pointer; font-family: inherit; color: inherit;
  display: flex; flex-direction: column; gap: 8px; padding: 18px; border-radius: 18px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .72), rgba(12, 14, 38, .64));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
  transition: transform .28s, border-color .28s, box-shadow .28s;
}
.game-card:hover { transform: translateY(-6px); border-color: var(--cyan); box-shadow: 0 22px 52px rgba(45, 226, 230, .24); }
.gc-top { display: flex; align-items: flex-start; justify-content: space-between; }
.gc-icon { font-size: 34px; line-height: 1; filter: drop-shadow(0 4px 12px rgba(45, 226, 230, .4)); }
.gc-cat { font-size: 11px; padding: 3px 10px; border-radius: 999px; color: #cdd6f4; background: rgba(255, 255, 255, .08); border: 1px solid rgba(255, 255, 255, .16); }
.gc-cat.cat-闯关 { color: #7af5f7; border-color: rgba(45, 226, 230, .5); background: rgba(45, 226, 230, .1); }
.gc-cat.cat-益智 { color: #c9a9ff; border-color: rgba(138, 92, 255, .5); background: rgba(138, 92, 255, .1); }
.gc-cat.cat-经典 { color: #ffd0a9; border-color: rgba(255, 176, 120, .5); background: rgba(255, 176, 120, .1); }
.gc-cat.cat-对战 { color: #ff8ad8; border-color: rgba(255, 72, 196, .5); background: rgba(255, 72, 196, .1); }
.gc-name { font-size: 18px; font-weight: 700; color: #eef2ff; }
.gc-desc { font-size: 12.5px; line-height: 1.6; color: #9fb0d8; min-height: 40px; }
.gc-rec { font-size: 11.5px; color: var(--cyan-soft); padding: 8px 10px; border-radius: 10px; background: rgba(45, 226, 230, .07); border: 1px solid rgba(45, 226, 230, .16); }
.gc-foot { display: flex; align-items: center; gap: 8px; margin-top: 2px; }
.gc-clear { font-size: 11px; font-weight: 600; color: #04121f; padding: 3px 9px; border-radius: 999px; background: linear-gradient(135deg, var(--cyan), var(--purple)); }
.gc-new { font-size: 11px; color: #7e8ab0; padding: 3px 9px; border-radius: 999px; border: 1px solid rgba(255, 255, 255, .12); }
.gc-play { margin-left: auto; font-size: 12.5px; font-weight: 600; color: var(--cyan-soft); }

/* ===== 成就墙 ===== */
.achv { margin-top: 36px; padding: 22px; border-radius: 18px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14); }
.achv-title { font-size: 19px; font-weight: 600; letter-spacing: 1px; }
.achv-sub { font-size: 12.5px; color: #9fb0d8; margin-top: 4px; }
.achv-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(108px, 1fr)); gap: 12px; margin-top: 18px; }
.badge { display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 14px 8px; border-radius: 14px;
  background: rgba(255, 255, 255, .04); border: 1px solid rgba(255, 255, 255, .1); opacity: .55; transition: .3s; }
.badge.lit { opacity: 1; background: linear-gradient(160deg, rgba(45, 226, 230, .14), rgba(138, 92, 255, .14));
  border-color: rgba(45, 226, 230, .45); box-shadow: 0 8px 24px rgba(45, 226, 230, .18); }
.b-emoji { font-size: 28px; line-height: 1; }
.b-name { font-size: 11.5px; color: #cdd6f4; text-align: center; }
.b-times { font-size: 10.5px; color: var(--cyan-soft); }

@media (max-width: 760px) {
  .stats { grid-template-columns: 1fr 1fr; }
  .st { border-right: 0; }
  .st-progress { grid-column: 1 / -1; padding-left: 0; }
}
</style>
