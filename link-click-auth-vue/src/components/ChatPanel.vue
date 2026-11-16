<script setup>
import { ref, watch, nextTick, onBeforeUnmount, inject } from 'vue'
import { fetchConversations, fetchHistory, sendMessage, markRead } from '../api/chat'

/**
 * 好友私信内容块（嵌入社交中心 SocialPanel 的「私信」标签页）
 * show 为 true 时加载数据并开启轮询；遮罩/标题/关闭按钮由父级负责。
 */
const props = defineProps({
  show: { type: Boolean, default: false }
})
const emit = defineEmits(['read'])

const notify = inject('appNotify')
const me = inject('appUser', null)

/* ===== 左侧：好友会话列表 ===== */
const conversations = ref([])
const loadingList = ref(false)
const listErr = ref('')
const activeId = ref(null) // 当前聊天的好友 friendId

/* ===== 右侧：聊天窗口 ===== */
const messages = ref([]) // 时间正序
const loadingMsg = ref(false)
const msgErr = ref('')
const draft = ref('')
const sending = ref(false)
const canLoadMore = ref(false)
const bodyRef = ref(null)

let pollTimer = null
let pollTimer2 = null

function fmtTime(t) {
  return (t || '').replace('T', ' ').slice(5, 16) // MM-DD HH:mm
}

function initial(name) {
  return (name || '?').slice(0, 1).toUpperCase()
}

async function loadList() {
  loadingList.value = true
  listErr.value = ''
  try {
    const res = await fetchConversations()
    conversations.value = res.data || []
  } catch (e) {
    listErr.value = e.message || '加载失败'
  } finally {
    loadingList.value = false
  }
}

async function openChat(c) {
  activeId.value = c.friendId
  msgErr.value = ''
  await loadHistory()
  startMsgPoll()
}

async function loadHistory() {
  if (!activeId.value) return
  loadingMsg.value = true
  try {
    const res = await fetchHistory(activeId.value)
    messages.value = res.data || []
    canLoadMore.value = messages.value.length >= 50
    await nextTick(scrollBottom)
    // 拉历史时后端已自动标记已读，清掉列表里该好友的红点
    const c = conversations.value.find((x) => x.friendId === activeId.value)
    if (c) c.unread = 0
    emit('read')
  } catch (e) {
    msgErr.value = e.message || '加载失败'
  } finally {
    loadingMsg.value = false
  }
}

/** 往上翻更早的聊天记录 */
async function loadMore() {
  if (!activeId.value || !messages.value.length) return
  const first = messages.value[0]
  try {
    const res = await fetchHistory(activeId.value, first.id)
    const older = res.data || []
    canLoadMore.value = older.length >= 50
    if (older.length) {
      const el = bodyRef.value
      const before = el ? el.scrollHeight : 0
      messages.value = older.concat(messages.value)
      await nextTick(() => {
        if (el) el.scrollTop = el.scrollHeight - before // 保持视口不跳
      })
    }
  } catch (_) { /* 静默失败 */ }
}

async function send() {
  const text = draft.value.trim()
  if (!text || !activeId.value || sending.value) return
  sending.value = true
  try {
    const res = await sendMessage(activeId.value, text)
    messages.value.push(res.data)
    draft.value = ''
    const c = conversations.value.find((x) => x.friendId === activeId.value)
    if (c) {
      c.lastContent = text
      c.lastTime = res.data.createTime
    }
    await nextTick(scrollBottom)
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '发送失败'))
  } finally {
    sending.value = false
  }
}

/** 聊天窗口轮询：刷新当前会话新消息（3 秒） */
function startMsgPoll() {
  stopMsgPoll()
  pollTimer = setInterval(async () => {
    if (!activeId.value) return
    try {
      const res = await fetchHistory(activeId.value)
      const fresh = res.data || []
      const lastId = messages.value.length ? messages.value[messages.value.length - 1].id : 0
      const added = fresh.filter((m) => m.id > lastId)
      if (added.length) {
        const nearBottom = isNearBottom()
        messages.value = messages.value.concat(added)
        if (nearBottom) await nextTick(scrollBottom)
        const c = conversations.value.find((x) => x.friendId === activeId.value)
        if (c) { c.lastContent = added[added.length - 1].content; c.lastTime = added[added.length - 1].createTime }
      }
    } catch (_) { /* 后端未启动时静默 */ }
  }, 3000)
}
function stopMsgPoll() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
}

/** 私信标签页激活期间轮询会话列表，让列表/红点保持新鲜（6 秒） */
function startListPoll() {
  stopListPoll()
  pollTimer2 = setInterval(() => {
    if (props.show) loadList()
  }, 6000)
}
function stopListPoll() {
  if (pollTimer2) { clearInterval(pollTimer2); pollTimer2 = null }
}

