<script setup>
import { ref, onMounted, inject } from 'vue'
import NavBar from '../components/NavBar.vue'
import ArchiveCard from '../components/ArchiveCard.vue'
import ArchiveDetail from '../components/ArchiveDetail.vue'
import ArchiveForm from '../components/ArchiveForm.vue'
import { fetchPublicArchives, searchPublicArchives, getArchive, updateArchive, deleteArchive } from '../api/home'

const notify = inject('appNotify')

const items = ref([])
const loading = ref(false)
const error = ref('')
const keyword = ref('')
const page = ref(1)
const size = 12
const total = ref(0)
const hasMore = ref(false)

async function load(reset = true) {
  if (reset) {
    page.value = 1
    items.value = []
  }
  loading.value = true
  error.value = ''
  try {
    const q = keyword.value.trim()
    const fn = q ? searchPublicArchives : fetchPublicArchives
    const res = await fn(q, page.value, size)
    const recs = (res.data && res.data.records) || []
    total.value = res.data?.total ?? recs.length
    items.value = reset ? recs : items.value.concat(recs)
    hasMore.value = items.value.length < total.value
  } catch (err) {
    error.value = '社区加载失败：' + (err.message || '后端未连接')
  } finally {
    loading.value = false
  }
}

function onSearch() {
  load(true)
}
function clearSearch() {
  keyword.value = ''
  load(true)
}
function loadMore() {
  page.value += 1
  load(false)
}

/* 详情 + 编辑/删除（仅档案主人可见按钮） */
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
  await load(true)
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
    await load(true)
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '删除失败'))
  }
}

onMounted(() => load(true))
</script>

<template>
  <div class="page">
    <NavBar />
    <main class="content">
      <header class="head">
        <h1>社区 · 档案墙</h1>
        <p>这里展示所有人公开分享的时光，看看别人珍藏的瞬间。</p>
      </header>

      <form class="searchbar" @submit.prevent="onSearch">
        <svg class="s-ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="7" /><path d="M21 21l-4.3-4.3" />
        </svg>
        <input v-model="keyword" type="text" class="s-input" placeholder="搜索社区里公开的时光…" @keyup.enter="onSearch" />
        <button v-if="keyword" type="button" class="s-clear" @click="clearSearch" aria-label="清除">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18" /></svg>
        </button>
        <button type="submit" class="s-btn" :disabled="loading">{{ loading ? '搜索中…' : '搜索' }}</button>
      </form>

      <div v-if="loading && !items.length" class="state">载入中…</div>
      <div v-else-if="error" class="state err">{{ error }}</div>
      <div v-else-if="!items.length" class="state">还没有公开的档案，去首页把一段时光设为「公开」吧。</div>

      <div v-else>
        <div class="grid">
          <ArchiveCard
            v-for="m in items"
            :key="m.id"
            :archive="m"
            :author="m.username"
            :cover-h="150"
            @open="openDetail"
          />
        </div>

        <div v-if="hasMore" class="more-wrap">
          <button class="more" :disabled="loading" @click="loadMore">{{ loading ? '加载中…' : '加载更多' }}</button>
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

.searchbar { display: flex; align-items: center; gap: 8px; max-width: 640px; margin: 0 auto 30px; padding: 7px 7px 7px 18px; border-radius: 16px; background: linear-gradient(180deg, rgba(255, 255, 255, .1), rgba(255, 255, 255, .04)); border: 1px solid rgba(255, 255, 255, .18); box-shadow: 0 18px 50px rgba(0, 0, 0, .4); transition: .3s; }
.searchbar:focus-within { border-color: var(--cyan); box-shadow: 0 18px 50px rgba(0, 0, 0, .4), 0 0 0 3px rgba(45, 226, 230, .22); }
.s-ic { width: 22px; height: 22px; color: var(--cyan-soft); flex-shrink: 0; }
.s-input { flex: 1; background: transparent; border: 0; outline: none; min-width: 0; color: #fff; font-size: 15px; font-family: inherit; padding: 12px 0; }
.s-input::placeholder { color: #8b97bd; }
.s-clear { width: 30px; height: 30px; flex-shrink: 0; border: 0; cursor: pointer; border-radius: 9px; display: grid; place-items: center; color: #aab6da; background: rgba(255, 255, 255, .08); }
.s-clear svg { width: 16px; height: 16px; }
.s-clear:hover { color: #fff; background: rgba(255, 72, 196, .22); }
.s-btn { border: 0; cursor: pointer; font-family: inherit; white-space: nowrap; padding: 11px 22px; border-radius: 11px; font-size: 14.5px; font-weight: 600; color: #04121f; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 10px 26px rgba(138, 92, 255, .4); }
.s-btn:disabled { opacity: .7; cursor: not-allowed; }

.state { text-align: center; color: #9fb0d8; padding: 50px 0; }
.state.err { color: #ff8aa8; }

.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(224px, 1fr)); gap: 18px; }

.more-wrap { text-align: center; margin-top: 30px; }
.more { border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit; background: transparent; color: #cdd6f4; font-size: 13.5px; padding: 11px 30px; border-radius: 999px; transition: .22s; }
.more:hover:not(:disabled) { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .28); }
.more:disabled { opacity: .6; cursor: not-allowed; }
</style>
