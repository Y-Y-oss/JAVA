<script setup>
import { ref, computed, inject } from 'vue'
import { coverStyle, visibilityText } from '../utils/archiveStyle'

const props = defineProps({
  archive: { type: Object, default: null },
  loading: { type: Boolean, default: false },
  error: { type: String, default: '' }
})
const emit = defineEmits(['close', 'edit', 'delete'])

// 当前登录用户（App.vue provide 注入），用于判断是否是档案主人
const user = inject('appUser', null)
const confirmDel = ref(false)

const isOwner = computed(() => {
  const u = user && user.value
  return !!(u && props.archive && props.archive.userId === u.id)
})
</script>

<template>
  <transition name="pop">
    <div v-if="archive || loading || error" class="detail-mask" @click.self="emit('close')">
      <div class="detail-panel">
        <button class="detail-close" @click="emit('close')" aria-label="关闭">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>

        <div v-if="loading" class="detail-state">载入中…</div>
        <div v-else-if="error" class="detail-state err">{{ error }}</div>

        <template v-else-if="archive">
          <div class="detail-cover" :style="coverStyle(archive)">
            <span class="detail-tag">{{ archive.tag || '时光' }}</span>
            <span class="detail-vis">{{ visibilityText(archive.visibility) }}</span>
          </div>
          <div class="detail-body">
            <h2 class="detail-title">{{ archive.title }}</h2>
            <div class="detail-meta">
              <span><i>记录日期</i>{{ archive.archiveDate || '—' }}</span>
              <span><i>创建于</i>{{ archive.createTime || '—' }}</span>
              <span v-if="archive.updateTime"><i>更新于</i>{{ archive.updateTime }}</span>
              <span v-if="archive.username"><i>作者</i>{{ archive.username }}</span>
            </div>
            <div class="detail-content">{{ archive.content || '（这段时光还没有写下文字）' }}</div>

            <div class="detail-actions" v-if="isOwner">
              <button class="da edit" @click="emit('edit', archive)">编辑</button>
              <template v-if="!confirmDel">
                <button class="da del" @click="confirmDel = true">删除</button>
              </template>
              <template v-else>
                <span class="da-warn">删除后不可恢复，确定吗？</span>
                <button class="da cancel" @click="confirmDel = false">取消</button>
                <button class="da del solid" @click="emit('delete', archive)">确认删除</button>
              </template>
            </div>
          </div>
        </template>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.detail-mask {
  position: fixed; inset: 0; z-index: 50;
  display: grid; place-items: center;
  padding: 20px;
  background: rgba(5, 8, 24, .62);
  backdrop-filter: blur(8px) saturate(140%);
  -webkit-backdrop-filter: blur(8px) saturate(140%);
}
.detail-panel {
  position: relative;
  width: min(560px, 100%);
  max-height: 86vh; overflow-y: auto;
  border-radius: 20px;
  background: linear-gradient(160deg, rgba(20, 24, 56, .92), rgba(11, 13, 38, .95));
  border: 1px solid rgba(255, 255, 255, .16);
  box-shadow: 0 30px 80px rgba(0, 0, 0, .55), 0 0 0 1px rgba(45, 226, 230, .12);
  animation: pop .3s ease;
}
.detail-close {
  position: absolute; top: 14px; right: 14px; z-index: 2;
  width: 36px; height: 36px; border-radius: 50%; cursor: pointer;
  display: grid; place-items: center; color: #eef2ff;
  background: rgba(10, 14, 39, .5); border: 1px solid rgba(255, 255, 255, .2);
  transition: .25s;
}
.detail-close svg { width: 18px; height: 18px; }
.detail-close:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 14px rgba(255, 72, 196, .45); }

.detail-state { padding: 70px 24px; text-align: center; color: #9fb0d8; font-size: 14px; }
.detail-state.err { color: #ff8aa8; }

.detail-cover {
  position: relative; height: 150px; border-radius: 20px 20px 0 0;
  display: flex; align-items: flex-end; gap: 10px; padding: 16px;
  background-size: cover; background-repeat: no-repeat; background-color: #0a0e27;
}
.detail-tag {
  position: relative; z-index: 2;
  font-size: 12px; padding: 4px 14px; border-radius: 999px;
  background: rgba(10, 14, 39, .55); color: #eef2ff;
  border: 1px solid rgba(255, 255, 255, .3); backdrop-filter: blur(4px);
}
.detail-vis {
  position: relative; z-index: 2; margin-left: auto; font-size: 11px; padding: 4px 12px; border-radius: 999px;
  background: rgba(10, 14, 39, .55); color: #eef2ff;
  border: 1px solid rgba(255, 255, 255, .3); backdrop-filter: blur(4px);
}
.detail-body { padding: 22px 24px 26px; }
.detail-title { font-size: 21px; font-weight: 600; color: #eef2ff; margin-bottom: 16px; }
.detail-meta { display: flex; flex-wrap: wrap; gap: 8px 22px; margin-bottom: 18px; }
.detail-meta span {
  display: flex; flex-direction: column; gap: 3px;
  font-size: 13.5px; color: #cdd6f4;
}
.detail-meta i {
  font-style: normal; font-size: 10.5px; letter-spacing: 1px;
  color: #7e8ab0; text-transform: uppercase;
}
.detail-content {
  font-size: 14.5px; line-height: 1.75; color: #dfe5fb;
  white-space: pre-wrap; word-break: break-word;
  padding: 16px; border-radius: 14px;
  background: rgba(255, 255, 255, .05);
  border: 1px solid rgba(255, 255, 255, .1);
}

.detail-actions {
  display: flex; align-items: center; gap: 10px; margin-top: 20px;
  padding-top: 18px; border-top: 1px solid rgba(255, 255, 255, .1);
}
.da {
  border: 1px solid rgba(255, 255, 255, .18); cursor: pointer; font-family: inherit;
  background: transparent; color: #cdd6f4; font-size: 13px; padding: 9px 18px; border-radius: 11px; transition: .22s;
}
.da:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .28); }
.da.del:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 12px rgba(255, 72, 196, .4); }
.da.del.solid { background: linear-gradient(135deg, #ff48c4, #8a5cff); color: #fff; border-color: transparent; }
.da.cancel { color: #9fb0d8; }
.da-warn { font-size: 12.5px; color: #ff8aa8; margin-right: auto; }

@keyframes pop {
  from { opacity: 0; transform: translateY(14px) scale(.97); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}
.pop-enter-active, .pop-leave-active { transition: opacity .26s ease; }
.pop-enter-from, .pop-leave-to { opacity: 0; }
</style>
