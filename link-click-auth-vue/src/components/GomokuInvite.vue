<script setup>
import { ref, onMounted, onBeforeUnmount, inject } from 'vue'
import { useRouter } from 'vue-router'
import { fetchMyGames, acceptGomoku, declineGomoku } from '../api/gomoku'

/* 全局五子棋对弈邀请：挂在 App.vue，任何页面都能收到 / 接受 / 拒绝邀请 */
const notify = inject('appNotify', null)
const userRef = inject('appUser', null)
const router = useRouter()

const invites = ref([])     // 收到的邀请（可同意 / 拒绝）
const sent = ref([])        // 我发出的等待邀请（可取消）
const open = ref(false)
const busy = ref(false)
let timer = null
let knownIds = ''

async function poll() {
  if (!userRef || !userRef.value) { invites.value = []; return }
  try {
    const res = await fetchMyGames()
    const list = (res.data && res.data.toAccept) || []
    const ids = list.map(g => g.id).join(',')
    // 新邀请到来时自动展开面板并提醒一次
    if (ids && ids !== knownIds) {
      open.value = true
      if (notify) notify('⚫ 收到五子棋对弈邀请')
    }
    knownIds = ids
    invites.value = list
  } catch (_) { /* 网络抖动忽略本轮 */ }
}

async function accept(g) {
  if (busy.value) return
  busy.value = true
  try {
    await acceptGomoku(g.id)
    invites.value = invites.value.filter(x => x.id !== g.id)
    if (notify) notify('✓ 已接受邀请，正在进入对局')
    goToGame()
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '接受失败'))
    poll()
  } finally { busy.value = false }
}

async function decline(g) {
  try {
    await declineGomoku(g.id)
    invites.value = invites.value.filter(x => x.id !== g.id)
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '拒绝失败'))
  }
}

/** 跳到社区小游戏并自动切到「好友对弈」模式 */
function goToGame() {
  open.value = false
  sessionStorage.setItem('gomoku-open-net', '1')
  window.dispatchEvent(new CustomEvent('gomoku-open-net'))
  if (router.currentRoute.value.path !== '/community') router.push('/community')
}

onMounted(() => {
  poll()
  timer = setInterval(poll, 3000)
})
onBeforeUnmount(() => { if (timer) clearInterval(timer) })
</script>

<template>
  <div class="gi-root">
    <button class="gi-fab" :class="{ on: open }" @click="open = !open" title="五子棋好友对弈邀请">
      <span>⚫</span>
      <b v-if="invites.length" class="gi-badge">{{ invites.length }}</b>
    </button>

    <div v-if="open" class="gi-panel">
      <div class="gi-head">
        <h3>五子棋 · 好友对弈</h3>
        <button class="gi-x" @click="open = false" aria-label="关闭">✕</button>
      </div>

      <div class="gi-sec">收到的邀请（{{ invites.length }}）</div>
      <div v-if="!invites.length" class="gi-empty">暂时没有对弈邀请，也可以主动约好友来一局。</div>
      <div v-for="g in invites" :key="g.id" class="gi-invite">
        <p class="gi-name">@{{ g.hostUsername }} 邀请你对弈</p>
        <p class="gi-meta">TA 执{{ g.blackUserId === g.guestUserId ? '白' : '黑' }} · 你执{{ g.blackUserId === g.guestUserId ? '黑' : '白' }}</p>
        <div class="gi-btns">
          <button class="gi-no" :disabled="busy" @click="decline(g)">拒绝</button>
          <button class="gi-ok" :disabled="busy" @click="accept(g)">接受并开始</button>
        </div>
      </div>

      <button class="gi-go" @click="goToGame">去邀请好友对弈 →</button>
    </div>
  </div>
</template>

<style scoped>
.gi-root { position: fixed; right: 22px; bottom: 22px; z-index: 70; display: flex; flex-direction: column; align-items: flex-end; gap: 10px; }
.gi-fab { position: relative; width: 48px; height: 48px; border-radius: 50%; cursor: pointer; font-size: 20px; color: #04121f; border: 0; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 10px 28px rgba(138, 92, 255, .45); transition: transform .22s; }
.gi-fab:hover { transform: scale(1.08); }
.gi-fab.on { transform: rotate(45deg); }
.gi-badge { position: absolute; top: -4px; right: -4px; min-width: 18px; height: 18px; padding: 0 4px; border-radius: 999px; display: grid; place-items: center; font-size: 11px; font-weight: 700; color: #fff; background: #ff48c4; box-shadow: 0 3px 10px rgba(255, 72, 196, .6); }
.gi-panel { width: min(320px, calc(100vw - 44px)); max-height: 70vh; overflow-y: auto; padding: 16px; border-radius: 16px; background: linear-gradient(160deg, rgba(22, 26, 62, .98), rgba(11, 14, 38, .99)); border: 1px solid rgba(255, 255, 255, .16); box-shadow: 0 24px 70px rgba(0, 0, 0, .62); }
.gi-head { display: flex; align-items: center; justify-content: space-between; }
.gi-head h3 { font-size: 15px; font-weight: 600; color: #fff; letter-spacing: .5px; }
.gi-x { width: 26px; height: 26px; border: 0; cursor: pointer; border-radius: 8px; color: #aab6da; background: rgba(255, 255, 255, .08); font-size: 12px; }
.gi-x:hover { color: #fff; }
.gi-sec { margin: 14px 0 8px; font-size: 11.5px; letter-spacing: 1px; color: var(--cyan); }
.gi-empty { font-size: 12.5px; color: #9fb0d8; line-height: 1.7; padding: 8px 0; }
.gi-invite { padding: 11px 12px; border-radius: 12px; margin-bottom: 8px; background: rgba(255, 72, 196, .1); border: 1px solid rgba(255, 72, 196, .3); }
.gi-name { font-size: 13.5px; color: #eef2ff; font-weight: 600; }
.gi-meta { font-size: 11.5px; color: #9fb0d8; margin: 4px 0 10px; }
.gi-btns { display: flex; gap: 8px; justify-content: flex-end; }
.gi-no, .gi-ok { padding: 6px 14px; border-radius: 9px; cursor: pointer; font-family: inherit; font-size: 12px; }
.gi-no { color: #cdd6f4; background: transparent; border: 1px solid rgba(255, 255, 255, .2); }
.gi-no:hover { color: #ff8aa8; border-color: var(--magenta); }
.gi-ok { color: #04121f; font-weight: 600; border: 0; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); }
.gi-no:disabled, .gi-ok:disabled { opacity: .6; cursor: not-allowed; }
.gi-go { width: 100%; margin-top: 10px; padding: 10px; border-radius: 11px; cursor: pointer; font-family: inherit; font-size: 13px; font-weight: 600; color: #04121f; border: 0; background: rgba(45, 226, 230, .85); }
.gi-go:hover { filter: brightness(1.08); }
</style>
