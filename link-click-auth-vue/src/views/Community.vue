<script setup>
import { ref, onMounted, inject, computed } from 'vue'
import NavBar from '../components/NavBar.vue'
import ArchiveCard from '../components/ArchiveCard.vue'
import ArchiveDetail from '../components/ArchiveDetail.vue'
import ArchiveForm from '../components/ArchiveForm.vue'
import { fetchPublicArchives, getArchive, updateArchive, deleteArchive } from '../api/home'
import { KNOWN_TAGS, coverStyle } from '../utils/archiveStyle'

const notify = inject('appNotify')

// ===== B 站 · 时光代理人 相关视频 =====
// 官方番剧与影像入口，点击在新标签页打开哔哩哔哩观看（链接均为 B 站真实地址）。
const biliVideos = [
  {
    title: '时光代理人 · 官方番剧总览',
    desc: '第一季 / 第二季 / 英都篇 / 第三季 全集',
    cover: '/img/gallery/g1.png',
    url: 'https://www.bilibili.com/bangumi/media/md28230742/',
    tag: '番剧总览'
  },
  {
    title: '时光代理人 第一季',
    desc: '2021 · 全12话 · 9.8 分',
    cover: '/img/gallery/g2.png',
    url: 'https://bilibili.com/bangumi/play/ep411221',
    tag: '第一季'
  },
  {
    title: '时光代理人 第三季',
    desc: '2026 · 英都新篇章 · 更新中',
    cover: '/img/gallery/g3.png',
    url: 'https://www.bilibili.com/bangumi/play/ss105212',
    tag: '第三季'
  },
  {
    title: '更多二创 · 混剪 · 反应视频',
    desc: '去 B 站搜「时光代理人」看全站相关',
    cover: '/img/gallery/g4.png',
    url: 'https://search.bilibili.com/all?keyword=时光代理人',
    tag: '社区二创'
  }
]

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

      <!-- B 站 · 时光代理人 视频板块 -->
      <section class="bili">
        <div class="bili-head">
          <span class="bili-badge">bilibili</span>
          <div class="bili-hd-text">
            <h2 class="bili-title">B 站 · 时光代理人</h2>
            <p class="bili-sub">官方番剧与相关影像，点击直达哔哩哔哩观看</p>
          </div>
        </div>
        <div class="bili-grid">
          <a
            v-for="v in biliVideos"
            :key="v.url"
            class="bili-card"
            :href="v.url"
            target="_blank"
            rel="noopener noreferrer"
          >
            <div class="bili-cover" :style="{ backgroundImage: `url('${v.cover}')` }">
              <span class="bili-play">
                <svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z" /></svg>
              </span>
              <span class="bili-tag">{{ v.tag }}</span>
            </div>
            <div class="bili-info">
              <h3 class="bili-name">{{ v.title }}</h3>
              <p class="bili-desc">{{ v.desc }}</p>
            </div>
          </a>
        </div>
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
            @open="openDetail"
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
  display: grid; grid-template-columns: 150px 150px 1fr; gap: 16px; align-items: stretch;
  max-width: 980px; margin: 0 auto 26px; padding: 18px 20px;
  border-radius: 18px; background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62));
  border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 14px 36px rgba(0, 0, 0, .4);
}
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

/* ===== B 站 视频 ===== */
.bili { max-width: 980px; margin: 0 auto 34px; }
.bili-head { display: flex; align-items: center; gap: 14px; margin-bottom: 18px; }
.bili-badge { flex-shrink: 0; font-size: 13px; font-weight: 700; letter-spacing: .5px; color: #fff;
  background: #fb7299; padding: 7px 12px; border-radius: 10px; box-shadow: 0 8px 20px rgba(251, 114, 153, .42); }
.bili-title { font-size: 20px; font-weight: 600; letter-spacing: 1px; color: #eef2ff; }
.bili-sub { font-size: 13px; color: #9fb0d8; margin-top: 3px; }
.bili-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 16px; }
.bili-card { display: block; text-decoration: none; color: inherit; position: relative; border-radius: 16px; overflow: hidden;
  background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .62)); border: 1px solid rgba(255, 255, 255, .14);
  box-shadow: 0 14px 36px rgba(0, 0, 0, .4); transition: transform .3s, border-color .3s, box-shadow .3s; }
.bili-card:hover { transform: translateY(-6px); border-color: #fb7299; box-shadow: 0 22px 52px rgba(251, 114, 153, .32); }
.bili-cover { position: relative; height: 132px; background-size: cover; background-position: center; background-color: #0a0e27; }
.bili-cover::after { content: ""; position: absolute; inset: 0; background: linear-gradient(180deg, rgba(10, 14, 39, .1) 0%, rgba(10, 14, 39, .72) 100%); }
.bili-play { position: absolute; inset: 0; margin: auto; width: 46px; height: 46px; z-index: 2; display: grid; place-items: center; border-radius: 50%; color: #fff;
  background: rgba(251, 114, 153, .92); box-shadow: 0 6px 18px rgba(0, 0, 0, .4); transition: transform .3s; }
.bili-card:hover .bili-play { transform: scale(1.1); }
.bili-play svg { width: 22px; height: 22px; margin-left: 2px; }
.bili-tag { position: absolute; left: 10px; bottom: 10px; z-index: 2; font-size: 11px; padding: 3px 10px; border-radius: 999px; color: #fff;
  background: rgba(10, 14, 39, .6); border: 1px solid rgba(255, 255, 255, .28); backdrop-filter: blur(4px); }
.bili-info { padding: 12px 13px 14px; }
.bili-name { font-size: 14.5px; font-weight: 600; color: #eef2ff; line-height: 1.35; }
.bili-desc { font-size: 12px; color: #9fb0d8; margin-top: 5px; line-height: 1.5; }

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
