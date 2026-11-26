<script setup>
import { onMounted, onBeforeUnmount } from 'vue'

defineProps({
  title: { type: String, default: '小游戏' },
  icon: { type: String, default: '🎮' },
  subtitle: { type: String, default: '' }
})
const emit = defineEmits(['close'])

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}
onMounted(() => window.addEventListener('keydown', onKey))
onBeforeUnmount(() => window.removeEventListener('keydown', onKey))
</script>

<template>
  <div class="gf-mask" @click.self="emit('close')">
    <div class="gf-panel">
      <button class="gf-close" @click="emit('close')" aria-label="关闭">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <path d="M6 6l12 12M18 6L6 18" />
        </svg>
      </button>

      <header class="gf-head">
        <span class="gf-icon">{{ icon }}</span>
        <div class="gf-hd-text">
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
  background: rgba(5, 8, 24, .74); backdrop-filter: blur(9px) saturate(140%);
}
.gf-panel {
  position: relative; width: min(820px, 100%); max-height: 94vh; overflow-y: auto;
  border-radius: 22px; padding: 22px 26px 20px;
  background: linear-gradient(160deg, rgba(20, 24, 56, .97), rgba(11, 13, 38, .98));
  border: 1px solid rgba(255, 255, 255, .16);
  box-shadow: 0 30px 80px rgba(0, 0, 0, .62), 0 0 0 1px rgba(45, 226, 230, .12);
  animation: gfIn .24s cubic-bezier(.2, .8, .2, 1) both;
}
@keyframes gfIn { from { opacity: 0; transform: translateY(18px) scale(.97) } to { opacity: 1; transform: none } }
.gf-close {
  position: absolute; top: 14px; right: 14px; z-index: 3;
  width: 34px; height: 34px; border-radius: 50%; cursor: pointer;
  display: grid; place-items: center; color: #eef2ff;
  background: rgba(10, 14, 39, .55); border: 1px solid rgba(255, 255, 255, .2); transition: .22s;
}
.gf-close svg { width: 17px; height: 17px; }
.gf-close:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 14px rgba(255, 72, 196, .45); }

.gf-head { display: flex; align-items: center; gap: 14px; margin-bottom: 18px; padding-right: 40px; }
.gf-icon {
  flex-shrink: 0; width: 50px; height: 50px; border-radius: 14px; display: grid; place-items: center; font-size: 26px;
  background: linear-gradient(160deg, rgba(45, 226, 230, .18), rgba(138, 92, 255, .2));
  border: 1px solid rgba(255, 255, 255, .16);
}
.gf-hd-text { min-width: 0; }
.gf-hd-text h2 {
  font-size: 20px; font-weight: 700; letter-spacing: 1px;
  background: linear-gradient(135deg, var(--cyan), var(--magenta));
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.gf-hd-text p { font-size: 12.5px; color: #9fb0d8; margin-top: 4px; }
.gf-esc { margin-left: auto; flex-shrink: 0; font-size: 11.5px; color: #7e8ab0; }

.gf-body { display: flex; justify-content: center; }
.gf-foot { margin-top: 18px; display: flex; justify-content: center; }
.gf-back {
  border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .06);
  color: #cdd6f4; font-family: inherit; font-size: 13px; padding: 9px 22px; border-radius: 11px;
  cursor: pointer; transition: .22s;
}
.gf-back:hover { color: #fff; border-color: var(--cyan); }

@media (max-width: 640px) {
  .gf-panel { padding: 18px 14px 16px; }
  .gf-esc { display: none; }
}
</style>
