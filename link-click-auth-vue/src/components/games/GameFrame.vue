<script setup>
import { computed, onMounted, onBeforeUnmount } from 'vue'
import GameAmbient from './GameAmbient.vue'
import { getGameTheme, themeVars } from '../../utils/gameThemes'

const props = defineProps({
  title: { type: String, default: '小游戏' },
  icon: { type: String, default: '🎮' },
  subtitle: { type: String, default: '' },
  gameKey: { type: String, default: 'maze' }
})
const emit = defineEmits(['close'])

const theme = computed(() => getGameTheme(props.gameKey))
const vars = computed(() => themeVars(theme.value))

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}
onMounted(() => window.addEventListener('keydown', onKey))
onBeforeUnmount(() => window.removeEventListener('keydown', onKey))
</script>

<template>
  <div class="gf-mask" :style="vars" @click.self="emit('close')">
    <div class="gf-panel" :class="'gf-' + gameKey" :style="{ background: theme.bg }">
      <!-- 每款游戏专属动态氛围层 -->
      <GameAmbient :theme="theme.ambient" />

      <button class="gf-close" @click="emit('close')" aria-label="关闭">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <path d="M6 6l12 12M18 6L6 18" />
        </svg>
      </button>

      <header class="gf-head">
        <span class="gf-icon">{{ icon }}</span>
        <div class="gf-hd-text">
          <div class="gf-vibe">{{ theme.vibe }}</div>
          <h2>{{ title }}</h2>
          <p v-if="subtitle">{{ subtitle }}</p>
        </div>
        <span class="gf-esc">ESC 返回大厅</span>
      </header>

      <div class="gf-body">
        <slot />
      </div>

      <footer class="gf-foot">
        <button class="gf-back" @click="emit('close')">← 返回游戏大厅</button>
      </footer>
    </div>
  </div>
</template>

<style scoped>
.gf-mask {
  position: fixed; inset: 0; z-index: 80;
  display: flex; align-items: center; justify-content: center; padding: 18px;
  background: rgba(4, 6, 20, .78); backdrop-filter: blur(9px) saturate(140%);
}
.gf-panel {
  position: relative; width: min(var(--panel-w, 820px), 100%); max-height: 94vh; overflow-y: auto;
  border-radius: 22px; padding: 22px 26px 20px;
  border: 1px solid rgba(var(--game-rgb), .38);
  box-shadow:
    0 30px 80px rgba(0, 0, 0, .62),
    0 0 0 1px rgba(var(--game-rgb), .16),
    0 0 46px rgba(var(--game-rgb), .18),
    inset 0 1px 0 rgba(255, 255, 255, .09);
  animation: gfIn .34s cubic-bezier(.2, .8, .2, 1) both;
  isolation: isolate;
}
.gf-panel::before {
  content: ''; position: absolute; left: 0; right: 0; top: 0; height: 3px; z-index: 3;
  background: linear-gradient(90deg, transparent, var(--game-main), var(--game-accent), var(--game-main), transparent);
  box-shadow: 0 0 16px rgba(var(--game-rgb), .8);
}
.gf-head, .gf-body, .gf-foot { position: relative; z-index: 2; }

/* 每款游戏的入场方式也不同 */
.gf-maze { --panel-w: 820px; animation-name: gfZoom; }
.gf-breakout { --panel-w: 780px; animation-name: gfSlam; }
.gf-memory { --panel-w: 780px; animation-name: gfFlip; }
.gf-2048 { --panel-w: 760px; animation-name: gfRise; }
.gf-mines { --panel-w: 780px; animation-name: gfGlitch; }
.gf-slide { --panel-w: 720px; animation-name: gfSlideIn; }
.gf-snake { --panel-w: 760px; animation-name: gfWiggle; }
.gf-gomoku { --panel-w: 960px; animation-name: gfInk; }