function isNearBottom() {
  const el = bodyRef.value
  if (!el) return true
  return el.scrollHeight - el.scrollTop - el.clientHeight < 80
}

function scrollBottom() {
  const el = bodyRef.value
  if (el) el.scrollTop = el.scrollHeight
}

watch(() => props.show, (v) => {
  if (v) {
    loadList()
    startListPoll()
  } else {
    activeId.value = null
    messages.value = []
    stopMsgPoll()
    stopListPoll()
  }
})

onBeforeUnmount(() => { stopMsgPoll(); stopListPoll() })

function goBack() {
  activeId.value = null
  messages.value = []
  stopMsgPoll()
  loadList()
}
</script>

<template>
  <div class="cm-panel">
    <div class="cm-layout">
      <!-- 左侧会话列表 -->
      <aside class="cm-side">
        <div v-if="loadingList && !conversations.length" class="cm-state">载入中…</div>
        <div v-else-if="listErr" class="cm-state err">{{ listErr }}</div>
        <div v-else-if="!conversations.length" class="cm-state">
          还没有好友。去社区「我的好友」里添加一个，就能开始私信啦。
        </div>
        <ul v-else class="cv-list">
          <li
            v-for="c in conversations"
            :key="c.friendId"
            class="cv-item"
            :class="{ on: activeId === c.friendId }"
            @click="openChat(c)"
          >
            <span class="cv-avatar">
              <img v-if="c.avatar" :src="c.avatar" alt="" />
              <i v-else>{{ initial(c.nickname || c.username) }}</i>
            </span>
            <span class="cv-main">
              <span class="cv-name">@{{ c.username }}</span>
              <span class="cv-last">{{ c.lastContent || '打个招呼吧～' }}</span>
            </span>
            <span class="cv-right">
              <span v-if="c.lastTime" class="cv-time">{{ fmtTime(c.lastTime) }}</span>
              <span v-if="c.unread > 0" class="cv-badge">{{ c.unread > 99 ? '99+' : c.unread }}</span>
            </span>
          </li>
        </ul>
      </aside>

      <!-- 右侧聊天窗口 -->
      <section class="cm-chat">
        <template v-if="activeId">
          <div class="cm-chat-head">
            <button class="cm-back" @click="goBack" title="返回列表">←</button>
            <span class="cm-chat-name">@{{ (conversations.find((x) => x.friendId === activeId) || {}).username }}</span>
            <span class="cm-online">私信中</span>
          </div>

          <div class="cm-body" ref="bodyRef">
            <button v-if="canLoadMore" class="cm-more" @click="loadMore">查看更早的消息 ↑</button>
            <div v-if="loadingMsg && !messages.length" class="cm-state">载入中…</div>
            <div v-else-if="msgErr" class="cm-state err">{{ msgErr }}</div>
            <div v-else-if="!messages.length" class="cm-state">还没有聊天记录，说句「你好」打破沉默吧。</div>
            <template v-else>
              <div
                v-for="m in messages"
                :key="m.id"
                class="msg"
                :class="{ mine: me && m.senderId === me.id }"
              >
                <span class="msg-avatar">
                  <img v-if="m.avatar" :src="m.avatar" alt="" />
                  <i v-else>{{ initial(m.nickname || m.username) }}</i>
                </span>
                <div class="msg-bubble">
                  <div class="msg-text">{{ m.content }}</div>
                  <div class="msg-time">{{ fmtTime(m.createTime) }}</div>
                </div>
              </div>
            </template>
          </div>

          <form class="cm-input" @submit.prevent="send">
            <input v-model="draft" type="text" maxlength="1000" placeholder="输入消息，回车发送…" />
            <button type="submit" :disabled="sending || !draft.trim()">发送</button>
          </form>
        </template>
        <div v-else class="cm-placeholder">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" />
          </svg>
          <p>选择左侧一位好友开始私信</p>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.cm-panel { height: 100%; min-height: 0; display: flex; flex-direction: column; }
.cm-layout { flex: 1; min-height: 0; display: grid; grid-template-columns: 250px 1fr; gap: 14px; }

