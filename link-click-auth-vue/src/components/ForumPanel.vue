<script setup>
import { ref, watch, inject, computed } from 'vue'
import { fetchPosts, createPost, fetchPostDetail, addReply, deletePost, deleteReply } from '../api/forum'

/**
 * 论坛互动态内容块（嵌入社交中心 SocialPanel 的「互动态」标签页）
 * show 为 true 时加载数据；遮罩/标题/关闭按钮由父级负责。
 */
const props = defineProps({
  show: { type: Boolean, default: false }
})

const notify = inject('appNotify')
const me = inject('appUser', null)

/* ===== 视图状态：list 帖子列表 / detail 帖子详情 / compose 发帖 ===== */
const view = ref('list')
const posts = ref([])
const total = ref(0)
const page = ref(1)
const size = 20
const loading = ref(false)
const err = ref('')

/* ===== 详情 ===== */
const detail = ref(null)
const detailLoading = ref(false)
const detailErr = ref('')
const replyDraft = ref('')
const replySending = ref(false)

/* ===== 发帖 ===== */
const title = ref('')
const content = ref('')
const posting = ref(false)

function fmtTime(t) {
  return (t || '').replace('T', ' ').slice(0, 16)
}

function initial(n) {
  return (n || '?').slice(0, 1).toUpperCase()
}

const canPrev = computed(() => page.value > 1)
const canNext = computed(() => page.value * size < total.value)

async function loadList(p = 1) {
  loading.value = true
  err.value = ''
  try {
    const res = await fetchPosts(p, size)
    posts.value = (res.data && res.data.records) || []
    total.value = (res.data && res.data.total) || 0
    page.value = p
  } catch (e) {
    err.value = e.message || '加载失败'
  } finally {
    loading.value = false
  }
}

async function openDetail(post) {
  view.value = 'detail'
  detail.value = null
  detailErr.value = ''
  detailLoading.value = true
  try {
    const res = await fetchPostDetail(post.id)
    detail.value = res.data
  } catch (e) {
    detailErr.value = e.message || '加载失败'
  } finally {
    detailLoading.value = false
  }
}

async function submitReply() {
  const text = replyDraft.value.trim()
  if (!text || !detail.value || replySending.value) return
  replySending.value = true
  try {
    const res = await addReply(detail.value.id, text)
    detail.value.replies.push(res.data)
    detail.value.replyCount = res.data.replyCount
    replyDraft.value = ''
    // 同步列表上的回复数
    const p = posts.value.find((x) => x.id === detail.value.id)
    if (p) p.replyCount = res.data.replyCount
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '回复失败'))
  } finally {
    replySending.value = false
  }
}

async function doDeletePost(post) {
  try {
    await deletePost(post.id)
    if (notify) notify('✓ 帖子已删除')
    if (detail.value && detail.value.id === post.id) view.value = 'list'
    await loadList(page.value)
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '删除失败'))
  }
}

async function doDeleteReply(reply) {
  try {
    const res = await deleteReply(reply.id)
    detail.value.replies = detail.value.replies.filter((r) => r.id !== reply.id)
    if (res.data && res.data.replyCount !== undefined) detail.value.replyCount = res.data.replyCount
    const p = posts.value.find((x) => x.id === detail.value.id)
    if (p) p.replyCount = detail.value.replyCount
    if (notify) notify('✓ 回复已删除')
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '删除失败'))
  }
}

async function submitPost() {
  const t = title.value.trim()
  const c = content.value.trim()
  if (!t || !c || posting.value) return
  posting.value = true
  try {
    const res = await createPost(t, c)
    if (notify) notify('✓ ' + (res.message || '帖子已发布'))
    title.value = ''
    content.value = ''
    view.value = 'list'
    await loadList(1)
  } catch (e) {
    if (notify) notify('✗ ' + (e.message || '发布失败'))
  } finally {
    posting.value = false
  }
}

