<script setup>
import { computed } from 'vue'
import { coverStyle, coverColor, tagAccent, coverIcon, hasCover, coverUrl } from '../utils/archiveStyle'

const props = defineProps({
  archive: { type: Object, required: true },
  author: { type: String, default: '' },
  coverH: { type: Number, default: 142 },
  compact: { type: Boolean, default: false },
  // 社区模式：卡片底部显示 点赞/收藏/评论 互动栏（首页私有档案不显示）
  interactive: { type: Boolean, default: false },
  // 作者的好友状态：self 自己（不显示）/ guest 未登录 / friends 已是好友 / incoming 待我验证 / sent 已申请 / none 未加
  friendState: { type: String, default: '' }
})
defineEmits(['open', 'like', 'fav', 'add-friend'])

const friendBtnText = computed(() => {
  switch (props.friendState) {
    case 'friends': return '✓ 好友'
    case 'incoming': return '通过验证'
    case 'sent': return '已申请'
    case 'none': return '＋ 好友'
    default: return '' // self / guest 不显示
  }
})

const photoUrl = computed(() => (hasCover(props.archive) ? coverUrl(props.archive) : ''))
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
        <button
          v-if="friendBtnText && friendState !== 'friends'"
          class="ac-friend"
          :class="{ pending: friendState === 'sent', verify: friendState === 'incoming' }"
          :disabled="friendState === 'sent'"
          :title="friendState === 'incoming' ? '对方申请加你为好友，点击去验证' : '申请添加对方为好友（需对方验证）'"
          @click.stop="$emit('add-friend', archive)"
        >{{ friendBtnText }}</button>
        <span v-else-if="friendState === 'friends'" class="ac-friend ok" @click.stop>✓ 好友</span>
        <span class="ac-date">{{ archive.archiveDate || '—' }}</span>
      </div>

      <!-- 社区互动栏：点赞 / 收藏 / 评论数（点击事件不冒泡，避免触发卡片打开详情） -->
      <div v-if="interactive" class="ac-social" @click.stop>
        <button class="acx like" :class="{ on: archive.liked }" @click="$emit('like', archive)" :title="archive.liked ? '取消点赞' : '点赞'">
          <svg viewBox="0 0 24 24" :fill="archive.liked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8z" />
          </svg>
          <span>{{ archive.likeCount || 0 }}</span>
        </button>
        <button class="acx fav" :class="{ on: archive.favorited }" @click="$emit('fav', archive)" :title="archive.favorited ? '取消收藏' : '收藏'">
          <svg viewBox="0 0 24 24" :fill="archive.favorited ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 2l3 6.5 7 .8-5.2 4.7 1.5 6.9L12 17.3 5.7 21l1.5-6.9L2 9.3l7-.8z" />
          </svg>
          <span>{{ archive.favoriteCount || 0 }}</span>
        </button>
        <button class="acx cmt" @click="$emit('open', archive)" title="查看评论">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          <span>{{ archive.commentCount || 0 }}</span>
        </button>
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

/* 作者行「加好友」按钮：纯文字 + 状态颜色区分 */
.ac-friend {
  margin-left: auto;
  border: 0; cursor: pointer; font-family: inherit; font-size: 12px;
  color: #7af5f7; background: transparent; padding: 3px 6px; transition: .2s;
}
.ac-friend:hover:not(:disabled) { color: #fff; }
.ac-friend.pending { color: #8b97bd; cursor: default; }
.ac-friend.verify { color: #ffd166; }
.ac-friend.ok { color: #7ee8b0; cursor: default; }

/* 社区互动栏 */
.ac-social { display: flex; align-items: center; gap: 6px; margin-top: 4px; padding-top: 9px; border-top: 1px solid rgba(255, 255, 255, .09); }
.acx {
  display: inline-flex; align-items: center; gap: 5px;
  border: 0; cursor: pointer; font-family: inherit; font-size: 12px; color: #8b97bd;
  background: transparent; padding: 4px 8px; border-radius: 9px; transition: .2s;
}
.acx svg { width: 15px; height: 15px; }
.acx:hover { color: #fff; background: rgba(255, 255, 255, .09); }
.acx.like.on { color: #ff5e9c; }
.acx.like.on:hover { background: rgba(255, 94, 156, .16); }
.acx.fav.on { color: #ffd166; }
.acx.fav.on:hover { background: rgba(255, 209, 102, .16); }
.acx.cmt:hover { color: var(--cyan-soft); }
</style>
