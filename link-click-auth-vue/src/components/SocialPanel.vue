<script setup>
import { ref, watch } from 'vue'
import ChatPanel from './ChatPanel.vue'
import ForumPanel from './ForumPanel.vue'

/**
 * 社交中心（微博式）：一个入口整合「互动态」（论坛信息流）与「私信」（好友聊天）。
 * 参考 Weibo：默认进入互动态刷帖，私信标签上有未读红点。
 */
const props = defineProps({
  show: { type: Boolean, default: false },
  /** 私信未读总数（由 NavBar 轮询提供，用于标签红点） */
  unread: { type: Number, default: 0 },
  /** 打开时默认进入的标签页：feed 互动态（默认）/ chat 私信（好友面板「私聊」入口用） */
  initialTab: { type: String, default: 'feed' }
})
const emit = defineEmits(['close', 'read'])

const tab = ref('feed') // feed 互动态 | chat 私信

watch(() => props.show, (v) => {
  if (v) tab.value = props.initialTab === 'chat' ? 'chat' : 'feed'
})
</script>

<template>
  <transition name="pop">
    <div v-if="show" class="sp-mask" @click.self="emit('close')">
      <div class="sp-panel">
        <button class="sp-close" @click="emit('close')" aria-label="关闭">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>

        <header class="sp-head">
          <h2 class="sp-title">社交中心</h2>
          <nav class="sp-tabs">
            <button class="sp-tab" :class="{ on: tab === 'feed' }" @click="tab = 'feed'">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
                <path d="M8 8.5h8M8 12h5" />
              </svg>
              互动态
            </button>
            <button class="sp-tab" :class="{ on: tab === 'chat' }" @click="tab = 'chat'">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" />
              </svg>
              私信
              <i v-if="unread > 0" class="sp-badge">{{ unread > 99 ? '99+' : unread }}</i>
            </button>
          </nav>
        </header>

        <div class="sp-body">
          <ForumPanel :show="show && tab === 'feed'" v-show="tab === 'feed'" />
          <ChatPanel :show="show && tab === 'chat'" v-show="tab === 'chat'" @read="emit('read')" />
        </div>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.sp-mask {
  position: fixed; inset: 0; z-index: 55;
  display: grid; place-items: center; padding: 20px;
  background: rgba(5, 8, 24, .62);
  backdrop-filter: blur(8px) saturate(140%);
  -webkit-backdrop-filter: blur(8px) saturate(140%);
}
.sp-panel {
  position: relative; width: min(780px, 100%); height: min(640px, 90vh);
  border-radius: 20px; padding: 20px 22px;
  display: flex; flex-direction: column;
  background: linear-gradient(160deg, rgba(20, 24, 56, .94), rgba(11, 13, 38, .96));
  border: 1px solid rgba(255, 255, 255, .16);
  box-shadow: 0 30px 80px rgba(0, 0, 0, .55), 0 0 0 1px rgba(45, 226, 230, .12);
  animation: spPop .3s ease;
}
.sp-close {
  position: absolute; top: 14px; right: 14px;
  width: 36px; height: 36px; border-radius: 50%; cursor: pointer;
  display: grid; place-items: center; color: #eef2ff;
  background: rgba(10, 14, 39, .5); border: 1px solid rgba(255, 255, 255, .2); transition: .25s;
}
.sp-close svg { width: 18px; height: 18px; }
.sp-close:hover { color: #fff; border-color: var(--magenta); }

.sp-head { display: flex; align-items: center; gap: 16px; margin-bottom: 14px; padding-right: 44px; }
.sp-title {
  font-size: 20px; font-weight: 600; margin: 0;
  background: linear-gradient(90deg, var(--cyan), #fff 45%, var(--magenta));
  -webkit-background-clip: text; background-clip: text; color: transparent;
  white-space: nowrap;
}
.sp-tabs { display: flex; gap: 8px; }
.sp-tab {
  position: relative;
  display: inline-flex; align-items: center; gap: 7px;
  border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit;
  font-size: 13.5px; color: #cdd6f4; background: rgba(255, 255, 255, .05);
  padding: 8px 18px; border-radius: 999px; transition: .22s;
}
.sp-tab svg { width: 16px; height: 16px; }
.sp-tab:hover { color: #fff; border-color: var(--cyan); }
.sp-tab.on {
  color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 16px rgba(138, 92, 255, .35);
}
.sp-badge {
  min-width: 18px; height: 18px; padding: 0 5px; border-radius: 999px; font-style: normal;
  display: grid; place-items: center; font-size: 10.5px; font-weight: 700;
  background: #fff; color: #ff2d78;
  box-shadow: 0 2px 8px rgba(255, 45, 120, .6);
}

.sp-body { flex: 1; min-height: 0; }

@keyframes spPop { from { opacity: 0; transform: translateY(14px) scale(.97); } to { opacity: 1; transform: none; } }
.pop-enter-active, .pop-leave-active { transition: opacity .26s ease; }
.pop-enter-from, .pop-leave-to { opacity: 0; }
</style>
