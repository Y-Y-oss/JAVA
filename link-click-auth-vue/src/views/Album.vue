<script setup>
import { ref, onMounted, computed, inject } from 'vue'
import NavBar from '../components/NavBar.vue'
import ArchiveCard from '../components/ArchiveCard.vue'
import ArchiveDetail from '../components/ArchiveDetail.vue'
import ArchiveForm from '../components/ArchiveForm.vue'
import { fetchArchives, getArchive, createArchive, updateArchive, deleteArchive } from '../api/home'

const notify = inject('appNotify')

const archives = ref([])
const loading = ref(false)
const error = ref('')
const activeTag = ref('全部')
const tags = ['全部', '私语', '信件', '告白', '约定']

async function load() {
  loading.value = true
  error.value = ''
  try {
    const res = await fetchArchives(1, 50)
    archives.value = (res.data && res.data.records) || []
  } catch (err) {
    error.value = '相册加载失败：' + (err.message || '后端未连接')
  } finally {
    loading.value = false
  }
}

const displayList = computed(() =>
  activeTag.value === '全部' ? archives.value : archives.value.filter((m) => m.tag === activeTag.value)
)

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

/* 删除 */
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
          <h1>相册</h1>
          <p>每一段时光，都是一张被珍藏的照片。</p>
        </div>
        <button class="rec" @click="openCreate">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M12 5v14M5 12h14" /></svg>
          记录时光
        </button>
      </header>

      <div class="filters">
        <button v-for="t in tags" :key="t" class="f" :class="{ on: activeTag === t }" @click="activeTag = t">{{ t }}</button>
      </div>

      <div v-if="loading" class="state">载入中…</div>
      <div v-else-if="error" class="state err">{{ error }}</div>
      <div v-else-if="!displayList.length" class="state">
        这个分类下还没有档案。
        <button class="empty-cta" @click="openCreate">+ 记录一段时光</button>
      </div>

      <div v-else class="grid">
        <ArchiveCard
          v-for="m in displayList"
          :key="m.id"
          :archive="m"
          :cover-h="168"
          @open="openDetail"
        />
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
.head { display: flex; align-items: center; gap: 16px; margin-bottom: 20px; }
.head > div { flex: 1; }
.head h1 { font-size: 28px; font-weight: 600; letter-spacing: 2px; }
.head p { color: #9fb0d8; font-size: 14px; margin-top: 8px; }
.rec { display: inline-flex; align-items: center; gap: 7px; cursor: pointer; font-family: inherit; font-size: 14px; font-weight: 600; color: #04121f; padding: 11px 18px; border-radius: 12px; border: 0; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 10px 26px rgba(138, 92, 255, .4); transition: .25s; }
.rec svg { width: 16px; height: 16px; }
.rec:hover { transform: translateY(-1px); }

.filters { display: flex; gap: 9px; flex-wrap: wrap; margin-bottom: 26px; }
.f { border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit; background: rgba(255, 255, 255, .05); color: #cdd6f4; font-size: 13px; padding: 6px 16px; border-radius: 999px; transition: .22s; }
.f:hover { color: #fff; border-color: var(--cyan); }
.f.on { color: #04121f; font-weight: 600; border-color: transparent; background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); box-shadow: 0 6px 16px rgba(138, 92, 255, .35); }

.state { text-align: center; color: #9fb0d8; padding: 50px 0; display: flex; flex-direction: column; align-items: center; gap: 14px; }
.state.err { color: #ff8aa8; }
.empty-cta { border: 1px solid rgba(255, 255, 255, .2); cursor: pointer; font-family: inherit; background: rgba(255, 255, 255, .06); color: #eef2ff; font-size: 13px; padding: 9px 20px; border-radius: 999px; transition: .22s; }
.empty-cta:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .3); }

.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 18px; }
</style>
