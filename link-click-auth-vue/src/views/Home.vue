<script setup>
import { ref, inject, onMounted, onBeforeUnmount, computed } from 'vue'
import NavBar from '../components/NavBar.vue'
import ArchiveCard from '../components/ArchiveCard.vue'
import ArchiveDetail from '../components/ArchiveDetail.vue'
import ArchiveForm from '../components/ArchiveForm.vue'
import {
  fetchArchives, getArchive, searchArchives,
  createArchive, updateArchive, deleteArchive
} from '../api/home'
import { coverStyle, hasCover, coverUrl, KNOWN_TAGS } from '../utils/archiveStyle'

// 由 App.vue 通过 provide 注入：登录用户、退出登录、全局提示
const user = inject('appUser')
const onLogout = inject('appLogout')
const notify = inject('appNotify')

/* ===== 全部档案 ===== */
const archives = ref([])
const loadingMemories = ref(false)
const memoriesError = ref('')

async function loadArchives() {
  loadingMemories.value = true
  memoriesError.value = ''
  try {
    const res = await fetchArchives(1, 50)
    archives.value = (res.data && res.data.records) || []
  } catch (err) {
    memoriesError.value = '档案加载失败：' + (err.message || '后端未连接')
  } finally {
    loadingMemories.value = false
  }
}

/* ===== 搜索栏 ===== */
const keyword = ref('')
const searching = ref(false)
const searchTip = ref('')
const searchResults = ref([])
const isSearching = ref(false)
const displayList = computed(() => (isSearching.value ? searchResults.value : archives.value))

async function onSearch() {
  const q = keyword.value.trim()
  if (!q) {
    isSearching.value = false
    searchResults.value = []
    searchTip.value = ''
    return
  }
  isSearching.value = true
  searching.value = true
  searchTip.value = ''
  try {
    const res = await searchArchives(q, 1, 50)
    searchResults.value = (res.data && res.data.records) || []
    searchTip.value = searchResults.value.length
      ? `为你找到 ${searchResults.value.length} 段相关时光`
      : '没有匹配的档案'
  } catch (err) {
    searchResults.value = []
    searchTip.value = '搜索失败：' + (err.message || '后端未连接')
  } finally {
    searching.value = false
  }
}

const quickTags = ['私语', '信件', '告白', '约定']
function onTag(t) {
  keyword.value = t
  onSearch()
}
function clearSearch() {
  keyword.value = ''
  onSearch()
}

/* ===== 数据看板 ===== */
const now = new Date()
const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
const todayMD = `${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`

const stats = computed(() => {
  const list = archives.value
  const tags = new Set(list.map((a) => a.tag).filter(Boolean))
  const pub = list.filter((a) => a.visibility === 1).length
  const mon = list.filter((a) => (a.archiveDate || '').startsWith(monthKey)).length
  return [
    { val: list.length, lab: '时光档案', c: 'var(--cyan)' },
    { val: tags.size, lab: '标签种类', c: 'var(--magenta)' },
    { val: pub, lab: '公开分享', c: 'var(--purple)' },
    { val: mon, lab: '本月新增', c: 'var(--cyan-soft)' }
  ]
})

/* ===== 历史上的今天 ===== */
const onThisDay = computed(() =>
  archives.value.filter((a) => {
    const d = a.archiveDate || ''
    return d.length >= 10 && d.slice(5, 10) === todayMD
  })
)

/* ===== 精选轮播 ===== */
const featured = computed(() => {
  const withPhoto = archives.value.filter((a) => hasCover(a))
  const rest = archives.value.filter((a) => !hasCover(a))
  return withPhoto.concat(rest).slice(0, 5)
})
const fIdx = ref(0)
let autoTimer = null
function startAuto() {
  stopAuto()
  if (featured.value.length > 1) {
    autoTimer = setInterval(() => {
      fIdx.value = (fIdx.value + 1) % featured.value.length
    }, 5000)
  }
}
function stopAuto() {
  if (autoTimer) { clearInterval(autoTimer); autoTimer = null }
}
function goF(i) {
  fIdx.value = (i + featured.value.length) % featured.value.length
}
const curFeatured = computed(() => featured.value[fIdx.value] || null)
const curPhoto = computed(() =>
  curFeatured.value && hasCover(curFeatured.value) ? coverUrl(curFeatured.value) : ''
)

