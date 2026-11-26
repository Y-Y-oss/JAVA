<script setup>
import { ref, onMounted, inject, computed } from 'vue'
import NavBar from '../components/NavBar.vue'
import ArchiveCard from '../components/ArchiveCard.vue'
import ArchiveDetail from '../components/ArchiveDetail.vue'
import ArchiveForm from '../components/ArchiveForm.vue'
import FriendsPanel from '../components/FriendsPanel.vue'
import { useRouter } from 'vue-router'
import { fetchPublicArchives, getArchive, updateArchive, deleteArchive } from '../api/home'
import { toggleLike, toggleFavorite } from '../api/social'
import { applyFriend, fetchFriends, fetchFriendRequests, fetchSentRequests } from '../api/friends'
import { KNOWN_TAGS, coverStyle } from '../utils/archiveStyle'

const notify = inject('appNotify')
// 当前登录用户（App.vue provide 注入），未登录时点赞/收藏只提示不请求
const user = inject('appUser', null)

// 娱乐 / 游戏专区已独立成页，社区只保留一个导航入口
const router = useRouter()

const TAGS = ['全部', ...KNOWN_TAGS]

/* ===== 数据：一次拉全公开档案（演示规模），前端完成 搜索 / 标签筛选 / 排序 / 统计 ===== */
const allItems = ref([])
const loading = ref(false)
const error = ref('')
const keyword = ref('')
const activeTag = ref('全部')
const sortBy = ref('update') // update | create | title

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await fetchPublicArchives(1, 50)
    allItems.value = (res.data && res.data.records) || []
  } catch (err) {
    error.value = '社区加载失败：' + (err.message || '后端未连接')
  } finally {
    loading.value = false
  }
  loadFriendState()
}

/* 社区概览：公开档案数 / 时光收藏家数 / 标签分布 */
const stats = computed(() => {
  const list = allItems.value
  const authors = new Set(list.map((a) => a.username).filter(Boolean))
  const tagCount = {}
  for (const a of list) {
    const t = a.tag || '未分类'
    tagCount[t] = (tagCount[t] || 0) + 1
  }
  const max = Math.max(1, ...Object.values(tagCount))
  return { total: list.length, authors: authors.size, tagCount, max }
})

/* 精选时光：最近更新的公开档案作头图 */
const featured = computed(() => {
  const list = allItems.value
  if (!list.length) return null
  return [...list].sort((a, b) => (b.updateTime || '').localeCompare(a.updateTime || ''))[0]
})

/* 展示列表：搜索 + 标签 + 排序 */
const displayItems = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  let list = allItems.value
  if (kw) {
    list = list.filter((a) =>
      `${a.title || ''} ${a.content || ''} ${a.tag || ''} ${a.username || ''}`.toLowerCase().includes(kw)
    )
  }
  if (activeTag.value !== '全部') {
    list = list.filter((a) => (a.tag || '未分类') === activeTag.value)
  }
  const arr = list.slice()
  if (sortBy.value === 'create') arr.sort((a, b) => (b.createTime || '').localeCompare(a.createTime || ''))
  else if (sortBy.value === 'title') arr.sort((a, b) => (a.title || '').localeCompare(b.title || ''))
  else arr.sort((a, b) => (b.updateTime || '').localeCompare(a.updateTime || ''))
  return arr
})

function avatarText(name) {
  return (name || '?').slice(0, 1).toUpperCase()
}

/* ===== 详情 + 编辑/删除（仅档案主人可见按钮） ===== */
const detailOpen = ref(false)
const detailLoading = ref(false)
const detailError = ref('')
const detail = ref(null)
async function openDetail(m) {
  detailOpen.value = true
  detailLoading.value = true
  detailError.value = ''
  detail.value = null
  try {
    const res = await getArchive(m.id)
    detail.value = res.data || null
  } catch (err) {
    detailError.value = '档案详情加载失败：' + (err.message || '后端未连接')
  } finally {
    detailLoading.value = false
  }
}
function closeDetail() {
  detailOpen.value = false
  detail.value = null
  detailError.value = ''
}

const formShow = ref(false)
const formInitial = ref(null)
function openEdit(arch) {
  formInitial.value = arch
  formShow.value = true
}
async function onFormSaved(arch) {
  formShow.value = false
  if (notify) notify('✓ 档案已更新')
  await load()
  if (detailOpen.value && arch && detail.value && detail.value.id === arch.id) detail.value = arch
  formInitial.value = null
}
function onFormClose() {
  formShow.value = false
  formInitial.value = null
}
async function onDelete(arch) {
  try {
    await deleteArchive(arch.id)
    if (notify) notify('✓ 档案已从时光长廊抹去')
    detailOpen.value = false
    await load()
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '删除失败'))
  }
}

