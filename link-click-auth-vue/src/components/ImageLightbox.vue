<script setup>
import { ref, watch, onBeforeUnmount } from 'vue'

/**
 * 通用图片查看器（灯箱）：
 * 全屏黑底 + 完整显示原图（object-fit: contain，不裁剪），点任意处 / ESC / 关闭按钮退出。
 */
const props = defineProps({
  show: { type: Boolean, default: false },
  src: { type: String, default: '' },
  alt: { type: String, default: '' }
})
const emit = defineEmits(['close'])

const loaded = ref(false)

watch(() => props.src, () => { loaded.value = false })

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}

watch(() => props.show, (v) => {
  if (v) window.addEventListener('keydown', onKey)
  else window.removeEventListener('keydown', onKey)
})

onBeforeUnmount(() => window.removeEventListener('keydown', onKey))
</script>

<template>
  <transition name="lb">
    <div v-if="show && src" class="lb-mask" @click="emit('close')">
      <button class="lb-close" aria-label="关闭" @click.stop="emit('close')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <path d="M6 6l12 12M18 6L6 18" />
        </svg>
      </button>
      <span v-if="!loaded" class="lb-loading">图片载入中…</span>
      <img
        v-show="loaded"
        class="lb-img"
        :src="src"
        :alt="alt"
        @load="loaded = true"
        @error="loaded = true"
      />
      <span v-if="loaded" class="lb-hint">{{ alt }} · 点击任意处或按 ESC 关闭</span>
    </div>
  </transition>
</template>

<style scoped>
.lb-mask {
  position: fixed; inset: 0; z-index: 80;
  display: flex; align-items: center; justify-content: center;
  background: rgba(2, 4, 14, .9);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  cursor: zoom-out;
  padding: 30px;
}
.lb-img {
  max-width: min(1100px, 94vw);
  max-height: 88vh;
  object-fit: contain;          /* 完整显示原图，不裁剪 */
  border-radius: 10px;
  box-shadow: 0 30px 90px rgba(0, 0, 0, .8), 0 0 0 1px rgba(255, 255, 255, .14);
  animation: lbIn .28s ease;
}
.lb-close {
  position: absolute; top: 18px; right: 18px; z-index: 2;
  width: 40px; height: 40px; border-radius: 50%; cursor: pointer;
  display: grid; place-items: center; color: #eef2ff;
  background: rgba(10, 14, 39, .6); border: 1px solid rgba(255, 255, 255, .25); transition: .25s;
}
.lb-close svg { width: 20px; height: 20px; }
.lb-close:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 14px rgba(255, 72, 196, .45); }
.lb-loading {
  position: absolute; font-size: 13px; color: #9fb0d8; letter-spacing: 1px;
}
.lb-hint {
  position: absolute; bottom: 18px; left: 50%; transform: translateX(-50%);
  font-size: 11.5px; color: rgba(238, 242, 255, .55); letter-spacing: 1px;
  white-space: nowrap;
}
@keyframes lbIn { from { opacity: 0; transform: scale(.96); } to { opacity: 1; transform: none; } }
.lb-enter-active, .lb-leave-active { transition: opacity .22s ease; }
.lb-enter-from, .lb-leave-to { opacity: 0; }
</style>
