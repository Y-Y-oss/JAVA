<script setup>
import { ref, watch, inject } from 'vue'
import { applyFriend, acceptFriend, rejectFriend, fetchFriends, fetchFriendRequests, fetchSentRequests, removeFriend } from '../api/friends'

const props = defineProps({
  show: { type: Boolean, default: false }
})
const emit = defineEmits(['close'])

const notify = inject('appNotify')

const tab = ref('list') // list | add | requests
const friends = ref([])
const requests = ref([]) // 收到的待验证
const sent = ref([]) // 我发出的待验证
const loading = ref(false)
const addName = ref('')
const adding = ref(false)
const err = ref('')

async function loadAll() {
  loading.value = true
  err.value = ''
  try {
    const [f, r, s] = await Promise.all([fetchFriends(), fetchFriendRequests(), fetchSentRequests()])
    friends.value = f.data || []
    requests.value = r.data || []
    sent.value = s.data || []
  } catch (e) {
    err.value = e.message || '加载失败'
  } finally {
    loading.value = false
  }
}

// 打开面板时拉取数据
watch(() => props.show, (v) => {
  if (v) loadAll()
})

async function submitAdd() {
  const name = addName.value.trim()
  if (!name) return
  adding.value = true
  err.value = ''
  try {
    const res = await applyFriend(name)
    if (notify) notify('✓ ' + (res.message || '申请已发送'))
    addName.value = ''
    await loadAll()
    tab.value = 'list'
  } catch (e) {
    err.value = e.message || '申请失败'
  } finally {
    adding.value = false
  }
}

async function doAccept(r) {
  try {
    const res = await acceptFriend(r.id)
    if (notify) notify('✓ ' + (res.message || '已通过验证'))
    await loadAll()
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '操作失败'))
  }
}

async function doReject(r) {
  try {
    await rejectFriend(r.id)
    if (notify) notify('已拒绝该申请')
    await loadAll()
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '操作失败'))
  }
}

async function doRemove(f) {
  try {
    await removeFriend(f.friendId)
    if (notify) notify('好友已删除')
    await loadAll()
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '删除失败'))
  }
}

function fmtTime(t) {
  return (t || '').replace('T', ' ').slice(0, 16)
}
</script>