@keyframes gfIn { from { opacity: 0; transform: translateY(18px) scale(.97) } to { opacity: 1; transform: none } }
@keyframes gfZoom { from { opacity: 0; transform: scale(.82); filter: blur(8px) } to { opacity: 1; transform: none; filter: none } }
@keyframes gfSlam { 0% { opacity: 0; transform: translateY(-70px) scale(1.06) } 70% { opacity: 1; transform: translateY(8px) scale(.985) } 100% { transform: none } }
@keyframes gfFlip { from { opacity: 0; transform: perspective(900px) rotateY(-38deg) scale(.94) } to { opacity: 1; transform: none } }
@keyframes gfRise { from { opacity: 0; transform: translateY(60px) scale(.96) } to { opacity: 1; transform: none } }
@keyframes gfGlitch {
  0% { opacity: 0; transform: translateX(-16px) skewX(6deg) } 30% { opacity: 1; transform: translateX(10px) skewX(-4deg) }
  60% { transform: translateX(-5px) skewX(2deg) } 100% { transform: none }
}
@keyframes gfSlideIn { from { opacity: 0; transform: translateX(-90px) rotate(-2deg) } to { opacity: 1; transform: none } }
@keyframes gfWiggle {
  0% { opacity: 0; transform: translateY(26px) scale(.95) rotate(-2deg) }
  60% { opacity: 1; transform: rotate(1.5deg) } 100% { transform: none }
}
@keyframes gfInk { from { opacity: 0; transform: scale(.7) rotate(-5deg); filter: blur(6px) } to { opacity: 1; transform: none; filter: none } }

.gf-close {
  position: absolute; top: 14px; right: 14px; z-index: 5;
  width: 34px; height: 34px; border-radius: 50%; cursor: pointer;
  display: grid; place-items: center; color: #eef2ff;
  background: rgba(8, 12, 28, .58); border: 1px solid rgba(255, 255, 255, .2); transition: .22s;
}
.gf-close svg { width: 17px; height: 17px; }
.gf-close:hover {
  color: var(--game-accent); border-color: var(--game-main);
  box-shadow: 0 0 16px rgba(var(--game-rgb), .65); transform: rotate(90deg);
}

.gf-head { display: flex; align-items: center; gap: 14px; margin-bottom: 18px; padding-right: 40px; }
.gf-icon {
  flex-shrink: 0; width: 50px; height: 50px; border-radius: 14px; display: grid; place-items: center; font-size: 26px;
  background: linear-gradient(160deg, rgba(var(--game-rgb), .28), rgba(var(--game-rgb), .08));
  border: 1px solid rgba(var(--game-rgb), .5);
  box-shadow: 0 0 22px rgba(var(--game-rgb), .28), inset 0 1px 0 rgba(255, 255, 255, .2);
  animation: iconBreathe 3.2s ease-in-out infinite;
}
@keyframes iconBreathe { 0%, 100% { box-shadow: 0 0 16px rgba(var(--game-rgb), .22) } 50% { box-shadow: 0 0 30px rgba(var(--game-rgb), .55) } }
.gf-hd-text { min-width: 0; }
.gf-vibe {
  display: inline-block; font-size: 10px; letter-spacing: 2px; color: var(--game-accent);
  padding: 2px 8px; border-radius: 999px; margin-bottom: 3px;
  border: 1px solid rgba(var(--game-rgb), .4); background: rgba(var(--game-rgb), .1);
}
.gf-hd-text h2 {
  font-size: 20px; font-weight: 700; letter-spacing: 1px;
  background: linear-gradient(135deg, var(--game-main), var(--game-accent) 55%, var(--game-second));
  -webkit-background-clip: text; background-clip: text; color: transparent;
  filter: drop-shadow(0 0 12px rgba(var(--game-rgb), .35));
}
.gf-hd-text p { font-size: 12.5px; color: #9fb0d8; margin-top: 4px; }
.gf-esc { margin-left: auto; flex-shrink: 0; font-size: 11.5px; color: #7e8ab0; }

.gf-body { display: flex; justify-content: center; }
.gf-foot { margin-top: 18px; display: flex; justify-content: center; }
.gf-back {
  border: 1px solid rgba(var(--game-rgb), .32); background: rgba(var(--game-rgb), .08);
  color: var(--game-accent); font-family: inherit; font-size: 13px; padding: 9px 22px; border-radius: 11px;
  cursor: pointer; transition: .22s;
}
.gf-back:hover { color: var(--game-ink); background: var(--game-main); border-color: transparent; box-shadow: 0 0 18px rgba(var(--game-rgb), .5); }

@media (max-width: 640px) {
  .gf-panel { padding: 18px 14px 16px; }
  .gf-esc { display: none; }
}
</style>
