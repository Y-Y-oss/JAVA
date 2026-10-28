<script setup>
import { ref, onMounted, computed, inject } from 'vue'
import NavBar from '../components/NavBar.vue'
import ArchiveDetail from '../components/ArchiveDetail.vue'
import ArchiveForm from '../components/ArchiveForm.vue'
import { fetchArchives, getArchive, createArchive, updateArchive, deleteArchive } from '../api/home'
import { coverStyle, hasCover, ARCHIVE_COVER } from '../utils/archiveStyle'

const notify = inject('appNotify')

const archives = ref([])
const loading = ref(false)
const error = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await fetchArchives(1, 50)
    const list = (res.data && res.data.records) || []
    list.sort((a, b) => {
      const da = a.archiveDate || ''
      const db = b.archiveDate || ''
      if (!da) return 1
      if (!db) return -1
      return db.localeCompare(da)
    })
    archives.value = list
  } catch (err) {
    error.value = '时光轴加载失败：' + (err.message || '后端未连接')
  } finally {
    loading.value = false
  }
}

const groups = computed(() => {
  const m = {}
  for (const a of archives.value) {
    const y = (a.archiveDate || '未标注').slice(0, 4)
    ;(m[y] = m[y] || []).push(a)
  }
  return Object.keys(m)
    .sort((a, b) => b.localeCompare(a))
    .map((y) => ({ year: y, items: m[y] }))
})

function excerpt(m) {
  const c = m && m.content ? String(m.content) : ''
  return c.length > 60 ? c.slice(0, 60) + '…' : c
}
function thumb(m) {
  return hasCover(m) ? ARCHIVE_COVER[m.id] : ''
}

/* 详情 */
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

/* 新建 / 编辑 */
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
  if (notify) notify('✓ ' + (formInitial.value ? '档案已更新' : '档案已封存进时光长廊'))
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
        <div>
          <h1>时间线</h1>
          <p>沿着时光的刻度，把每段记忆按发生的日子排好。</p>
        </div>
        <button class="rec" @click="openCreate">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14" /></svg>
          记录时光
        </button>
      </header>

      <div v-if="loading" class="state">载入中…</div>
      <div v-else-if="error" class="state err">{{ error }}</div>
      <div v-else-if="!archives.length" class="state">
        还没有档案，去首页记录一段时光吧。
        <button class="empty-cta" @click="openCreate">+ 记录一段时光</button>
      </div>

      <div v-else class="timeline">
        <section v-for="g in groups" :key="g.year" class="year-block">
          <div class="year">{{ g.year }}</div>
          <ul class="rail">
            <li v-for="m in g.items" :key="m.id" class="node" @click="openDetail(m)">
              <span class="dot" :style="{ background: coverStyle(m).background }"></span>
              <div class="card">
                <div class="thumb" v-if="thumb(m)" :style="{ backgroundImage: 'url(' + thumb(m) + ')' }"></div>
                <div class="body-col">
                  <div class="meta">
                    <span class="date">{{ m.archiveDate || '未标注日期' }}</span>
                    <span class="tag">{{ m.tag || '时光' }}</span>
                    <span v-if="m.visibility === 1" class="vis">公开</span>
                  </div>
                  <h3 class="title">{{ m.title }}</h3>
                  <p class="excerpt">{{ excerpt(m) }}</p>
                </div>
              </div>
            </li>
          </ul>
        </section>
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
.content { max-width: 880px; margin: 0 auto; padding: 40px 22px 60px; }
.head { display: flex; align-items: center; gap: 16px; margin-bottom: 30px; }
.head > div { flex: 1; }
.head h1 { font-size: 28px; font-weight: 600; letter-spacing: 2px; }
.head p { color: #9fb0d8; font-size: 14px; margin-top: 8px; }
.rec { display: inline-flex; align-items: center; gap: 7px; cursor: pointer; font-family: inherit; font-size: 14px; font-weight: 600; color: #04121f; padding: 11px 18px; border-radius: 12px; border: 0; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 10px 26px rgba(138, 92, 255, .4); transition: .25s; }
.rec svg { width: 16px; height: 16px; }
.rec:hover { transform: translateY(-1px); }

.state { text-align: center; color: #9fb0d8; padding: 50px 0; display: flex; flex-direction: column; align-items: center; gap: 14px; }
.state.err { color: #ff8aa8; }
.empty-cta { border: 1px solid rgba(255, 255, 255, .2); cursor: pointer; font-family: inherit; background: rgba(255, 255, 255, .06); color: #eef2ff; font-size: 13px; padding: 9px 20px; border-radius: 999px; transition: .22s; }
.empty-cta:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .3); }

.timeline { position: relative; }
.year-block { margin-bottom: 36px; }
.year { font-size: 20px; font-weight: 700; letter-spacing: 2px; margin-bottom: 14px; background: linear-gradient(90deg, var(--cyan), var(--magenta)); -webkit-background-clip: text; background-clip: text; color: transparent; }
.rail { position: relative; padding-left: 26px; }
.rail::before { content: ""; position: absolute; left: 7px; top: 6px; bottom: 6px; width: 2px; background: linear-gradient(180deg, rgba(45, 226, 230, .6), rgba(255, 72, 196, .5)); }
.node { position: relative; margin-bottom: 16px; cursor: pointer; }
.dot { position: absolute; left: -26px; top: 22px; width: 14px; height: 14px; border-radius: 50%; box-shadow: 0 0 0 4px rgba(10, 14, 39, .9), 0 0 12px rgba(45, 226, 230, .6); }
.card { display: flex; gap: 14px; border-radius: 14px; padding: 14px; background: linear-gradient(160deg, rgba(18, 22, 52, .7), rgba(12, 14, 38, .6)); border: 1px solid rgba(255, 255, 255, .14); transition: .25s; }
.node:hover .card { transform: translateX(4px); border-color: var(--cyan); box-shadow: 0 14px 36px rgba(45, 226, 230, .25); }
.thumb { flex: 0 0 76px; width: 76px; height: 76px; border-radius: 10px; background-size: cover; background-position: center; background-color: #0a0e27; }
.card .body-col { flex: 1; min-width: 0; }
.meta { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; flex-wrap: wrap; }
.date { font-size: 13px; color: var(--cyan-soft); letter-spacing: 1px; }
.tag { font-size: 11px; padding: 2px 10px; border-radius: 999px; border: 1px solid rgba(255, 255, 255, .2); color: #cdd6f4; }
.vis { font-size: 10.5px; padding: 2px 9px; border-radius: 999px; background: rgba(45, 226, 230, .9); color: #04121f; font-weight: 600; }
.title { font-size: 16px; font-weight: 600; margin-bottom: 6px; }
.excerpt { font-size: 13px; line-height: 1.6; color: #9fb0d8; }
</style>
