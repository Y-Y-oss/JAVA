<script setup>
import { ref, inject, onMounted, computed } from 'vue'
import { fetchArchives, getArchive, searchArchives } from '../api/home'

// 由 App.vue 通过 provide 注入：登录用户、退出登录、全局提示
const user = inject('appUser')
const onLogout = inject('appLogout')
const notify = inject('appNotify')

/* ===== 导航栏 ===== */
const navItems = [
  { key: 'home', label: '首页', icon: 'M3 11l9-8 9 8M5 10v10h5v-6h4v6h5V10' },
  { key: 'timeline', label: '时间线', icon: 'M4 6h16M4 12h16M4 18h10' },
  { key: 'album', label: '相册', icon: 'M4 5h16v14H4zM4 15l4-4 4 4 4-5 4 5' },
  { key: 'community', label: '社区', icon: 'M16 11a4 4 0 1 0-8 0M3 21v-2a5 5 0 0 1 10 0v2M14 21v-2a5 5 0 0 1 7 0v2' }
]
const activeNav = ref('home')

/* ===== 记忆卡片：对接真实后端 /api/archives ===== */
const archives = ref([])
const loadingMemories = ref(false)
const memoriesError = ref('')

// 封面渐变色按标签取一个固定配色，保持视觉统一
const TAG_COLORS = {
  私语: 'linear-gradient(135deg,#2de2e6,#8a5cff)',
  信件: 'linear-gradient(135deg,#ff48c4,#8a5cff)',
  告白: 'linear-gradient(135deg,#7af5f7,#2de2e6)',
  约定: 'linear-gradient(135deg,#8a5cff,#ff48c4)'
}
const coverColor = (tag) => TAG_COLORS[tag] || 'linear-gradient(135deg,#2de2e6,#ff48c4)'

// 每个标签对应一个主题图标：避免封面只是纯色块，增加「记忆照片」的质感
const TAG_ICONS = {
  私语: 'M4 5h16a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H10l-5 4v-4H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z',
  信件: 'M3 6h18a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1z M3 7l9 6 9-6',
  告白: 'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z',
  约定: 'M12 2l2.9 6.3 6.9.7-5.1 4.7 1.4 6.8L12 17.8 5.9 20.5l1.4-6.8L2.2 9.7l6.9-.7z'
}
// 默认（时光）用相机图标
const DEFAULT_ICON = 'M4 7h3l2-2h6l2 2h3a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z M12 17a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z'
const coverIcon = (tag) => TAG_ICONS[tag] || DEFAULT_ICON

// 每条档案的封面照片：按 id 对应 public/img/archives/{id}.png（AI 生成的电影感主题图）
const ARCHIVE_COVER = {
  1: '/img/archives/1.png',
  2: '/img/archives/2.png',
  3: '/img/archives/3.png',
  4: '/img/archives/4.png',
  5: '/img/archives/5.png',
  6: '/img/archives/6.png'
}
// 封面样式：有照片 → 照片 + 底部暗化渐变（保证标签文字清晰）；无照片 → 回退渐变色
function coverStyle(m) {
  const url = ARCHIVE_COVER[m && m.id]
  if (url) {
    return {
      backgroundImage: `linear-gradient(180deg, rgba(10,14,39,.10) 0%, rgba(10,14,39,.70) 100%), url("${url}")`,
      backgroundPosition: 'center'
    }
  }
  return { background: coverColor((m && m.tag) || '') }
}

async function loadArchives() {
  loadingMemories.value = true
  memoriesError.value = ''
  try {
    // 真实接口：我的档案列表（需登录，request 层自动带 Authorization 头）
    const res = await fetchArchives(1, 8)
    archives.value = (res.data && res.data.records) || []
  } catch (err) {
    memoriesError.value = '档案加载失败：' + (err.message || '后端未连接')
  } finally {
    loadingMemories.value = false
  }
}