/* ===== 好友面板 ===== */
const friendsOpen = ref(false)

/* ===== 档案墙一键加好友：纯文字按钮 + 状态区分（✓好友/已申请/通过验证） ===== */
const friendNames = ref(new Set())   // 已是好友
const sentNames = ref(new Set())     // 我发出、待对方验证
const incomingNames = ref(new Set()) // 对方发给我、待我验证

async function loadFriendState() {
  const u = user && user.value
  if (!u) return
  try {
    const [f, r, s] = await Promise.all([fetchFriends(), fetchFriendRequests(), fetchSentRequests()])
    friendNames.value = new Set((f.data || []).map((x) => x.username))
    incomingNames.value = new Set((r.data || []).map((x) => x.username))
    sentNames.value = new Set((s.data || []).map((x) => x.username))
  } catch (_) { /* 未登录/网络问题忽略 */ }
}

/** 档案作者的好友状态：self 自己（不显示按钮）/ friends 已是好友 / incoming 待我验证 / sent 已申请 / none 未加 */
function friendStateOf(arch) {
  const u = user && user.value
  if (!u) return 'guest'
  if (arch.userId === u.id) return 'self'
  if (friendNames.value.has(arch.username)) return 'friends'
  if (incomingNames.value.has(arch.username)) return 'incoming'
  if (sentNames.value.has(arch.username)) return 'sent'
  return 'none'
}

async function handleAddFriend(arch) {
  const u = user && user.value
  if (!u) { if (notify) notify('✗ 请先登录，再添加好友'); return }
  // 对方已申请过我 → 直接打开好友面板去验证
  if (friendStateOf(arch) === 'incoming') {
    friendsOpen.value = true
    return
  }
  try {
    const res = await applyFriend(arch.username)
    if (notify) notify('✓ ' + (res.message || '好友申请已发送'))
    await loadFriendState()
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '申请失败'))
  }
}

/* ===== 社区互动：点赞 / 收藏（卡片上直接切换） ===== */
function requireLogin() {
  const u = user && user.value
  if (!u) {
    if (notify) notify('✗ 请先登录，再来和大家互动')
    return false
  }
  return true
}

/** 本地即时更新某档案的互动字段，避免整墙重拉 */
function patchItem(id, patch) {
  const idx = allItems.value.findIndex((a) => a.id === id)
  if (idx >= 0) allItems.value[idx] = { ...allItems.value[idx], ...patch }
  if (featured.value && featured.value.id === id) featured.value = { ...featured.value, ...patch }
}

async function onToggleLike(arch) {
  if (!requireLogin()) return
  const liked = !arch.liked
  const likeCount = Math.max(0, (arch.likeCount || 0) + (liked ? 1 : -1))
  patchItem(arch.id, { liked, likeCount }) // 乐观更新，失败再回滚
  try {
    const res = await toggleLike(arch.id)
    patchItem(arch.id, res.data || {})
  } catch (err) {
    patchItem(arch.id, { liked: arch.liked, likeCount: arch.likeCount })
    if (notify) notify('✗ ' + (err.message || '点赞失败'))
  }
}

