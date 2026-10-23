<script setup>
import { computed } from 'vue'
import { coverStyle, coverColor, tagAccent, coverIcon, hasCover } from '../utils/archiveStyle'

const props = defineProps({
  archive: { type: Object, required: true },
  author: { type: String, default: '' },
  coverH: { type: Number, default: 142 },
  compact: { type: Boolean, default: false }
})
defineEmits(['open'])

const photoUrl = computed(() => (hasCover(props.archive) ? `/img/archives/${props.archive.id}.png` : ''))
const tagLabel = computed(() => props.archive?.tag || '时光')
const accent = computed(() => tagAccent(props.archive?.tag))
const iconPath = computed(() => coverIcon(props.archive?.tag))
const visPublic = computed(() => props.archive?.visibility === 1)

function excerpt(c, n = 46) {
  c = c ? String(c) : ''
  return c.length > n ? c.slice(0, n) + '…' : c
}
</script>

<template>
  <article class="ac" :class="{ compact }" :style="{ '--accent': accent }" @click="$emit('open', archive)">
    <div class="ac-cover" :style="{ height: coverH + 'px' }">
      <img v-if="photoUrl" class="ac-photo" :src="photoUrl" :alt="archive.title" loading="lazy" />
      <div v-else class="ac-illus" :style="{ background: coverColor(archive?.tag) }">
        <span class="blob b1"></span>
        <span class="blob b2"></span>
        <svg class="ac-icon" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,.92)" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
          <path :d="iconPath" />
        </svg>
        <span class="ac-illus-tag">{{ tagLabel }}</span>
      </div>

      <span class="ac-tag">{{ tagLabel }}</span>
      <span class="ac-vis" :class="{ pri: !visPublic }">{{ visPublic ? '公开' : '私有' }}</span>
      <span class="ac-go">查看 →</span>
    </div>

    <div class="ac-body">
      <h3 class="ac-title">{{ archive.title }}</h3>
      <p class="ac-excerpt" v-if="archive.content && !compact">{{ excerpt(archive.content) }}</p>
      <div class="ac-foot">
        <span class="ac-author" v-if="author">@{{ author }}</span>
        <span class="ac-date">{{ archive.archiveDate || '—' }}</span>
      </div>
    </div>
  </article>
</template>

<style scoped>
.ac {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  cursor: pointer;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14);
  box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
  transition: transform .3s, border-color .3s, box-shadow .3s;
  animation: acIn .45s cubic-bezier(.2, .8, .2, 1) both;
}
.ac::before {
  /* 顶部主题色细条，按标签取色，避免画面单调 */
  content: "";
  position: absolute; top: 0; left: 0; right: 0; height: 3px; z-index: 3;
  background: linear-gradient(90deg, transparent, var(--accent), transparent);
  opacity: .85;
}
.ac:hover {
  transform: translateY(-6px);
  border-color: var(--accent);
  box-shadow: 0 22px 52px color-mix(in srgb, var(--accent) 32%, transparent);
}
@keyframes acIn { from { opacity: 0; transform: translateY(18px) scale(.97); } to { opacity: 1; transform: none; } }

.ac-cover {
  position: relative;
  overflow: hidden;
  background: #0a0e27;
  background-size: cover;
  background-repeat: no-repeat;
  transition: background-size .55s ease;
}
.ac:hover .ac-cover { background-size: 116% 116%; }
.ac-photo {
  position: absolute; inset: 0; width: 100%; height: 100%;
  object-fit: cover; display: block;
  transition: transform .55s ease;
}
.ac:hover .ac-photo { transform: scale(1.06); }

/* 无图时的插画式封面：多层渐变 + 漂浮光斑 + 标签大图标，绝非纯色块 */
.ac-illus { position: absolute; inset: 0; overflow: hidden; }
.ac-illus .blob {
  position: absolute; border-radius: 50%; filter: blur(22px); opacity: .55;
  mix-blend-mode: screen;
}
.ac-illus .b1 { width: 120px; height: 120px; left: -28px; top: -22px; background: rgba(255, 255, 255, .55); }
.ac-illus .b2 { width: 90px; height: 90px; right: -18px; bottom: -20px; background: rgba(10, 14, 39, .5); }
.ac-icon {
  position: absolute; inset: 0; margin: auto; width: 56px; height: 56px;
  opacity: .9; transform: translateY(-6px);
  filter: drop-shadow(0 4px 14px rgba(0, 0, 0, .35));
}
.ac-illus-tag {
  position: absolute; left: 0; right: 0; bottom: 12px; text-align: center;
  font-size: 12px; letter-spacing: 3px; color: rgba(255, 255, 255, .85);
  text-shadow: 0 2px 8px rgba(0, 0, 0, .4);
}

.ac-cover::after {
  content: ""; position: absolute; inset: 0; z-index: 1; pointer-events: none;
  background: radial-gradient(circle at 80% 12%, rgba(255, 255, 255, .18), transparent 55%);
  mix-blend-mode: screen;
}
.ac-tag {
  position: absolute; left: 12px; bottom: 12px; z-index: 2;
  font-size: 11px; padding: 3px 12px; border-radius: 999px;
  background: rgba(10, 14, 39, .55); color: #eef2ff; border: 1px solid rgba(255, 255, 255, .3);
  backdrop-filter: blur(4px);
}
.ac-vis {
  position: absolute; right: 12px; top: 12px; z-index: 2;
  font-size: 10.5px; padding: 3px 10px; border-radius: 999px;
  background: rgba(45, 226, 230, .9); color: #04121f; font-weight: 600;
}
.ac-vis.pri { background: rgba(10, 14, 39, .6); color: #cdd6f4; border: 1px solid rgba(255, 255, 255, .25); }
.ac-go {
  position: absolute; right: 12px; bottom: 12px; z-index: 2;
  font-size: 12px; color: #fff; font-weight: 600; letter-spacing: 1px;
  opacity: 0; transform: translateX(-6px); transition: .28s;
}
.ac:hover .ac-go { opacity: 1; transform: translateX(0); }

.ac-body { padding: 14px 14px 16px; display: flex; flex-direction: column; gap: 7px; }
.ac-title { font-size: 15px; font-weight: 600; color: #eef2ff; line-height: 1.35; }
.ac-excerpt {
  font-size: 12.5px; line-height: 1.6; color: #9fb0d8;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.ac-foot { display: flex; align-items: center; justify-content: space-between; margin-top: 2px; }
.ac-author { font-size: 12px; color: var(--cyan-soft); }
.ac-date { font-size: 12px; color: #7e8ab0; }
</style>