/* ===== 搜索栏：调用真实后端 /api/archives/search =====
 * 后端按 标题/内容/标签/时光节点 模糊匹配当前用户自己的档案，返回分页结构。
 * 这里不再做客户端过滤，关键词交由后端处理，保证与数据库一致。 */
const keyword = ref('')
const searching = ref(false)
const searchTip = ref('')
const searchResults = ref([])   // 搜索结果（后端返回）
const isSearching = ref(false)  // 当前是否处于「搜索态」

// 当前展示列表：搜索态显示搜索结果，否则显示「我的档案」首页展示
const displayList = computed(() => (isSearching.value ? searchResults.value : archives.value))

async function onSearch() {
  const q = keyword.value.trim()
  if (!q) {
    // 关键词清空 → 退出搜索态，回到「我的档案」首页展示
    isSearching.value = false
    searchResults.value = []
    searchTip.value = archives.value.length ? '' : '还没有档案，先去记录一段时光吧'
    return
  }
  isSearching.value = true
  searching.value = true
  searchTip.value = ''
  try {
    // 真实接口：我的档案搜索（需登录）
    const res = await searchArchives(q, 1, 50)
    searchResults.value = (res.data && res.data.records) || []
    const n = searchResults.value.length
    searchTip.value = n ? `为你找到 ${n} 段相关时光` : '没有匹配的档案'
  } catch (err) {
    searchResults.value = []
    searchTip.value = '搜索失败：' + (err.message || '后端未连接')
  } finally {
    searching.value = false
  }
}

// 点热门标签 → 直接以该标签为关键词搜索
const quickTags = ['私语', '信件', '告白', '约定']
function onTag(tag) {
  keyword.value = tag
  onSearch()
}

// 清除搜索 → 回到「我的档案」
function clearSearch() {
  keyword.value = ''
  onSearch()
}

/* 关键词高亮（仅对后端返回、自己可控的内容做 HTML 转义后包裹 <mark>） */
function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}
function highlight(text) {
  const safe = escapeHtml(text)
  const q = keyword.value.trim()
  if (!q || !safe) return safe
  const ql = q.toLowerCase()
  const lower = safe.toLowerCase()
  let out = ''
  let i = 0
  while (i <= lower.length) {
    const idx = lower.indexOf(ql, i)
    if (idx === -1) { out += safe.slice(i); break }
    out += safe.slice(i, idx) + '<mark>' + safe.slice(idx, idx + q.length) + '</mark>'
    i = idx + q.length
  }
  return out
}

// 内容摘要（卡片上展示前 44 字）
function excerpt(m) {
  const c = m && m.content ? String(m.content) : ''
  return c.length > 44 ? c.slice(0, 44) + '…' : c
}

onMounted(loadArchives)

/* ===== 档案详情：点击卡片 → GET /api/archives/{id} 拉取完整档案 ===== */
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
    // 真实接口：档案详情（需登录，request 层自动带 Authorization 头）
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

// 可见性文案：0=仅自己 1=公开到档案墙
const visibilityText = (v) => (v === 1 ? '公开 · 档案墙' : '仅自己可见')

/* 用户首字母，用于头像 */
const initial = () =>
  (user && (user.value?.nickname || user.value?.username || '?'))?.slice(0, 1).toUpperCase()
</script>