async function onToggleFavorite(arch) {
  if (!requireLogin()) return
  const favorited = !arch.favorited
  const favoriteCount = Math.max(0, (arch.favoriteCount || 0) + (favorited ? 1 : -1))
  patchItem(arch.id, { favorited, favoriteCount })
  try {
    const res = await toggleFavorite(arch.id)
    patchItem(arch.id, res.data || {})
  } catch (err) {
    patchItem(arch.id, { favorited: arch.favorited, favoriteCount: arch.favoriteCount })
    if (notify) notify('✗ ' + (err.message || '收藏失败'))
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <NavBar />
    <main class="content">
      <header class="head">
        <h1>社区 · 档案墙</h1>
        <p>这里展示所有人公开分享的时光，看看别人珍藏的瞬间。</p>
      </header>

      <!-- 社区概览 -->
      <section class="overview">
        <div class="ov-card">
          <span class="ov-num">{{ stats.total }}</span>
          <span class="ov-label">公开档案</span>
        </div>
        <div class="ov-card">
          <span class="ov-num">{{ stats.authors }}</span>
          <span class="ov-label">时光收藏家</span>
        </div>
        <div class="ov-card friend-card" @click="friendsOpen = true" title="添加好友 / 验证申请">
          <span class="ov-num">👥</span>
          <span class="ov-label">我的好友</span>
        </div>
        <div class="ov-card fun-card" @click="router.push('/fun')" title="去娱乐 / 游戏专区">
          <span class="ov-num">🎉</span>
          <span class="ov-label">娱乐专区</span>
        </div>
        <div class="ov-tags">
          <span class="ov-tags-title">标签分布</span>
          <div class="ov-bars">
            <div v-for="(c, t) in stats.tagCount" :key="t" class="ov-bar-row">
              <span class="ov-bar-name">{{ t }}</span>
              <span class="ov-bar-track"><i :style="{ width: (c / stats.max * 100) + '%' }"></i></span>
              <span class="ov-bar-c">{{ c }}</span>
            </div>
          </div>
        </div>
      </section>

      <!-- 精选时光 -->
      <section v-if="featured" class="featured" :style="coverStyle(featured)">
        <div class="feat-mask"></div>
        <div class="feat-body">
          <span class="feat-badge">★ 精选时光</span>
          <h2 class="feat-title">{{ featured.title }}</h2>
          <p class="feat-excerpt">{{ featured.content }}</p>
          <div class="feat-meta">
            <span class="feat-avatar">{{ avatarText(featured.username) }}</span>
            <span class="feat-author">@{{ featured.username }}</span>
            <span class="feat-dot">·</span>
            <span>{{ featured.archiveDate || '—' }}</span>
            <span class="feat-tag">{{ featured.tag || '时光' }}</span>
          </div>
          <button class="feat-btn" @click="openDetail(featured)">查看这段时光 →</button>
        </div>
      </section>

      <!-- 娱乐 / 游戏专区已独立成页，社区这里只留一个导航入口 -->
      <section class="fun-entry" @click="router.push('/fun')">
        <span class="fe-emoji">🎮</span>
        <div class="fe-text">
          <h2>娱乐专区 · 游戏专区</h2>
          <p>8 款通关小游戏、番剧视频和 10 个摸鱼小玩法，已搬到独立的「娱乐」页面</p>
        </div>
        <span class="fe-go">去逛逛 →</span>
      </section>

      <!-- 工具栏：搜索 + 标签筛选 + 排序 -->
      <section class="toolbar">
        <form class="searchbar" @submit.prevent>
          <svg class="s-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" />
          </svg>
          <input v-model="keyword" type="text" class="s-input" placeholder="搜索社区里公开的时光…（标题/内容/作者）" />
          <button v-if="keyword" type="button" class="s-clear" @click="keyword = ''" aria-label="清除">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18" /></svg>
          </button>
        </form>

        <div class="chips">
          <button
            v-for="t in TAGS"
            :key="t"
            class="chip"
            :class="{ on: activeTag === t }"
            @click="activeTag = t"
          >{{ t }}</button>
        </div>

        <div class="sort">
          <span class="sort-label">排序</span>
          <button class="sort-btn" :class="{ on: sortBy === 'update' }" @click="sortBy = 'update'">最近更新</button>
          <button class="sort-btn" :class="{ on: sortBy === 'create' }" @click="sortBy = 'create'">最新创建</button>
          <button class="sort-btn" :class="{ on: sortBy === 'title' }" @click="sortBy = 'title'">标题 A→Z</button>
        </div>
      </section>

      <div v-if="loading" class="state">载入中…</div>
      <div v-else-if="error" class="state err">{{ error }}</div>
      <div v-else-if="!displayItems.length" class="state">
        没有符合条件的公开档案。换个标签或关键词试试，去首页把一段时光设为「公开」吧。
      </div>

      <div v-else>
        <p class="result-count">共 {{ displayItems.length }} 段公开时光</p>
        <div class="grid">
          <ArchiveCard
            v-for="m in displayItems"
            :key="m.id"
            :archive="m"
            :author="m.username"
            :cover-h="150"
            interactive
            one-line
            :friend-state="friendStateOf(m)"
            @open="openDetail"
            @like="onToggleLike"
            @fav="onToggleFavorite"
            @add-friend="handleAddFriend"
          />
        </div>
      </div>
    </main>

    <ArchiveDetail
      :archive="detail"
      :loading="detailLoading"
      :error="detailError"
      @close="closeDetail"
      @edit="openEdit"
      @delete="onDelete"
    />
    <ArchiveForm :initial="formInitial" :show="formShow" @saved="onFormSaved" @close="onFormClose" />
    <FriendsPanel :show="friendsOpen" @close="friendsOpen = false" />
  </div>
</template>

<style scoped>
.page { position: relative; z-index: 2; height: 100vh; overflow-y: auto; color: #eef2ff; }
.content { max-width: 1180px; margin: 0 auto; padding: 40px 22px 60px; }
.head { text-align: center; margin-bottom: 22px; }
.head h1 { font-size: 28px; font-weight: 600; letter-spacing: 2px; }
.head p { color: #9fb0d8; font-size: 14px; margin-top: 8px; }

/* ===== 社区概览 ===== */
.overview {
  display: grid; grid-template-columns: 140px 140px 140px 130px 1fr; gap: 16px; align-items: stretch;
  max-width: 980px; margin: 0 auto 26px; padding: 18px 20px;
  border-radius: 18px; background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
}
.friend-card, .fun-card { cursor: pointer; transition: .22s; border-radius: 12px; }
.friend-card:hover, .fun-card:hover { background: rgba(45, 226, 230, .1); transform: translateY(-2px); }
.ov-card { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px;
  border-right: 1px solid rgba(255, 255, 255, .1); }
.ov-card:last-of-type { border-right: 0; }
.ov-num { font-size: 34px; font-weight: 700; line-height: 1;
  background: linear-gradient(135deg, var(--cyan), var(--magenta)); -webkit-background-clip: text; background-clip: text; color: transparent; }
.ov-label { font-size: 12.5px; color: #9fb0d8; letter-spacing: 1px; }
.ov-tags { min-width: 0; }
.ov-tags-title { font-size: 12px; color: #9fb0d8; letter-spacing: 1px; }
.ov-bars { margin-top: 8px; display: flex; flex-direction: column; gap: 6px; }
.ov-bar-row { display: flex; align-items: center; gap: 8px; font-size: 12px; }
.ov-bar-name { width: 44px; flex-shrink: 0; color: #cdd6f4; text-align: right; }
.ov-bar-track { flex: 1; height: 7px; border-radius: 999px; background: rgba(255, 255, 255, .08); overflow: hidden; }
.ov-bar-track i { display: block; height: 100%; border-radius: 999px;
  background: linear-gradient(90deg, var(--cyan), var(--purple) 60%, var(--magenta)); }
.ov-bar-c { width: 18px; flex-shrink: 0; color: #9fb0d8; text-align: left; }

/* ===== 精选时光头图 ===== */
.featured { position: relative; max-width: 980px; margin: 0 auto 30px; height: 230px; border-radius: 20px; overflow: hidden;
  background-size: cover; background-position: center; display: flex; align-items: flex-end; }
.feat-mask { position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(10, 14, 39, .15) 0%, rgba(10, 14, 39, .82) 100%); }
.feat-body { position: relative; z-index: 2; padding: 22px 26px; max-width: 720px; }
.feat-badge { display: inline-block; font-size: 11px; letter-spacing: 1px; color: #04121f; font-weight: 700;
  padding: 4px 12px; border-radius: 999px; background: linear-gradient(135deg, var(--cyan), var(--magenta)); }
.feat-title { font-size: 24px; font-weight: 700; margin: 10px 0 8px; }
.feat-excerpt { font-size: 13.5px; line-height: 1.6; color: #cdd6f4;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.feat-meta { display: flex; align-items: center; gap: 8px; margin-top: 12px; font-size: 12.5px; color: #aeb9dd; }
.feat-avatar { width: 26px; height: 26px; border-radius: 50%; display: grid; place-items: center; font-size: 12px; font-weight: 700; color: #04121f;
  background: linear-gradient(135deg, var(--cyan), var(--purple)); }
.feat-dot { opacity: .6; }
.feat-tag { margin-left: auto; padding: 3px 12px; border-radius: 999px; font-size: 11px;
  background: rgba(255, 255, 255, .14); border: 1px solid rgba(255, 255, 255, .25); }
.feat-btn { margin-top: 14px; border: 0; cursor: pointer; font-family: inherit; font-size: 14px; font-weight: 600; color: #04121f;
  padding: 10px 22px; border-radius: 12px; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 10px 26px rgba(138, 92, 255, .4); transition: .25s; }
.feat-btn:hover { transform: translateY(-1px); }

/* ===== 娱乐专区入口：游戏与番剧视频已独立成页，社区只留导航 ===== */
.fun-entry {
  max-width: 980px; margin: 0 auto 34px; padding: 18px 22px; border-radius: 16px;
  display: flex; align-items: center; gap: 16px; cursor: pointer;
  background: linear-gradient(120deg, rgba(45, 226, 230, .12), rgba(138, 92, 255, .12) 55%, rgba(255, 72, 196, .12));
  border: 1px solid rgba(45, 226, 230, .32); transition: .26s;
}
.fun-entry:hover { transform: translateY(-3px); border-color: var(--cyan); box-shadow: 0 18px 42px rgba(45, 226, 230, .2); }
.fe-emoji { font-size: 34px; line-height: 1; }
.fe-text { min-width: 0; }
.fe-text h2 { font-size: 17px; font-weight: 700; color: #eef2ff; }
.fe-text p { font-size: 12.5px; color: #9fb0d8; margin-top: 4px; line-height: 1.5; }
.fe-go { margin-left: auto; flex-shrink: 0; font-size: 13px; font-weight: 600; color: var(--cyan-soft); white-space: nowrap; }

@media (max-width: 560px) {
  .fun-entry { flex-wrap: wrap; }
  .fe-go { margin-left: 0; }
}

/* ===== 工具栏 ===== */
.toolbar { max-width: 980px; margin: 0 auto 24px; display: flex; flex-direction: column; gap: 14px; }
.searchbar { display: flex; align-items: center; gap: 8px; padding: 7px 7px 7px 18px; border-radius: 16px;
  background: linear-gradient(180deg, rgba(255, 255, 255, .1), rgba(255, 255, 255, .04)); border: 1px solid rgba(255, 255, 255, .18);
  box-shadow: 0 18px 50px rgba(0, 0, 0, .4); transition: .3s; }
.searchbar:focus-within { border-color: var(--cyan); box-shadow: 0 18px 50px rgba(0, 0, 0, .4), 0 0 0 3px rgba(45, 226, 230, .22); }
.s-ic { width: 22px; height: 22px; color: var(--cyan-soft); flex-shrink: 0; }
.s-input { flex: 1; background: transparent; border: 0; outline: none; min-width: 0; color: #fff; font-size: 15px; font-family: inherit; padding: 12px 0; }
.s-input::placeholder { color: #8b97bd; }
.s-clear { width: 30px; height: 30px; flex-shrink: 0; border: 0; cursor: pointer; border-radius: 9px; display: grid; place-items: center; color: #aab6da; background: rgba(255, 255, 255, .08); }
.s-clear svg { width: 16px; height: 16px; }
.s-clear:hover { color: #fff; background: rgba(255, 72, 196, .22); }

.chips { display: flex; flex-wrap: wrap; gap: 9px; }
.chip { border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit; background: rgba(255, 255, 255, .05); color: #cdd6f4; font-size: 13px; padding: 7px 16px; border-radius: 999px; transition: .22s; }
.chip:hover { color: #fff; border-color: var(--cyan); }
.chip.on { color: #04121f; font-weight: 600; border-color: transparent; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 6px 16px rgba(138, 92, 255, .35); }

.sort { display: flex; align-items: center; gap: 8px; }
.sort-label { font-size: 12.5px; color: #9fb0d8; letter-spacing: 1px; margin-right: 2px; }
.sort-btn { border: 1px solid rgba(255, 255, 255, .14); cursor: pointer; font-family: inherit; background: transparent; color: #cdd6f4; font-size: 12.5px; padding: 6px 14px; border-radius: 10px; transition: .22s; }
.sort-btn:hover { color: #fff; border-color: var(--cyan); }
.sort-btn.on { color: #eef2ff; border-color: var(--cyan); background: rgba(45, 226, 230, .12); }

.result-count { max-width: 980px; margin: 0 auto 12px; font-size: 12.5px; color: #9fb0d8; letter-spacing: .5px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(224px, 1fr)); gap: 18px; max-width: 980px; margin: 0 auto; }

.state { text-align: center; color: #9fb0d8; padding: 50px 0; max-width: 980px; margin: 0 auto; }
.state.err { color: #ff8aa8; }

/* 窄屏适配 */
@media (max-width: 720px) {
  .overview { grid-template-columns: 1fr 1fr; }
  .ov-tags { grid-column: 1 / -1; }
  .ov-card { border-right: 0; }
}
</style>