<template>
  <transition name="pop">
    <div v-if="show" class="fm-mask" @click.self="emit('close')">
      <div class="fm-panel" v-if="show">
        <button class="fm-close" @click="emit('close')" aria-label="关闭">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>

        <h2 class="fm-title">我的好友</h2>
        <p class="fm-sub">添加好友需要对方验证；成为好友后可以邀请对方来一局五子棋。</p>

        <div class="fm-tabs">
          <button class="fmt" :class="{ on: tab === 'list' }" @click="tab = 'list'">
            好友 <i>{{ friends.length }}</i>
          </button>
          <button class="fmt" :class="{ on: tab === 'requests' }" @click="tab = 'requests'">
            验证 <i>{{ requests.length }}</i>
          </button>
          <button class="fmt" :class="{ on: tab === 'add' }" @click="tab = 'add'">添加</button>
        </div>

        <!-- 好友列表 -->
        <div v-if="tab === 'list'" class="fm-body">
          <div v-if="loading" class="fm-state">载入中…</div>
          <div v-else-if="!friends.length" class="fm-state">
            还没有好友。去「添加」里输入对方的用户名，等对方验证后就加上啦。
          </div>
          <ul v-else class="f-list">
            <li v-for="f in friends" :key="f.id" class="f-item">
              <div class="f-main">
                <span class="f-name">@{{ f.username }}</span>
                <span class="f-since">好友于 {{ fmtTime(f.createTime) }}</span>
              </div>
              <button class="f-del" @click="doRemove(f)">删除</button>
            </li>
          </ul>
        </div>

        <!-- 收到的验证 -->
        <div v-else-if="tab === 'requests'" class="fm-body">
          <div v-if="loading" class="fm-state">载入中…</div>
          <template v-else>
            <div v-if="requests.length" class="fm-sec">收到的申请（需要你验证）</div>
            <div v-if="!requests.length" class="fm-state">没有待验证的申请。</div>
            <ul v-else class="f-list">
              <li v-for="r in requests" :key="'r' + r.id" class="f-item">
                <div class="f-main">
                  <span class="f-name">@{{ r.username }}</span>
                  <span class="f-since">申请于 {{ fmtTime(r.createTime) }}</span>
                </div>
                <button class="f-ok" @click="doAccept(r)">同意</button>
                <button class="f-del" @click="doReject(r)">拒绝</button>
              </li>
            </ul>
            <div v-if="sent.length" class="fm-sec">我发出的申请（等待对方验证）</div>
            <ul v-if="sent.length" class="f-list">
              <li v-for="s in sent" :key="'s' + s.id" class="f-item pending">
                <div class="f-main">
                  <span class="f-name">@{{ s.username }}</span>
                  <span class="f-since">等待验证 · {{ fmtTime(s.createTime) }}</span>
                </div>
              </li>
            </ul>
          </template>
        </div>

        <!-- 添加好友 -->
        <div v-else class="fm-body">
          <form class="fm-add" @submit.prevent="submitAdd">
            <input
              v-model="addName"
              type="text"
              placeholder="输入对方的用户名"
              maxlength="50"
            />
            <button type="submit" :disabled="adding || !addName.trim()">
              {{ adding ? '发送中…' : '发送申请' }}
            </button>
          </form>
          <p class="fm-hint">对方在「验证」里同意后，你们就互为好友了。</p>
        </div>

        <p class="fm-err" v-if="err">{{ err }}</p>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.fm-mask {
  position: fixed; inset: 0; z-index: 55;
  display: grid; place-items: center; padding: 20px;
  background: rgba(5, 8, 24, .62);
  backdrop-filter: blur(8px) saturate(140%);
  -webkit-backdrop-filter: blur(8px) saturate(140%);
}
.fm-panel {
  position: relative; width: min(440px, 100%); max-height: 82vh; overflow-y: auto;
  border-radius: 20px; padding: 24px 24px 26px;
  background: linear-gradient(160deg, rgba(20, 24, 56, .94), rgba(11, 13, 38, .96));
  border: 1px solid rgba(255, 255, 255, .16);
  box-shadow: 0 30px 80px rgba(0, 0, 0, .55), 0 0 0 1px rgba(45, 226, 230, .12);
  animation: pop .3s ease;
}
.fm-close {
  position: absolute; top: 14px; right: 14px;
  width: 36px; height: 36px; border-radius: 50%; cursor: pointer;
  display: grid; place-items: center; color: #eef2ff;
  background: rgba(10, 14, 39, .5); border: 1px solid rgba(255, 255, 255, .2); transition: .25s;
}
.fm-close svg { width: 18px; height: 18px; }
.fm-close:hover { color: #fff; border-color: var(--magenta); }
.fm-title { font-size: 20px; font-weight: 600; color: #eef2ff; margin-bottom: 6px; }
.fm-sub { font-size: 12.5px; color: #9fb0d8; margin-bottom: 16px; line-height: 1.6; }

.fm-tabs { display: flex; gap: 8px; margin-bottom: 16px; }
.fmt {
  flex: 1; border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit;
  font-size: 13px; color: #cdd6f4; background: rgba(255, 255, 255, .05); padding: 8px 0; border-radius: 11px; transition: .22s;
}
.fmt i { font-style: normal; color: var(--cyan-soft); margin-left: 4px; }
.fmt:hover { color: #fff; border-color: var(--cyan); }
.fmt.on {
  color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
}
.fmt.on i { color: rgba(4, 18, 31, .7); }

.fm-body { min-height: 120px; }
.fm-state { font-size: 13px; color: #8b97bd; text-align: center; padding: 26px 10px; line-height: 1.7; }
.fm-sec { font-size: 12px; color: #9fb0d8; letter-spacing: 1px; margin: 14px 0 8px; }

.f-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.f-item { display: flex; align-items: center; gap: 10px; padding: 11px 14px; border-radius: 13px;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .1); }
.f-item.pending { opacity: .75; }
.f-main { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.f-name { font-size: 13.5px; color: #eef2ff; }
.f-since { font-size: 11px; color: #7e8ab0; }
.f-del, .f-ok {
  border: 1px solid rgba(255, 255, 255, .18); cursor: pointer; font-family: inherit; font-size: 12px;
  padding: 6px 12px; border-radius: 9px; color: #cdd6f4; background: transparent; transition: .2s;
}
.f-ok { color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); }
.f-del:hover { color: #ff8aa8; border-color: var(--magenta); }

.fm-add { display: flex; gap: 8px; }
.fm-add input {
  flex: 1; padding: 11px 13px; font-family: inherit; font-size: 14px; color: #fff;
  background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .16);
  border-radius: 12px; outline: none; transition: .22s;
}
.fm-add input:focus { border-color: var(--cyan); background: rgba(45, 226, 230, .06); }
.fm-add button {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13.5px; font-weight: 600; color: #04121f;
  padding: 0 18px; border-radius: 12px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
}
.fm-add button:disabled { opacity: .5; cursor: not-allowed; }
.fm-hint { font-size: 11.5px; color: #8b97bd; margin-top: 10px; }
.fm-err { font-size: 12.5px; color: #ff8aa8; margin-top: 10px; }

@keyframes pop { from { opacity: 0; transform: translateY(14px) scale(.97); } to { opacity: 1; transform: none; } }
.pop-enter-active, .pop-leave-active { transition: opacity .26s ease; }
.pop-enter-from, .pop-leave-to { opacity: 0; }
</style>