/* ===== 时光胶片墙（借鉴 B 站滚动照片墙：双排反向无缝滚动） ===== */
// 胶片带 = 全部 gallery 素材（14 张风格统一，素材充足不重复）
const GALLERY_IMGS = Array.from({ length: 14 }, (_, i) => `/img/gallery/g${i + 1}.png`)
// 每条档案绑定的封面图（用于胶片墙点击时跳转对应档案；其余照片点开灯箱）
const ARCHIVE_TO_COVER = computed(() => {
  const m = {}
  for (const a of archives.value) {
    if (hasCover(a)) m[coverUrl(a)] = a
  }
  return m
})

// 基础胶片：14 张素材，每张都不同
const filmBase = computed(() =>
  GALLERY_IMGS.map((src) => {
    const arch = ARCHIVE_TO_COVER.value[src]
    return {
      src,
      cap: arch ? arch.title : '',
      id: arch ? arch.id : null
    }
  })
)
const filmRow1 = computed(() => {
  const b = filmBase.value
  return b.concat(b)
})
const filmRow2 = computed(() => {
  // 第二排从中间错位开始反向排列，避免与第一排同时出现同一张照片
  const b = filmBase.value
  const half = Math.floor(b.length / 2)
  const shifted = b.slice(half).concat(b.slice(0, half))
  return shifted.reverse().concat(shifted.slice().reverse())
})
function openFilm(item) {
  if (item.id != null) {
    const a = archives.value.find((x) => x.id === item.id)
    if (a) return openDetail(a)
  }
  openLightbox(item.src, item.cap)
}

/* ===== 灯箱预览 ===== */
const lbOpen = ref(false)
const lbSrc = ref('')
const lbCap = ref('')
function openLightbox(src, cap) {
  lbSrc.value = src
  lbCap.value = cap || ''
  lbOpen.value = true
}
function closeLightbox() {
  lbOpen.value = false
  lbSrc.value = ''
  lbCap.value = ''
}

/* ===== 分类区块 ===== */
const sections = computed(() =>
  KNOWN_TAGS
    .map((t) => ({ tag: t, items: archives.value.filter((a) => a.tag === t) }))
    .filter((s) => s.items.length)
)

/* ===== 瀑布流封面高低错落 ===== */
const MASONRY_H = [156, 200, 138, 184, 162, 214, 148, 196, 170, 206]
function masonryH(i) {
  return MASONRY_H[i % MASONRY_H.length]
}

/* ===== 详情 ===== */
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

/* ===== 新建 / 编辑 表单 ===== */
const formShow = ref(false)
const formInitial = ref(null)
function openCreate() {
  formInitial.value = null
  formShow.value = true
}
function openEdit(arch) {
  formInitial.value = arch
  formShow.value = true
}
async function onFormSaved(arch) {
  formShow.value = false
  notify('✓ ' + (formInitial.value ? '档案已更新' : '档案已封存进时光长廊'))
  await loadArchives()
  if (detailOpen.value && arch && detail.value && detail.value.id === arch.id) {
    detail.value = arch
  }
  formInitial.value = null
}
function onFormClose() {
  formShow.value = false
  formInitial.value = null
}

/* ===== 删除 ===== */
async function onDelete(arch) {
  try {
    await deleteArchive(arch.id)
    notify('✓ 档案已从时光长廊抹去')
    detailOpen.value = false
    await loadArchives()
  } catch (err) {
    notify('✗ ' + (err.message || '删除失败'))
  }
}

/* ===== 随机回忆 ===== */
function randomMemory() {
  if (!archives.value.length) return
  const i = Math.floor(Math.random() * archives.value.length)
  openDetail(archives.value[i])
}

onMounted(() => {
  loadArchives().then(() => startAuto())
})
onBeforeUnmount(stopAuto)
</script>