/** 我发的（或管理员）才能删 */
function canDelete(userId) {
  if (!me || !me.value) return false
  return userId === me.value.id || me.value.permission === 0
}

watch(() => props.show, (v) => {
  if (v) {
    view.value = 'list'
    loadList(1)
  }
}, { immediate: false })
</script>

<template>
  <div class="fo-panel">
    <div class="fo-head">
      <button v-if="view !== 'list'" class="fo-back" @click="view = 'list'" title="返回互动态">←</button>
      <span class="fo-sub">{{ view === 'detail' ? '帖子详情' : view === 'compose' ? '发布新帖' : '大家都在聊什么…' }}</span>
      <button v-if="view === 'list'" class="fo-new" @click="view = 'compose'">✎ 发帖</button>
    </div>

    <!-- 帖子列表 -->
    <div v-if="view === 'list'" class="fo-body">
      <div v-if="loading && !posts.length" class="fo-state">载入中…</div>
      <div v-else-if="err" class="fo-state err">{{ err }}</div>
      <div v-else-if="!posts.length" class="fo-state">
        还没有帖子，点右上角「✎ 发帖」写下第一贴吧。
      </div>
      <ul v-else class="fp-list">
        <li v-for="p in posts" :key="p.id" class="fp-item" @click="openDetail(p)">
          <span class="fp-avatar">
            <img v-if="p.avatar" :src="p.avatar" alt="" />
            <i v-else>{{ initial(p.nickname || p.username) }}</i>
          </span>
          <div class="fp-main">
            <div class="fp-title-row">
              <span class="fp-p-title">{{ p.title }}</span>
              <button v-if="canDelete(p.userId)" class="fp-del" @click.stop="doDeletePost(p)">删除</button>
            </div>
            <p class="fp-excerpt">{{ p.content }}</p>
            <div class="fp-meta">
              <span class="fp-author">@{{ p.username }}</span>
              <span>{{ fmtTime(p.createTime) }}</span>
              <span class="fp-replies">💬 {{ p.replyCount }}</span>
            </div>
          </div>
        </li>
      </ul>
      <div v-if="posts.length" class="fo-pager">
        <button :disabled="!canPrev" @click="loadList(page - 1)">← 上一页</button>
        <span>第 {{ page }} 页 / 共 {{ Math.max(1, Math.ceil(total / size)) }} 页</span>
        <button :disabled="!canNext" @click="loadList(page + 1)">下一页 →</button>
      </div>
    </div>

    <!-- 帖子详情 -->
    <div v-else-if="view === 'detail'" class="fo-body">
      <div v-if="detailLoading" class="fo-state">载入中…</div>
      <div v-else-if="detailErr" class="fo-state err">{{ detailErr }}</div>
      <template v-else-if="detail">
        <article class="fd-post">
          <div class="fd-author">
            <span class="fd-avatar">
              <img v-if="detail.avatar" :src="detail.avatar" alt="" />
              <i v-else>{{ initial(detail.nickname || detail.username) }}</i>
            </span>
            <div class="fd-author-meta">
              <span class="fd-name">@{{ detail.username }}</span>
              <span class="fd-time">{{ fmtTime(detail.createTime) }} · 💬 {{ detail.replyCount }}</span>
            </div>
            <button v-if="canDelete(detail.userId)" class="fp-del" @click="doDeletePost(detail)">删除帖子</button>
          </div>
          <h3 class="fd-title">{{ detail.title }}</h3>
          <p class="fd-content">{{ detail.content }}</p>
        </article>

        <div class="fd-sec">回复（{{ detail.replies.length }}）</div>
        <ul v-if="detail.replies.length" class="fr-list">
          <li v-for="r in detail.replies" :key="r.id" class="fr-item">
            <span class="fr-avatar">
              <img v-if="r.avatar" :src="r.avatar" alt="" />
              <i v-else>{{ initial(r.nickname || r.username) }}</i>
            </span>
            <div class="fr-main">
              <div class="fr-meta">
                <span class="fr-name">@{{ r.username }}</span>
                <span class="fr-time">{{ fmtTime(r.createTime) }}</span>
                <button v-if="canDelete(r.userId)" class="fp-del" @click="doDeleteReply(r)">删除</button>
              </div>
              <p class="fr-text">{{ r.content }}</p>
            </div>
          </li>
        </ul>
        <div v-else class="fo-state">还没有回复，来抢沙发！</div>

        <form v-if="me" class="fr-input" @submit.prevent="submitReply">
          <input v-model="replyDraft" type="text" maxlength="500" placeholder="写下你的回复，回车发送…" />
          <button type="submit" :disabled="replySending || !replyDraft.trim()">回复</button>
        </form>
        <p v-else class="fo-hint">登录后才能回复。</p>
      </template>
    </div>

    <!-- 发帖 -->
    <div v-else class="fo-body">
      <form v-if="me" class="fo-compose" @submit.prevent="submitPost">
        <input v-model="title" type="text" maxlength="100" placeholder="帖子标题（≤100 字）" />
        <textarea v-model="content" maxlength="3000" rows="9" placeholder="想说点什么？分享你的时光见闻…（≤3000 字）"></textarea>
        <div class="fc-actions">
          <button type="button" class="fc-cancel" @click="view = 'list'">取消</button>
          <button type="submit" :disabled="posting || !title.trim() || !content.trim()">
            {{ posting ? '发布中…' : '发布' }}
          </button>
        </div>
      </form>
      <div v-else class="fo-state">登录后才能发帖，先去右上角登录吧。</div>
    </div>
  </div>