<template>
  <div class="home">
    <!-- 顶部 Hero 背景照片（模糊+压暗，与卡片照片呼应） -->
    <div class="hero-bg" aria-hidden="true"></div>

    <!-- ===== 导航栏 ===== -->
    <header class="navbar">
      <div class="nav-inner">
        <div class="brand">
          <svg class="logo" viewBox="0 0 64 64" fill="none">
            <circle cx="32" cy="32" r="30" stroke="#2de2e6" stroke-width="2.5" />
            <circle cx="32" cy="32" r="14" fill="#0a0e27" stroke="#ff48c4" stroke-width="2.5" />
            <circle cx="32" cy="32" r="6" fill="#7af5f7" />
            <path d="M32 2v10M32 52v10M2 32h10M52 32h10" stroke="#2de2e6" stroke-width="2.5" stroke-linecap="round" />
          </svg>
          <div class="brand-text">
            <span class="b-cn">时光代理人</span>
            <span class="b-en">Link Click</span>
          </div>
        </div>

        <nav class="nav-links">
          <button
            v-for="item in navItems"
            :key="item.key"
            class="nav-link"
            :class="{ active: activeNav === item.key }"
            @click="activeNav = item.key"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path :d="item.icon" />
            </svg>
            <span>{{ item.label }}</span>
          </button>
        </nav>

        <div class="nav-user">
          <div class="avatar" :title="user?.nickname || user?.username">{{ initial() }}</div>
          <div class="u-meta">
            <span class="u-name">{{ user?.nickname || user?.username }}</span>
            <span class="u-role">{{ user?.role === 'admin' ? '管理员' : '时光代理人' }}</span>
          </div>
          <button class="logout-btn" @click="onLogout" title="退出登录">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9" />
            </svg>
          </button>
        </div>
      </div>
    </header>

    <!-- ===== 主体：搜索栏 Hero ===== -->
    <main class="content">
      <section class="hero">
        <h1 class="hero-title">欢迎回来，{{ user?.nickname || user?.username }}</h1>
        <p class="hero-sub">在时光的长河里，找回每一帧被珍藏的瞬间。</p>

        <form class="searchbar" @submit.prevent="onSearch">
          <svg class="s-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" />
          </svg>
          <input
            v-model="keyword"
            type="text"
            class="s-input"
            placeholder="搜索照片、记忆、时间线…"
            @keyup.enter="onSearch"
          />
          <button
            v-if="keyword"
            type="button"
            class="s-clear"
            title="清除"
            aria-label="清除"
            @click="clearSearch"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
          <button type="submit" class="s-btn" :disabled="searching">
            <svg class="s-btn-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" />
            </svg>
            <span>{{ searching ? '搜索中…' : '搜索' }}</span>
          </button>
        </form>

        <!-- 热门标签快捷筛选 -->
        <div class="quick-tags">
          <span class="qt-label">热门标签</span>
          <button
            v-for="t in quickTags"
            :key="t"
            type="button"
            class="qt"
            :class="{ on: keyword === t }"
            @click="onTag(t)"
          >#{{ t }}</button>
        </div>

        <p class="search-tip" v-if="searchTip && !searching">
          <span class="tip-pill">{{ searchTip }}</span>
        </p>
      </section>

      <!-- ===== 记忆卡片区（真实后端数据：/api/archives 或 /api/archives/search） ===== -->
      <section class="memories">
        <div class="sec-head">
          <div class="sec-title">
            <h2>{{ isSearching ? '搜索结果' : '最近记忆' }}</h2>
            <span class="sec-sub">TIME ARCHIVES</span>
          </div>
          <div class="sec-actions">
            <span v-if="isSearching && !searching && searchResults.length" class="count-pill">{{ searchResults.length }} 段时光</span>
            <button v-if="isSearching" type="button" class="clear-search" @click="clearSearch">清除搜索</button>
          </div>
        </div>

        <!-- 骨架屏（加载中） -->
        <div v-if="loadingMemories || (isSearching && searching)" class="skeleton-grid">
          <div class="sk-card" v-for="n in 8" :key="n">
            <div class="sk-cover shimmer"></div>
            <div class="sk-line w70 shimmer"></div>
            <div class="sk-line w45 shimmer"></div>
          </div>
        </div>

        <div class="cards-loading err" v-else-if="memoriesError">{{ memoriesError }}</div>

        <!-- 空状态 -->
        <div class="cards-loading empty" v-else-if="!displayList.length">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" /><path d="M8 11h6" />
          </svg>
          <p>{{ isSearching ? '没有匹配的档案，换个关键词试试' : '还没有档案，去记录属于你的时光吧' }}</p>
        </div>

        <!-- 卡片网格 -->
        <div class="cards" v-else>
          <article
            v-for="(m, idx) in displayList"
            :key="m.id"
            class="card"
            :style="{ animationDelay: (idx * 45) + 'ms' }"
            @click="openDetail(m)"
          >
            <div class="card-cover" :style="coverStyle(m)">
              <span class="card-tag">{{ m.tag || '时光' }}</span>
              <span v-if="m.visibility === 1" class="card-vis">公开</span>
              <span v-else-if="m.visibility === 0" class="card-vis private">私有</span>
              <span class="card-go">查看 →</span>
            </div>
            <div class="card-body">
              <h3 class="card-title" v-html="highlight(m.title)"></h3>
              <p class="card-excerpt" v-html="highlight(excerpt(m))"></p>
              <span class="card-date">{{ m.archiveDate || '—' }}</span>
            </div>
          </article>
        </div>
      </section>
    </main>

    <!-- ===== 档案详情弹层 ===== -->
    <transition name="pop">
      <div v-if="detailOpen" class="detail-mask" @click.self="closeDetail">
        <div class="detail-panel">
          <button class="detail-close" @click="closeDetail" aria-label="关闭">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>

          <div v-if="detailLoading" class="detail-state">载入中…</div>
          <div v-else-if="detailError" class="detail-state err">{{ detailError }}</div>

          <template v-else-if="detail">
            <div class="detail-cover" :style="coverStyle(detail)">
              <span class="detail-tag">{{ detail.tag || '时光' }}</span>
              <span class="detail-vis">{{ visibilityText(detail.visibility) }}</span>
            </div>
            <div class="detail-body">
              <h2 class="detail-title">{{ detail.title }}</h2>
              <div class="detail-meta">
                <span><i>记录日期</i>{{ detail.archiveDate || '—' }}</span>
                <span><i>创建于</i>{{ detail.createTime || '—' }}</span>
                <span v-if="detail.updateTime"><i>更新于</i>{{ detail.updateTime }}</span>
              </div>
              <div class="detail-content">{{ detail.content || '（这段时光还没有写下文字）' }}</div>
            </div>
          </template>
        </div>
      </div>
    </transition>
  </div>