<template>
  <div class="home">
    <NavBar />

    <main class="content">
      <!-- Hero -->
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
          <button v-if="keyword" type="button" class="s-clear" title="清除" aria-label="清除" @click="clearSearch">
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

        <div class="quick-tags">
          <span class="qt-label">热门标签</span>
          <button v-for="t in quickTags" :key="t" type="button" class="qt" :class="{ on: keyword === t }" @click="onTag(t)">#{{ t }}</button>
        </div>

        <div class="actions">
          <button class="act primary" @click="openCreate">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round">
              <path d="M12 5v14M5 12h14" />
            </svg>
            记录时光
          </button>
          <button class="act" @click="randomMemory">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M16 3h5v5M21 3l-7 7M8 21H3v-5M3 21l7-7" />
            </svg>
            随机回忆
          </button>
        </div>

        <p class="search-tip" v-if="searchTip && !searching">
          <span class="tip-pill">{{ searchTip }}</span>
        </p>
      </section>

      <!-- 数据看板 -->
      <section class="stats" v-if="!loadingMemories && !memoriesError && archives.length">
        <div class="stat" v-for="s in stats" :key="s.lab" :style="{ '--c': s.c }">
          <div class="num">{{ s.val }}</div>
          <div class="lab">{{ s.lab }}</div>
        </div>
      </section>

      <!-- 时光胶片墙：双排反向无缝滚动 -->
      <section class="filmwall" v-if="!isSearching">
        <div class="sec-head">
          <div class="sec-title">
            <h2>时光胶片墙</h2>
            <span class="sec-sub">FILM WALL</span>
          </div>
          <span class="film-hint">▸ 悬停暂停 · 点击打开档案</span>
        </div>
        <div class="film-row">
          <div class="film-track t1">
            <figure v-for="(f, i) in filmRow1" :key="'r1' + i" class="film" @click="openFilm(f)">
              <img :src="f.src" :alt="f.cap || '时光' " loading="lazy" />
              <figcaption v-if="f.cap">{{ f.cap }}</figcaption>
            </figure>
          </div>
        </div>
        <div class="film-row">
          <div class="film-track t2">
            <figure v-for="(f, i) in filmRow2" :key="'r2' + i" class="film" @click="openFilm(f)">
              <img :src="f.src" :alt="f.cap || '时光' " loading="lazy" />
              <figcaption v-if="f.cap">{{ f.cap }}</figcaption>
            </figure>
          </div>
        </div>
      </section>

      <!-- 历史上的今天 -->
      <section class="otd" v-if="!isSearching && onThisDay.length">
        <div class="otd-head">
          <span class="otd-kicker">历史上的今天 · {{ todayMD }}</span>
          <span class="otd-more" @click="randomMemory">换一段 ↻</span>
        </div>
        <div class="otd-row">
          <article
            v-for="m in onThisDay"
            :key="m.id"
            class="otd-card"
            @click="openDetail(m)"
          >
            <div class="otd-cover" :style="coverStyle(m)"></div>
            <div class="otd-info">
              <h4>{{ m.title }}</h4>
              <span>{{ m.archiveDate }}</span>
            </div>
          </article>
        </div>
      </section>

      <!-- 精选记忆轮播 -->
      <section class="featured" v-if="!isSearching && featured.length">
        <div class="sec-head">
          <div class="sec-title">
            <h2>精选记忆</h2>
            <span class="sec-sub">FEATURED</span>
          </div>
          <span class="fc-count">{{ fIdx + 1 }} / {{ featured.length }}</span>
        </div>

        <div class="fc-stage" @mouseenter="stopAuto" @mouseleave="startAuto">
          <button class="fc-nav prev" @click="goF(fIdx - 1)" aria-label="上一张">‹</button>

          <div class="fc-card" v-if="curFeatured" :key="curFeatured.id" @click="openDetail(curFeatured)">
            <div class="fc-cover">
              <img v-if="curPhoto" class="fc-photo" :src="curPhoto" :alt="curFeatured.title" />
              <div v-else class="fc-illus" :style="{ background: coverStyle(curFeatured).background }"></div>
              <span class="fc-tag">{{ curFeatured.tag || '时光' }}</span>
              <span class="fc-vis" :class="{ pri: curFeatured.visibility !== 1 }">
                {{ curFeatured.visibility === 1 ? '公开' : '私有' }}
              </span>
            </div>
            <div class="fc-info">
              <span class="fc-kicker">EDITOR'S PICK</span>
              <h3 class="fc-title">{{ curFeatured.title }}</h3>
              <p class="fc-excerpt">{{ curFeatured.content || '（这段时光还没有写下文字）' }}</p>
              <div class="fc-meta">
                <span class="fc-date">{{ curFeatured.archiveDate || '—' }}</span>
                <span class="fc-go">查看完整记忆 →</span>
              </div>
            </div>
          </div>

          <button class="fc-nav next" @click="goF(fIdx + 1)" aria-label="下一张">›</button>
        </div>

        <div class="fc-dots">
          <button
            v-for="(f, i) in featured"
            :key="f.id"
            class="dot"
            :class="{ on: i === fIdx }"
            @click="goF(i)"
            :aria-label="'第' + (i + 1) + '张'"
          ></button>
        </div>
      </section>

      <!-- 分类区块 -->
      <section class="cats" v-if="!isSearching && sections.length">
        <div v-for="sec in sections" :key="sec.tag" class="cat-block">
          <div class="sec-head">
            <div class="sec-title">
              <h2>{{ sec.tag }}</h2>
              <span class="sec-sub">{{ sec.items.length }} 段</span>
            </div>
            <span class="cat-hint">← 左右滑动 →</span>
          </div>
          <div class="cat-row">
            <ArchiveCard
              v-for="(m, i) in sec.items"
              :key="m.id"
              :archive="m"
              :cover-h="150"
              @open="openDetail"
            />
          </div>
        </div>
      </section>

      <!-- 全部回忆 / 搜索结果（瀑布流） -->
      <section class="memories">
        <div class="sec-head">
          <div class="sec-title">
            <h2>{{ isSearching ? '搜索结果' : '全部回忆' }}</h2>
            <span class="sec-sub">{{ isSearching ? 'RESULTS' : 'TIME ARCHIVES' }}</span>
          </div>
          <div class="sec-actions">
            <span v-if="isSearching && !searching && searchResults.length" class="count-pill">{{ searchResults.length }} 段时光</span>
            <button v-if="isSearching" type="button" class="clear-search" @click="clearSearch">清除搜索</button>
          </div>
        </div>

        <div v-if="loadingMemories" class="skeleton-grid">
          <div class="sk-card" v-for="n in 8" :key="n"><div class="sk-cover shimmer"></div></div>
        </div>
        <div class="cards-loading err" v-else-if="memoriesError">{{ memoriesError }}</div>
        <div class="cards-loading empty" v-else-if="!displayList.length">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" /><path d="M8 11h6" />
          </svg>
          <p>{{ isSearching ? '没有匹配的档案，换个关键词试试' : '还没有档案，点上方「记录时光」写下第一段回忆吧' }}</p>
          <button v-if="!isSearching" class="empty-cta" @click="openCreate">+ 记录一段时光</button>
        </div>

        <div class="masonry" v-else>
          <ArchiveCard
            v-for="(m, i) in displayList"
            :key="m.id"
            :archive="m"
            :cover-h="masonryH(i)"
            @open="openDetail"
          />
        </div>
      </section>
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

    <!-- 灯箱大图预览 -->
    <Teleport to="body">
      <div class="lightbox" v-if="lbOpen" @click.self="closeLightbox">
        <button class="lb-close" @click="closeLightbox" aria-label="关闭">✕</button>
        <figure class="lb-body">
          <img :src="lbSrc" :alt="lbCap" />
          <figcaption v-if="lbCap">{{ lbCap }}</figcaption>
        </figure>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.home {
  position: relative;
  z-index: 2;
  height: 100vh;
  overflow-y: auto;
  color: #eef2ff;
}
.content { position: relative; z-index: 1; max-width: 1180px; margin: 0 auto; padding: 40px 22px 60px; }