</template>

<style scoped>
.fo-panel { height: 100%; min-height: 0; display: flex; flex-direction: column; }
.fo-head { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.fo-sub { flex: 1; font-size: 12.5px; color: #9fb0d8; }
.fo-back {
  width: 30px; height: 30px; border-radius: 9px; cursor: pointer; flex-shrink: 0;
  border: 1px solid rgba(255, 255, 255, .16); background: transparent; color: #cdd6f4; transition: .2s;
}
.fo-back:hover { color: #fff; border-color: var(--cyan); }
.fo-new {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13px; font-weight: 600;
  color: #04121f; padding: 8px 16px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
}
.fo-body { flex: 1; min-height: 0; overflow-y: auto; }
.fo-state { font-size: 13px; color: #8b97bd; text-align: center; padding: 26px 10px; line-height: 1.7; }
.fo-state.err { color: #ff8aa8; }
.fo-hint { font-size: 12px; color: #8b97bd; text-align: center; }

/* 帖子列表 */
.fp-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.fp-item {
  display: flex; gap: 10px; padding: 13px 14px; border-radius: 14px; cursor: pointer; transition: .2s;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .1);
}
.fp-item:hover { background: rgba(255, 154, 224, .08); border-color: var(--magenta); }
.fp-avatar, .fr-avatar, .fd-avatar {
  width: 36px; height: 36px; border-radius: 50%; flex-shrink: 0; overflow: hidden;
  display: grid; place-items: center; font-size: 14px; font-weight: 700; font-style: normal; color: #04121f;
  background: linear-gradient(135deg, var(--magenta), var(--purple));
}
.fp-avatar img, .fr-avatar img, .fd-avatar img { width: 100%; height: 100%; object-fit: cover; }
.fp-main { flex: 1; min-width: 0; }
.fp-title-row { display: flex; align-items: center; gap: 8px; }
.fp-p-title {
  flex: 1; min-width: 0; font-size: 14.5px; font-weight: 600; color: #eef2ff;
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.fp-excerpt {
  margin: 5px 0 7px; font-size: 12.5px; color: #9fb0d8; line-height: 1.55;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.fp-meta { display: flex; align-items: center; gap: 10px; font-size: 11px; color: #7e8ab0; }
.fp-author { color: var(--cyan-soft); }
.fp-replies { margin-left: auto; }
.fp-del {
  flex-shrink: 0; border: 1px solid rgba(255, 255, 255, .18); cursor: pointer; font-family: inherit;
  font-size: 11px; padding: 4px 10px; border-radius: 8px; color: #cdd6f4; background: transparent; transition: .2s;
}
.fp-del:hover { color: #ff8aa8; border-color: var(--magenta); }

.fo-pager { display: flex; align-items: center; justify-content: center; gap: 14px; margin-top: 16px; font-size: 12px; color: #9fb0d8; }
.fo-pager button {
  border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit; font-size: 12px;
  color: #cdd6f4; background: transparent; padding: 6px 14px; border-radius: 10px; transition: .2s;
}
.fo-pager button:hover:not(:disabled) { color: #fff; border-color: var(--cyan); }
.fo-pager button:disabled { opacity: .4; cursor: not-allowed; }

/* 帖子详情 */
.fd-post { padding: 4px 2px 14px; border-bottom: 1px solid rgba(255, 255, 255, .1); }
.fd-author { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.fd-author-meta { display: flex; flex-direction: column; gap: 2px; flex: 1; }
.fd-name { font-size: 13px; color: #eef2ff; font-weight: 600; }
.fd-time { font-size: 11px; color: #7e8ab0; }
.fd-title { font-size: 18px; font-weight: 700; color: #eef2ff; margin-bottom: 8px; line-height: 1.4; }
.fd-content { font-size: 13.5px; color: #cdd6f4; line-height: 1.75; white-space: pre-wrap; word-break: break-word; }

.fd-sec { font-size: 12px; color: #9fb0d8; letter-spacing: 1px; margin: 14px 0 10px; }
.fr-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
.fr-item {
  display: flex; gap: 9px; padding: 11px 13px; border-radius: 13px;
  background: rgba(255, 255, 255, .04); border: 1px solid rgba(255, 255, 255, .08);
}
.fr-main { flex: 1; min-width: 0; }
.fr-meta { display: flex; align-items: center; gap: 10px; margin-bottom: 4px; }
.fr-name { font-size: 12.5px; color: #eef2ff; font-weight: 600; }
.fr-time { font-size: 10.5px; color: #7e8ab0; }
.fr-meta .fp-del { margin-left: auto; }
.fr-text { margin: 0; font-size: 13px; color: #cdd6f4; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }

.fr-input { display: flex; gap: 8px; margin-top: 14px; }
.fr-input input {
  flex: 1; padding: 11px 13px; font-family: inherit; font-size: 13.5px; color: #fff;
  background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .16);
  border-radius: 12px; outline: none; transition: .22s;
}
.fr-input input:focus { border-color: var(--cyan); background: rgba(45, 226, 230, .06); }
.fr-input button {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13px; font-weight: 600; color: #04121f;
  padding: 0 18px; border-radius: 12px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
}
.fr-input button:disabled { opacity: .5; cursor: not-allowed; }

/* 发帖表单 */
.fo-compose { display: flex; flex-direction: column; gap: 12px; }
.fo-compose input, .fo-compose textarea {
  padding: 12px 14px; font-family: inherit; font-size: 14px; color: #fff;
  background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .16);
  border-radius: 13px; outline: none; transition: .22s; resize: vertical;
}
.fo-compose input:focus, .fo-compose textarea:focus { border-color: var(--cyan); background: rgba(45, 226, 230, .06); }
.fc-actions { display: flex; justify-content: flex-end; gap: 10px; }
.fc-cancel {
  border: 1px solid rgba(255, 255, 255, .18); cursor: pointer; font-family: inherit; font-size: 13px;
  color: #cdd6f4; background: transparent; padding: 9px 20px; border-radius: 12px; transition: .2s;
}
.fc-cancel:hover { color: #fff; border-color: var(--magenta); }
.fc-actions button[type="submit"] {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13.5px; font-weight: 600; color: #04121f;
  padding: 9px 24px; border-radius: 12px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
}
.fc-actions button[type="submit"]:disabled { opacity: .5; cursor: not-allowed; }
</style>
