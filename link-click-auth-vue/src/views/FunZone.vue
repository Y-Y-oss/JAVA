<script setup>
import { useRouter } from 'vue-router'
import NavBar from '../components/NavBar.vue'
import BiliRow from '../components/BiliRow.vue'
import FunPanel from '../components/FunPanel.vue'
import { getGameTheme } from '../utils/gameThemes'

/** 娱乐专区：与社区分开的独立功能页。视频一行 4 个 + 小玩法集市 + 游戏专区快捷入口 */
const router = useRouter()
const quickGames = [
  { key: 'maze', icon: '🌀', name: '时光迷宫' },
  { key: '2048', icon: '🔢', name: '2048' },
  { key: 'memory', icon: '🃏', name: '记忆翻牌' },
  { key: 'mines', icon: '💣', name: '扫雷' },
  { key: 'slide', icon: '🧩', name: '华容道' },
  { key: 'breakout', icon: '🧱', name: '打砖块' },
  { key: 'snake', icon: '🐍', name: '贪吃蛇' },
  { key: 'gomoku', icon: '⚫', name: '五子棋' }
]
function gameCardStyle(key) {
  const t = getGameTheme(key)
  return { '--card-main': t.main, '--card-rgb': t.rgb }
}
function goGames() { router.push('/games') }
function goQuick(key) { router.push({ path: '/games', query: { play: key } }) }
</script>

<template>
  <div class="page">
    <NavBar />
    <main class="content">
      <header class="head">
        <span class="kicker">🎉 娱乐 · 独立功能</span>
        <h1>娱乐专区</h1>
        <p>番剧、游戏、抽签、摸鱼小玩具都在这儿了。和社区分开的一块自留地，随时来放松一下。</p>
        <div class="head-links">
          <button class="link-btn" @click="goGames">🎮 进入游戏专区 →</button>
          <button class="link-btn ghost" @click="router.push('/community')">← 回社区</button>
        </div>
      </header>

      <!-- 游戏专区快捷入口 -->
      <section class="quick">
        <div class="sec-head">
          <h2>🎮 游戏专区 · 快速开玩</h2>
          <button class="sec-more" @click="goGames">查看全部 8 款 →</button>
        </div>
        <div class="quick-row">
          <button v-for="g in quickGames" :key="g.key" class="quick-card" :style="gameCardStyle(g.key)" @click="goQuick(g.key)">
            <span class="qc-emoji">{{ g.icon }}</span>
            <b>{{ g.name }}</b>
            <small>开始 →</small>
          </button>
        </div>
      </section>

      <!-- B 站视频：固定一行 4 个 -->
      <section class="bili-box">
        <BiliRow />
      </section>

      <!-- 小玩法集市 -->
      <section class="plays">
        <div class="sec-head">
          <h2>🎪 小玩法集市</h2>
          <span class="sec-note">10 个随手就能玩的小东西</span>
        </div>
        <FunPanel />
      </section>
    </main>
  </div>
</template>

<style scoped>
.page { position: relative; z-index: 2; height: 100vh; overflow-y: auto; color: #eef2ff; }
.content { max-width: 1120px; margin: 0 auto; padding: 36px 22px 70px; }
.head { text-align: center; margin-bottom: 28px; }
.kicker {
  display: inline-block; font-size: 11.5px; letter-spacing: 2px; color: var(--cyan-soft);
  padding: 5px 14px; border-radius: 999px; border: 1px solid rgba(255, 72, 196, .4);
  background: rgba(255, 72, 196, .08); margin-bottom: 12px;
}
.head h1 {
  font-size: 32px; font-weight: 700; letter-spacing: 3px;
  background: linear-gradient(135deg, var(--magenta), #fff 45%, var(--cyan));
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.head p { color: #9fb0d8; font-size: 13.5px; margin-top: 10px; }
.head-links { display: flex; gap: 10px; justify-content: center; margin-top: 16px; flex-wrap: wrap; }
.link-btn {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13px; font-weight: 600; color: #04121f;
  padding: 9px 20px; border-radius: 11px;
  background: linear-gradient(135deg, var(--magenta), var(--purple) 55%, var(--cyan));
  box-shadow: 0 8px 22px rgba(255, 72, 196, .34); transition: .22s;
}
.link-btn:hover { transform: translateY(-2px); }
.link-btn.ghost { color: #cdd6f4; background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .18); box-shadow: none; }
.link-btn.ghost:hover { color: #fff; border-color: var(--cyan); }

.sec-head { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
.sec-head h2 { font-size: 20px; font-weight: 600; letter-spacing: 1px; color: #eef2ff; }
.sec-more {
  margin-left: auto; border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .06);
  color: var(--cyan-soft); font-family: inherit; font-size: 12.5px; cursor: pointer;
  padding: 7px 16px; border-radius: 999px; transition: .22s;
}
.sec-more:hover { color: #04121f; border-color: transparent; background: var(--cyan); }
.sec-note { margin-left: auto; font-size: 12.5px; color: #7e8ab0; }

/* 游戏快捷入口 */
.quick { margin-bottom: 32px; }
.quick-row { display: grid; grid-template-columns: repeat(8, minmax(0, 1fr)); gap: 12px; }
.quick-card {
  display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 14px 6px;
  cursor: pointer; font-family: inherit; color: #eef2ff; border-radius: 16px;
  background: linear-gradient(160deg, rgba(var(--card-rgb), .12), rgba(12, 14, 38, .7));
  border: 1px solid rgba(var(--card-rgb), .34); box-shadow: 0 12px 30px rgba(0, 0, 0, .38);
  transition: transform .26s, border-color .26s, box-shadow .26s;
}
.quick-card:hover {
  transform: translateY(-5px); border-color: var(--card-main);
  box-shadow: 0 20px 44px rgba(var(--card-rgb), .3), inset 0 0 22px rgba(var(--card-rgb), .1);
}
.qc-emoji { font-size: 28px; line-height: 1; filter: drop-shadow(0 4px 12px rgba(var(--card-rgb), .6)); }
.quick-card b { font-size: 12.5px; font-weight: 600; }
.quick-card small { font-size: 10.5px; color: var(--card-main); }

/* B 站视频 */
.bili-box {
  padding: 20px; margin-bottom: 34px; border-radius: 18px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
}

@media (max-width: 900px) {
  .quick-row { grid-template-columns: repeat(4, minmax(0, 1fr)); }
}
@media (max-width: 480px) {
  .quick-row { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
</style>