/* 左侧会话列表 */
.cm-side { overflow-y: auto; border-right: 1px solid rgba(255, 255, 255, .1); padding-right: 10px; }
.cv-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
.cv-item {
  display: flex; align-items: center; gap: 9px; padding: 10px 10px;
  border-radius: 13px; cursor: pointer; transition: .2s;
  background: rgba(255, 255, 255, .04); border: 1px solid rgba(255, 255, 255, .08);
}
.cv-item:hover { background: rgba(45, 226, 230, .08); }
.cv-item.on { background: rgba(45, 226, 230, .14); border-color: var(--cyan); }
.cv-avatar {
  width: 36px; height: 36px; border-radius: 50%; flex-shrink: 0; overflow: hidden;
  display: grid; place-items: center; font-size: 14px; font-weight: 700; font-style: normal; color: #04121f;
  background: linear-gradient(135deg, var(--cyan), var(--purple));
}
.cv-avatar img { width: 100%; height: 100%; object-fit: cover; }
.cv-main { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 3px; }
.cv-name { font-size: 13px; font-weight: 600; color: #eef2ff; }
.cv-last {
  font-size: 11.5px; color: #8b97bd; max-width: 120px;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.cv-right { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; flex-shrink: 0; }
.cv-time { font-size: 10px; color: #7e8ab0; }
.cv-badge {
  min-width: 18px; height: 18px; padding: 0 5px; border-radius: 999px;
  display: grid; place-items: center; font-size: 10.5px; font-weight: 700; color: #fff;
  background: linear-gradient(135deg, #ff48c4, #ff5e9c);
  box-shadow: 0 3px 10px rgba(255, 72, 196, .5);
}

/* 右侧聊天窗口 */
.cm-chat { display: flex; flex-direction: column; min-width: 0; min-height: 0; }
.cm-chat-head {
  display: flex; align-items: center; gap: 10px; padding-bottom: 10px; margin-bottom: 8px;
  border-bottom: 1px solid rgba(255, 255, 255, .1);
}
.cm-back {
  width: 28px; height: 28px; border-radius: 9px; cursor: pointer; flex-shrink: 0;
  border: 1px solid rgba(255, 255, 255, .16); background: transparent; color: #cdd6f4; transition: .2s;
}
.cm-back:hover { color: #fff; border-color: var(--cyan); }
.cm-chat-name { font-size: 14.5px; font-weight: 600; color: #eef2ff; }
.cm-online { font-size: 11px; color: var(--cyan-soft); }

.cm-body { flex: 1; min-height: 0; overflow-y: auto; padding: 6px 4px; display: flex; flex-direction: column; gap: 12px; }
.cm-more {
  align-self: center; border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit;
  font-size: 11.5px; color: #8b97bd; background: transparent; padding: 5px 14px; border-radius: 999px; transition: .2s;
}
.cm-more:hover { color: #fff; border-color: var(--cyan); }

.msg { display: flex; gap: 8px; max-width: 82%; }
.msg.mine { align-self: flex-end; flex-direction: row-reverse; }
.msg-avatar {
  width: 30px; height: 30px; border-radius: 50%; flex-shrink: 0; overflow: hidden;
  display: grid; place-items: center; font-size: 12px; font-weight: 700; font-style: normal; color: #04121f;
  background: linear-gradient(135deg, var(--purple), var(--magenta));
}
.msg-avatar img { width: 100%; height: 100%; object-fit: cover; }
.msg-bubble {
  display: flex; flex-direction: column; gap: 4px; padding: 9px 13px;
  border-radius: 14px; background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .12);
}
.msg.mine .msg-bubble { background: rgba(45, 226, 230, .14); border-color: rgba(45, 226, 230, .35); }
.msg-text { font-size: 13.5px; color: #eef2ff; line-height: 1.55; word-break: break-word; white-space: pre-wrap; }
.msg-time { font-size: 10px; color: #7e8ab0; }

.cm-input { display: flex; gap: 8px; padding-top: 10px; border-top: 1px solid rgba(255, 255, 255, .1); margin-top: 8px; }
.cm-input input {
  flex: 1; padding: 11px 13px; font-family: inherit; font-size: 14px; color: #fff;
  background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .16);
  border-radius: 12px; outline: none; transition: .22s;
}
.cm-input input:focus { border-color: var(--cyan); background: rgba(45, 226, 230, .06); }
.cm-input button {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13.5px; font-weight: 600; color: #04121f;
  padding: 0 20px; border-radius: 12px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
}
.cm-input button:disabled { opacity: .5; cursor: not-allowed; }

.cm-state { font-size: 13px; color: #8b97bd; text-align: center; padding: 24px 10px; line-height: 1.7; }
.cm-state.err { color: #ff8aa8; }

.cm-placeholder {
  flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px;
  color: #5f6b94;
}
.cm-placeholder svg { width: 54px; height: 54px; }
.cm-placeholder p { font-size: 13px; }

@media (max-width: 640px) {
  .cm-layout { grid-template-columns: 1fr; }
  .cm-side { display: none; }
}
</style>