</template>

<style scoped>
.home {
  position: relative;
  z-index: 2;
  height: 100%;
  overflow-y: auto;
  color: #eef2ff;
}

/* ===== 导航栏 ===== */
.navbar {
  position: sticky;
  top: 0;
  z-index: 5;
  backdrop-filter: blur(18px) saturate(150%);
  -webkit-backdrop-filter: blur(18px) saturate(150%);
  background: linear-gradient(180deg, rgba(10, 14, 39, .82), rgba(10, 14, 39, .42));
  border-bottom: 1px solid rgba(255, 255, 255, .12);
  box-shadow: 0 8px 30px rgba(0, 0, 0, .35);
}
.nav-inner {
  max-width: 1180px;
  margin: 0 auto;
  height: 66px;
  padding: 0 22px;
  display: flex;
  align-items: center;
  gap: 22px;
}
.brand { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.logo { width: 38px; height: 38px; filter: drop-shadow(0 4px 12px rgba(45, 226, 230, .5)); }
.brand-text { display: flex; flex-direction: column; line-height: 1.1; }
.b-cn {
  font-size: 16px; font-weight: 600; letter-spacing: 2px;
  background: linear-gradient(90deg, var(--cyan), #fff 45%, var(--magenta));
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.b-en { font-size: 10px; letter-spacing: 3px; color: #9fb0d8; text-transform: uppercase; }

.nav-links { display: flex; gap: 6px; margin: 0 auto; }
.nav-link {
  display: flex; align-items: center; gap: 7px;
  padding: 9px 16px; border: 0; cursor: pointer; font-family: inherit;
  background: transparent; color: #aab6da; font-size: 14px;
  border-radius: 12px; transition: .25s;
}
.nav-link svg { width: 17px; height: 17px; }
.nav-link:hover { color: #fff; background: rgba(255, 255, 255, .06); }
.nav-link.active {
  color: #04121f; font-weight: 600;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 18px rgba(45, 226, 230, .4);
}

.nav-user { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.avatar {
  width: 38px; height: 38px; border-radius: 50%; display: grid; place-items: center;
  font-size: 16px; font-weight: 600; color: #04121f;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 18px rgba(45, 226, 230, .4); user-select: none;
}
.u-meta { display: flex; flex-direction: column; line-height: 1.2; }
.u-name { font-size: 13.5px; font-weight: 600; color: #eef2ff; }
.u-role { font-size: 11px; color: var(--cyan-soft); }
.logout-btn {
  width: 36px; height: 36px; border-radius: 10px; cursor: pointer;
  display: grid; place-items: center; margin-left: 4px;
  background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .16);
  color: #aab6da; transition: .25s;
}
.logout-btn svg { width: 18px; height: 18px; }
.logout-btn:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 14px rgba(255, 72, 196, .4); }

/* 顶部 Hero 背景照片 */
.hero-bg {
  position: absolute; top: 0; left: 0; right: 0; height: 620px; z-index: 0;
  background: url('/img/archives/3.png') center 30% / cover no-repeat;
  filter: blur(8px) brightness(.38) saturate(1.1);
  opacity: .85;
  -webkit-mask-image: linear-gradient(180deg, #000 55%, transparent);
  mask-image: linear-gradient(180deg, #000 55%, transparent);
  pointer-events: none;
}

/* ===== 主体 ===== */
.content { position: relative; z-index: 1; max-width: 1180px; margin: 0 auto; padding: 40px 22px 60px; }

.hero { text-align: center; padding: 36px 0 14px; }
.hero-title {
  font-size: 32px; font-weight: 600; letter-spacing: 2px; margin-bottom: 10px;
  background: linear-gradient(90deg, #fff, var(--cyan-soft) 50%, var(--magenta));
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.hero-sub { color: #9fb0d8; font-size: 14px; margin-bottom: 28px; }

/* 搜索栏 */
.searchbar {
  display: flex; align-items: center; gap: 8px;
  max-width: 640px; margin: 0 auto;
  padding: 7px 7px 7px 18px;
  border-radius: 16px;
  background: linear-gradient(180deg, rgba(255, 255, 255, .1), rgba(255, 255, 255, .04));
  border: 1px solid rgba(255, 255, 255, .18);
  box-shadow: 0 18px 50px rgba(0, 0, 0, .4), 0 0 0 0 rgba(45, 226, 230, 0);
  transition: .3s;
}
.searchbar:focus-within {
  border-color: var(--cyan);
  box-shadow: 0 18px 50px rgba(0, 0, 0, .4), 0 0 0 3px rgba(45, 226, 230, .22), 0 0 24px rgba(45, 226, 230, .25);
}
.s-ic { width: 22px; height: 22px; color: var(--cyan-soft); flex-shrink: 0; }
.s-input {
  flex: 1; background: transparent; border: 0; outline: none; min-width: 0;
  color: #fff; font-size: 15px; font-family: inherit; padding: 12px 0;
}
.s-input::placeholder { color: #8b97bd; }
.s-clear {
  width: 30px; height: 30px; flex-shrink: 0; border: 0; cursor: pointer; border-radius: 9px;
  display: grid; place-items: center; color: #aab6da;
  background: rgba(255, 255, 255, .08); transition: .2s;
}
.s-clear svg { width: 16px; height: 16px; }
.s-clear:hover { color: #fff; background: rgba(255, 72, 196, .22); }
.s-btn {
  display: inline-flex; align-items: center; gap: 7px;
  border: 0; cursor: pointer; font-family: inherit; white-space: nowrap;
  padding: 11px 22px; border-radius: 11px; font-size: 14.5px; font-weight: 600; color: #04121f;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  background-size: 200% 100%; transition: .4s; letter-spacing: 2px;
  box-shadow: 0 10px 26px rgba(138, 92, 255, .4);
}
.s-btn-ic { width: 17px; height: 17px; }
.s-btn:hover:not(:disabled) { background-position: 100% 0; transform: translateY(-1px); }
.s-btn:disabled { opacity: .7; cursor: not-allowed; }

/* 热门标签 */
.quick-tags { margin: 16px auto 0; max-width: 640px; display: flex; align-items: center; gap: 9px; flex-wrap: wrap; justify-content: center; }
.qt-label { font-size: 12px; color: #7e8ab0; letter-spacing: 1px; }
.qt {
  border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit;
  background: rgba(255, 255, 255, .05); color: #cdd6f4; font-size: 13px;
  padding: 6px 14px; border-radius: 999px; transition: .22s;
}
.qt:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .28); }
.qt.on {
  color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 16px rgba(138, 92, 255, .35);
}

.search-tip { margin-top: 16px; font-size: 13px; color: #9fb0d8; text-align: center; }
.tip-pill {
  display: inline-block; padding: 7px 18px; border-radius: 999px;
  background: rgba(45, 226, 230, .1); border: 1px solid rgba(45, 226, 230, .28);
  color: var(--cyan-soft); font-size: 13px;
}

/* 记忆卡片 */
.memories { margin-top: 50px; }
.sec-head { display: flex; align-items: center; gap: 12px; margin-bottom: 22px; }
.sec-title { display: flex; align-items: baseline; gap: 12px; }
.sec-title h2 { font-size: 20px; font-weight: 600; letter-spacing: 1px; position: relative; padding-left: 14px; }
.sec-title h2::before {
  content: ""; position: absolute; left: 0; top: 50%; transform: translateY(-50%);
  width: 5px; height: 18px; border-radius: 3px;
  background: linear-gradient(180deg, var(--cyan), var(--magenta));
}
.sec-sub { font-size: 11px; letter-spacing: 3px; color: #7e8ab0; }
.sec-actions { margin-left: auto; display: flex; align-items: center; gap: 12px; }
.count-pill {
  font-size: 12px; padding: 5px 13px; border-radius: 999px;
  background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .14);
  color: #cdd6f4;
}
.clear-search {
  border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit;
  background: transparent; color: #aab6da; font-size: 12.5px;
  padding: 6px 14px; border-radius: 999px; transition: .22s;
}
.clear-search:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 12px rgba(255, 72, 196, .3); }

.cards {
  display: grid; grid-template-columns: repeat(auto-fill, minmax(224px, 1fr)); gap: 18px;
}
.card {
  position: relative;
  border-radius: 16px; overflow: hidden; cursor: pointer;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .6));
  border: 1px solid rgba(255, 255, 255, .14);
  box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
  transition: transform .3s, border-color .3s, box-shadow .3s;
  animation: memoIn .45s cubic-bezier(.2, .8, .2, 1) both;
}
.card:hover {
  transform: translateY(-6px);
  border-color: var(--cyan);
  box-shadow: 0 22px 52px rgba(45, 226, 230, .3);
}
.card-cover { position: relative; height: 128px; overflow: hidden; background: #0a0e27; background-size: cover; background-repeat: no-repeat; transition: background-size .55s ease; }
/* 顶部柔光，让照片更有电影质感 */
.card-cover::after {
  content: ""; position: absolute; inset: 0; z-index: 1; pointer-events: none;
  background: radial-gradient(circle at 80% 12%, rgba(255, 255, 255, .18), transparent 55%);
  mix-blend-mode: screen;
}
/* 悬停时照片轻微放大，强化「记忆照片」质感 */
.card:hover .card-cover { background-size: 116% 116%; }
.card-tag {
  position: absolute; left: 12px; bottom: 12px; z-index: 2;
  font-size: 11px; padding: 3px 12px; border-radius: 999px;
  background: rgba(10, 14, 39, .55); color: #eef2ff; border: 1px solid rgba(255, 255, 255, .3);
  backdrop-filter: blur(4px);
}
.card-vis {
  position: absolute; right: 12px; top: 12px; z-index: 2;
  font-size: 10.5px; padding: 3px 10px; border-radius: 999px;
  background: rgba(45, 226, 230, .9); color: #04121f; font-weight: 600;
}
.card-vis.private { background: rgba(10, 14, 39, .6); color: #cdd6f4; border: 1px solid rgba(255, 255, 255, .25); }
.card-go {
  position: absolute; right: 12px; bottom: 12px; z-index: 2;
  font-size: 12px; color: #fff; font-weight: 600; letter-spacing: 1px;
  opacity: 0; transform: translateX(-6px); transition: .28s;
}
.card:hover .card-go { opacity: 1; transform: translateX(0); }
.card-body { padding: 14px 14px 16px; display: flex; flex-direction: column; gap: 7px; }
.card-title { font-size: 15px; font-weight: 600; color: #eef2ff; line-height: 1.35; }
.card-title :deep(mark), .card-excerpt :deep(mark) {
  background: linear-gradient(180deg, rgba(255, 72, 196, .35), rgba(45, 226, 230, .35));
  color: #fff; padding: 0 2px; border-radius: 3px;
}
.card-excerpt {
  font-size: 12.5px; line-height: 1.6; color: #9fb0d8;
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.card-date { font-size: 12px; color: #7e8ab0; }

/* 骨架屏 */
.skeleton-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(224px, 1fr)); gap: 18px; }
.sk-card {
  border-radius: 16px; overflow: hidden; padding: 0;
  background: linear-gradient(160deg, rgba(18, 22, 52, .55), rgba(12, 14, 38, .5));
  border: 1px solid rgba(255, 255, 255, .1);
}
.sk-cover { height: 128px; }
.sk-card { padding: 14px; }
.sk-cover { margin: -14px -14px 12px; }
.sk-line { height: 12px; border-radius: 6px; margin-top: 9px; }
.sk-line.w70 { width: 70%; }
.sk-line.w45 { width: 45%; }
.shimmer {
  background: linear-gradient(100deg, rgba(255, 255, 255, .04) 30%, rgba(255, 255, 255, .14) 50%, rgba(255, 255, 255, .04) 70%);
  background-size: 220% 100%;
  animation: shimmer 1.3s ease-in-out infinite;
}
@keyframes shimmer { 0% { background-position: 180% 0; } 100% { background-position: -40% 0; } }

.cards-loading { color: #9fb0d8; text-align: center; padding: 40px 20px; }
.cards-loading.err { color: #ff8aa8; }
.cards-loading.empty { display: flex; flex-direction: column; align-items: center; gap: 14px; }
.cards-loading.empty svg { width: 46px; height: 46px; opacity: .5; color: var(--cyan-soft); }
.cards-loading.empty p { font-size: 14px; }

/* ===== 档案详情弹层 ===== */
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

@keyframes memoIn { from { opacity: 0; transform: translateY(18px) scale(.97); } to { opacity: 1; transform: none; } }
@keyframes pop {
  from { opacity: 0; transform: translateY(14px) scale(.97); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}
.pop-enter-active, .pop-leave-active { transition: opacity .26s ease; }
.pop-enter-from, .pop-leave-to { opacity: 0; }

@media (max-width: 720px) {
  .nav-links { display: none; }
  .u-meta { display: none; }
  .hero-title { font-size: 25px; }
}
</style>