/* ===== Hero ===== */
.hero { text-align: center; padding: 26px 0 6px; }
.hero-title {
  font-size: 32px; font-weight: 600; letter-spacing: 2px; margin-bottom: 10px;
  background: linear-gradient(90deg, #fff, var(--cyan-soft) 50%, var(--magenta));
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.hero-sub { color: #9fb0d8; font-size: 14px; margin-bottom: 26px; }

.searchbar {
  display: flex; align-items: center; gap: 8px; max-width: 640px; margin: 0 auto;
  padding: 7px 7px 7px 18px; border-radius: 16px;
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
.s-input { flex: 1; background: transparent; border: 0; outline: none; min-width: 0; color: #fff; font-size: 15px; font-family: inherit; padding: 12px 0; }
.s-input::placeholder { color: #8b97bd; }
.s-clear { width: 30px; height: 30px; flex-shrink: 0; border: 0; cursor: pointer; border-radius: 9px; display: grid; place-items: center; color: #aab6da; background: rgba(255, 255, 255, .08); transition: .2s; }
.s-clear svg { width: 16px; height: 16px; }
.s-clear:hover { color: #fff; background: rgba(255, 72, 196, .22); }
.s-btn { display: inline-flex; align-items: center; gap: 7px; border: 0; cursor: pointer; font-family: inherit; white-space: nowrap; padding: 11px 22px; border-radius: 11px; font-size: 14.5px; font-weight: 600; color: #04121f; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); background-size: 200% 100%; transition: .4s; letter-spacing: 2px; box-shadow: 0 10px 26px rgba(138, 92, 255, .4); }
.s-btn-ic { width: 17px; height: 17px; }
.s-btn:hover:not(:disabled) { background-position: 100% 0; transform: translateY(-1px); }
.s-btn:disabled { opacity: .7; cursor: not-allowed; }

.quick-tags { margin: 16px auto 0; max-width: 640px; display: flex; align-items: center; gap: 9px; flex-wrap: wrap; justify-content: center; }
.qt-label { font-size: 12px; color: #7e8ab0; letter-spacing: 1px; }
.qt { border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit; background: rgba(255, 255, 255, .05); color: #cdd6f4; font-size: 13px; padding: 6px 14px; border-radius: 999px; transition: .22s; }
.qt:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .28); }
.qt.on { color: #04121f; font-weight: 600; border-color: transparent; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 6px 16px rgba(138, 92, 255, .35); }

.actions { margin: 22px auto 0; display: flex; gap: 12px; justify-content: center; }
.act { display: inline-flex; align-items: center; gap: 8px; cursor: pointer; font-family: inherit; font-size: 14.5px; font-weight: 600; padding: 12px 22px; border-radius: 13px; transition: .28s; border: 1px solid rgba(255, 255, 255, .18); background: rgba(255, 255, 255, .06); color: #eef2ff; }
.act svg { width: 18px; height: 18px; }
.act:hover { transform: translateY(-2px); border-color: var(--cyan); box-shadow: 0 10px 26px rgba(45, 226, 230, .28); }
.act.primary { color: #04121f; border-color: transparent; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); background-size: 200% 100%; box-shadow: 0 12px 30px rgba(138, 92, 255, .42); }
.act.primary:hover { background-position: 100% 0; }

.search-tip { margin-top: 16px; font-size: 13px; color: #9fb0d8; text-align: center; }
.tip-pill { display: inline-block; padding: 7px 18px; border-radius: 999px; background: rgba(45, 226, 230, .1); border: 1px solid rgba(45, 226, 230, .28); color: var(--cyan-soft); font-size: 13px; }

/* ===== 数据看板 ===== */
.stats { margin-top: 40px; display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
.stat {
  position: relative; overflow: hidden;
  padding: 20px 18px; border-radius: 16px;
  background: linear-gradient(160deg, rgba(18, 22, 52, .66), rgba(12, 14, 38, .6));
  border: 1px solid rgba(255, 255, 255, .12);
  box-shadow: 0 14px 36px rgba(0, 0, 0, .35);
}
.stat::before { content: ""; position: absolute; top: 0; left: 0; right: 0; height: 3px; background: linear-gradient(90deg, transparent, var(--c), transparent); }
.stat::after { content: ""; position: absolute; right: -30px; bottom: -30px; width: 90px; height: 90px; border-radius: 50%; background: var(--c); opacity: .14; filter: blur(20px); }
.stat .num { font-size: 32px; font-weight: 700; letter-spacing: 1px; background: linear-gradient(90deg, var(--c), #fff); -webkit-background-clip: text; background-clip: text; color: transparent; }
.stat .lab { margin-top: 4px; font-size: 12.5px; color: #9fb0d8; letter-spacing: 1px; }

/* ===== 历史上的今天 ===== */
.otd { margin-top: 34px; }
.otd-head { display: flex; align-items: center; gap: 12px; margin-bottom: 14px; }
.otd-kicker { font-size: 14px; font-weight: 600; color: #eef2ff; letter-spacing: 1px; }
.otd-more { margin-left: auto; font-size: 12.5px; color: var(--cyan-soft); cursor: pointer; transition: .2s; }
.otd-more:hover { color: #fff; text-shadow: 0 0 10px rgba(45, 226, 230, .5); }
.otd-row { display: flex; gap: 14px; overflow-x: auto; padding-bottom: 8px; }
.otd-card { flex: 0 0 240px; cursor: pointer; border-radius: 14px; overflow: hidden; background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .6)); border: 1px solid rgba(255, 255, 255, .14); transition: .28s; }
.otd-card:hover { transform: translateY(-4px); border-color: var(--cyan); box-shadow: 0 18px 44px rgba(45, 226, 230, .25); }
.otd-cover { height: 120px; background-size: cover; background-position: center; background-color: #0a0e27; }
.otd-info { padding: 12px 14px 14px; display: flex; flex-direction: column; gap: 5px; }
.otd-info h4 { font-size: 14.5px; font-weight: 600; color: #eef2ff; }
.otd-info span { font-size: 12px; color: #7e8ab0; }

/* ===== 精选轮播 ===== */
.featured { margin-top: 44px; }
.sec-head { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; }
.sec-title { display: flex; align-items: baseline; gap: 12px; }
.sec-title h2 { font-size: 20px; font-weight: 600; letter-spacing: 1px; position: relative; padding-left: 14px; }
.sec-title h2::before { content: ""; position: absolute; left: 0; top: 50%; transform: translateY(-50%); width: 5px; height: 18px; border-radius: 3px; background: linear-gradient(180deg, var(--cyan), var(--magenta)); }
.sec-sub { font-size: 11px; letter-spacing: 3px; color: #7e8ab0; }
.sec-actions { margin-left: auto; display: flex; align-items: center; gap: 12px; }
.fc-count { margin-left: auto; font-size: 13px; color: #9fb0d8; letter-spacing: 1px; }

.fc-stage { position: relative; display: flex; align-items: stretch; gap: 14px; }
.fc-nav { position: absolute; top: 50%; transform: translateY(-50%); z-index: 4; width: 42px; height: 42px; border-radius: 50%; cursor: pointer; display: grid; place-items: center; font-size: 24px; line-height: 1; color: #eef2ff; background: rgba(10, 14, 39, .6); border: 1px solid rgba(255, 255, 255, .25); backdrop-filter: blur(6px); transition: .25s; }
.fc-nav:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 16px rgba(45, 226, 230, .4); }
.fc-nav.prev { left: 12px; }
.fc-nav.next { right: 12px; }
.fc-card { flex: 1; display: grid; grid-template-columns: 46% 1fr; min-height: 260px; border-radius: 18px; overflow: hidden; cursor: pointer; background: linear-gradient(160deg, rgba(18, 22, 52, .8), rgba(12, 14, 38, .7)); border: 1px solid rgba(255, 255, 255, .14); box-shadow: 0 20px 50px rgba(0, 0, 0, .45); transition: .3s; animation: fcIn .5s cubic-bezier(.2, .8, .2, 1); }
@keyframes fcIn { from { opacity: 0; transform: translateX(26px); } to { opacity: 1; transform: none; } }
.fc-card:hover { border-color: var(--cyan); box-shadow: 0 26px 60px rgba(45, 226, 230, .28); }
.fc-cover { position: relative; min-height: 260px; background-size: cover; background-position: center; background-color: #0a0e27; overflow: hidden; }
.fc-photo { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
.fc-illus { position: absolute; inset: 0; }
.fc-tag { position: absolute; left: 14px; bottom: 14px; z-index: 2; font-size: 12px; padding: 4px 14px; border-radius: 999px; background: rgba(10, 14, 39, .55); color: #eef2ff; border: 1px solid rgba(255, 255, 255, .3); backdrop-filter: blur(4px); }
.fc-vis { position: absolute; right: 14px; top: 14px; z-index: 2; font-size: 11px; padding: 4px 12px; border-radius: 999px; background: rgba(45, 226, 230, .9); color: #04121f; font-weight: 600; }
.fc-vis.pri { background: rgba(10, 14, 39, .6); color: #cdd6f4; border: 1px solid rgba(255, 255, 255, .25); }
.fc-info { padding: 30px 30px; display: flex; flex-direction: column; justify-content: center; gap: 14px; }
.fc-kicker { font-size: 11px; letter-spacing: 4px; color: var(--cyan-soft); }
.fc-title { font-size: 24px; font-weight: 600; color: #eef2ff; line-height: 1.35; }
.fc-excerpt { font-size: 14px; line-height: 1.7; color: #9fb0d8; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.fc-meta { display: flex; align-items: center; justify-content: space-between; margin-top: 4px; }
.fc-date { font-size: 13px; color: var(--cyan-soft); letter-spacing: 1px; }
.fc-go { font-size: 13px; color: #fff; font-weight: 600; }

.fc-dots { display: flex; gap: 9px; justify-content: center; margin-top: 18px; }
.fc-dots .dot { width: 9px; height: 9px; border-radius: 50%; border: 0; cursor: pointer; padding: 0; background: rgba(255, 255, 255, .22); transition: .25s; }
.fc-dots .dot.on { width: 26px; border-radius: 999px; background: linear-gradient(90deg, var(--cyan), var(--magenta)); }

/* ===== 分类区块 ===== */
.cats { margin-top: 44px; display: flex; flex-direction: column; gap: 30px; }
.cat-block .sec-head { margin-bottom: 14px; }
.cat-hint { margin-left: auto; font-size: 11.5px; color: #7e8ab0; letter-spacing: 1px; }
.cat-row { display: flex; gap: 16px; overflow-x: auto; padding-bottom: 10px; scroll-snap-type: x proximity; }
.cat-row :deep(.ac) { flex: 0 0 240px; scroll-snap-align: start; }

/* ===== 全部回忆 / 瀑布流 ===== */
.memories { margin-top: 46px; }
.count-pill { font-size: 12px; padding: 5px 13px; border-radius: 999px; background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .14); color: #cdd6f4; }
.clear-search { border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit; background: transparent; color: #aab6da; font-size: 12.5px; padding: 6px 14px; border-radius: 999px; transition: .22s; }
.clear-search:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 12px rgba(255, 72, 196, .3); }

.masonry { column-count: 4; column-gap: 18px; }
.masonry :deep(.ac) { break-inside: avoid; margin: 0 0 18px; display: inline-block; width: 100%; }

.skeleton-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(224px, 1fr)); gap: 18px; }
.sk-card { border-radius: 16px; overflow: hidden; padding: 0; background: linear-gradient(160deg, rgba(18, 22, 52, .55), rgba(12, 14, 38, .5)); border: 1px solid rgba(255, 255, 255, .1); }
.sk-card { padding: 14px; }
.sk-cover { height: 128px; margin: -14px -14px 12px; border-radius: 0; }
.sk-cover { background: linear-gradient(100deg, rgba(255, 255, 255, .04) 30%, rgba(255, 255, 255, .14) 50%, rgba(255, 255, 255, .04) 70%); background-size: 220% 100%; animation: shimmer 1.3s ease-in-out infinite; }
.shimmer { background: linear-gradient(100deg, rgba(255, 255, 255, .04) 30%, rgba(255, 255, 255, .14) 50%, rgba(255, 255, 255, .04) 70%); background-size: 220% 100%; animation: shimmer 1.3s ease-in-out infinite; }
@keyframes shimmer { 0% { background-position: 180% 0; } 100% { background-position: -40% 0; } }

.cards-loading { color: #9fb0d8; text-align: center; padding: 40px 20px; }
.cards-loading.err { color: #ff8aa8; }
.cards-loading.empty { display: flex; flex-direction: column; align-items: center; gap: 14px; }
.cards-loading.empty svg { width: 46px; height: 46px; opacity: .5; color: var(--cyan-soft); }
.cards-loading.empty p { font-size: 14px; }
.empty-cta { margin-top: 6px; border: 1px solid rgba(255, 255, 255, .2); cursor: pointer; font-family: inherit; background: rgba(255, 255, 255, .06); color: #eef2ff; font-size: 13.5px; padding: 10px 22px; border-radius: 999px; transition: .22s; }
.empty-cta:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .3); }

/* ===== 时光胶片墙 ===== */
.filmwall { margin-top: 40px; }
.film-hint { margin-left: auto; font-size: 11.5px; color: #7e8ab0; letter-spacing: 1px; }
.film-row { overflow: hidden; margin-bottom: 16px; -webkit-mask-image: linear-gradient(90deg, transparent, #000 6%, #000 94%, transparent); mask-image: linear-gradient(90deg, transparent, #000 6%, #000 94%, transparent); }
.film-track { display: flex; gap: 16px; width: max-content; }
.film-track.t1 { animation: filmScroll 60s linear infinite; }
.film-track.t2 { animation: filmScroll 72s linear infinite reverse; }
.film-row:hover .film-track { animation-play-state: paused; }
@keyframes filmScroll { from { transform: translateX(0); } to { transform: translateX(-50%); } }
.film {
  position: relative; flex: 0 0 280px; height: 176px; margin: 0;
  border-radius: 14px; overflow: hidden; cursor: zoom-in;
  border: 1px solid rgba(255, 255, 255, .14);
  box-shadow: 0 12px 30px rgba(0, 0, 0, .4);
  transition: transform .3s, border-color .3s, box-shadow .3s;
}
.film:nth-child(odd) { height: 200px; flex-basis: 250px; }
.film:hover { transform: translateY(-6px) scale(1.03); border-color: var(--cyan); box-shadow: 0 20px 44px rgba(45, 226, 230, .3); z-index: 2; }
.film img { width: 100%; height: 100%; object-fit: cover; display: block; transition: transform .5s ease; }
.film:hover img { transform: scale(1.08); }
.film figcaption {
  position: absolute; left: 0; right: 0; bottom: 0; z-index: 2;
  padding: 26px 12px 9px; font-size: 12px; letter-spacing: 2px; color: #eef2ff;
  background: linear-gradient(180deg, transparent, rgba(10, 14, 39, .85));
}

/* ===== 灯箱 ===== */
.lightbox {
  position: fixed; inset: 0; z-index: 50;
  display: grid; place-items: center; padding: 30px;
  background: rgba(6, 8, 24, .88); backdrop-filter: blur(14px);
  animation: lbFade .25s ease both;
}
@keyframes lbFade { from { opacity: 0; } to { opacity: 1; } }
.lb-body { max-width: min(1080px, 92vw); animation: lbIn .32s cubic-bezier(.2, .8, .2, 1) both; }
@keyframes lbIn { from { opacity: 0; transform: scale(.92); } to { opacity: 1; transform: none; } }
.lb-body img {
  max-width: 100%; max-height: 78vh; display: block;
  border-radius: 16px; border: 1px solid rgba(255, 255, 255, .2);
  box-shadow: 0 30px 90px rgba(0, 0, 0, .7), 0 0 40px rgba(45, 226, 230, .18);
}
.lb-body figcaption { margin-top: 12px; text-align: center; font-size: 14px; letter-spacing: 2px; color: #cdd6f4; }
.lb-close {
  position: absolute; top: 22px; right: 26px; z-index: 2;
  width: 42px; height: 42px; border-radius: 50%; cursor: pointer;
  font-size: 17px; color: #eef2ff;
  background: rgba(255, 255, 255, .1); border: 1px solid rgba(255, 255, 255, .25);
  transition: .25s;
}
.lb-close:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 16px rgba(255, 72, 196, .45); transform: rotate(90deg); }

@media (max-width: 900px) {
  .stats { grid-template-columns: repeat(2, 1fr); }
  .masonry { column-count: 3; }
  .fc-card { grid-template-columns: 1fr; }
  .fc-cover { min-height: 180px; }
  .film { flex: 0 0 210px; height: 132px; }
  .film:nth-child(odd) { flex-basis: 190px; height: 150px; }
}
@media (max-width: 600px) {
  .masonry { column-count: 2; }
  .hero-title { font-size: 25px; }
}
</style>
