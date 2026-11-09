<script setup>
import { ref, watch, computed } from 'vue'
import { createArchive, updateArchive, uploadArchiveImage, deleteArchiveImage } from '../api/home'
import { KNOWN_TAGS } from '../utils/archiveStyle'

const props = defineProps({
  initial: { type: Object, default: null }, // null = 新建；否则为编辑
  show: { type: Boolean, default: false }
})
const emit = defineEmits(['saved', 'close'])

const isEdit = computed(() => !!props.initial)
const title = ref('')
const content = ref('')
const archiveDate = ref('')
const tag = ref('私语')
const visibility = ref(0)
const submitting = ref(false)
const formError = ref('')

// 封面照片上传相关
const coverUrl = ref('')
const uploading = ref(false)
const progress = ref(0)
const isDragOver = ref(false)
const fileInput = ref(null)

// 打开时根据 initial 填充表单（编辑）或重置（新建）
watch(() => props.show, (v) => {
  if (!v) return
  formError.value = ''
  submitting.value = false
  if (props.initial) {
    title.value = props.initial.title || ''
    content.value = props.initial.content || ''
    archiveDate.value = props.initial.archiveDate || ''
    tag.value = props.initial.tag || '私语'
    visibility.value = props.initial.visibility === 1 ? 1 : 0
  } else {
    title.value = ''
    content.value = ''
    archiveDate.value = new Date().toISOString().slice(0, 10)
    tag.value = '私语'
    visibility.value = 0
  }
  coverUrl.value = props.initial ? (props.initial.cover || '') : ''
})

function onPickFile() {
  if (fileInput.value) fileInput.value.click()
}

async function handleFile(file) {
  if (!file) return
  if (!file.type.startsWith('image/')) {
    formError.value = '请选择图片文件（png/jpg/webp/gif）'
    return
  }
  if (file.size > 5 * 1024 * 1024) {
    formError.value = '图片不能超过 5MB'
    return
  }
  uploading.value = true
  progress.value = 0
  formError.value = ''
  try {
    const res = await uploadArchiveImage(file, { onProgress: (p) => (progress.value = p) })
    coverUrl.value = (res.data && res.data.url) || ''
  } catch (err) {
    formError.value = err.message || '上传失败'
  } finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

function onFileChange(e) {
  handleFile(e.target.files && e.target.files[0])
}

function onDrop(e) {
  isDragOver.value = false
  const file = e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]
  handleFile(file)
}
function onDragOver() {
  isDragOver.value = true
}
function onDragLeave() {
  isDragOver.value = false
}

async function removeCover() {
  const old = coverUrl.value
  coverUrl.value = ''
  // 若移除的是刚上传/已保存的真实照片，顺手通知后端删除文件，避免磁盘残留
  if (old && old.startsWith('/uploads/')) {
    try {
      await deleteArchiveImage(old)
    } catch (_) {
      // 服务端删除失败不影响本地移除体验
    }
  }
}

async function onSubmit() {
  if (!title.value.trim()) {
    formError.value = '请先给这段时光起个标题'
    return
  }
  submitting.value = true
  formError.value = ''
  const dto = {
    title: title.value.trim(),
    content: content.value.trim() || null,
    archiveDate: archiveDate.value || null,
    tag: tag.value || null,
    visibility: visibility.value === 1 ? 1 : 0,
    cover: coverUrl.value || null
  }
  try {
    const res = isEdit.value
      ? await updateArchive(props.initial.id, dto)
      : await createArchive(dto)
    emit('saved', res.data)
  } catch (err) {
    formError.value = err.message || '保存失败'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <transition name="pop">
    <div v-if="show" class="form-mask" @click.self="emit('close')">
      <div class="form-panel">
        <button class="form-close" @click="emit('close')" aria-label="关闭">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>

        <h2 class="form-title">{{ isEdit ? '编辑这段时光' : '记录一段时光' }}</h2>
        <p class="form-sub">{{ isEdit ? '修改后它会重新封存进时光长廊' : '把值得珍藏的瞬间，交给时光代理人保管' }}</p>

        <form class="form-fields" @submit.prevent="onSubmit">
          <label class="fld">
            <span class="fld-label">标题 <i>*</i></span>
            <input v-model="title" type="text" maxlength="100" placeholder="例如：天台上的告白" />
          </label>

          <label class="fld">
            <span class="fld-label">内容</span>
            <textarea v-model="content" rows="4" maxlength="5000" placeholder="写下这段时光里发生了什么…"></textarea>
          </label>

          <div class="fld-row">
            <label class="fld">
              <span class="fld-label">时光节点</span>
              <input v-model="archiveDate" type="date" />
            </label>
            <label class="fld">
              <span class="fld-label">标签</span>
              <select v-model="tag">
                <option v-for="t in KNOWN_TAGS" :key="t" :value="t">{{ t }}</option>
              </select>
            </label>
          </div>

          <div class="fld">
            <span class="fld-label">可见性</span>
            <div class="seg">
              <button type="button" class="seg-btn" :class="{ on: visibility === 0 }" @click="visibility = 0">仅自己</button>
              <button type="button" class="seg-btn" :class="{ on: visibility === 1 }" @click="visibility = 1">公开到档案墙</button>
            </div>
          </div>

          <div class="fld">
            <span class="fld-label">封面照片</span>
            <div class="cover-upload" :class="{ 'drag-over': isDragOver }"
                 @dragover.prevent="onDragOver" @dragleave.prevent="onDragLeave" @drop.prevent="onDrop">
              <div v-if="coverUrl" class="cover-preview">
                <img :src="coverUrl" alt="封面预览" />
                <div class="cover-actions">
                  <button type="button" class="ca" @click="onPickFile">重新上传</button>
                  <button type="button" class="ca danger" @click="removeCover">移除</button>
                </div>
                <div v-if="uploading" class="cover-progress"><div class="bar" :style="{ width: progress + '%' }"></div></div>
              </div>
              <button v-else type="button" class="cover-pick" :disabled="uploading" @click="onPickFile">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M12 16V4M7 9l5-5 5 5" /><path d="M4 16v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" />
                </svg>
                <span>{{ uploading ? '上传中… ' + progress + '%' : '上传一张照片' }}</span>
              </button>
              <input ref="fileInput" type="file" accept="image/*" class="hidden-file" @change="onFileChange" />
              <div v-if="uploading" class="progress"><div class="bar" :style="{ width: progress + '%' }"></div></div>
              <p class="cover-hint">支持 png/jpg/webp/gif，≤5MB。把图片拖到此处也能上传；留空则使用系统默认封面。</p>
            </div>
          </div>

          <p class="form-err" v-if="formError">{{ formError }}</p>

          <button type="submit" class="form-submit" :disabled="submitting">
            {{ submitting ? '保存中…' : (isEdit ? '保存修改' : '封存这段时光') }}
          </button>
        </form>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.form-mask {
  position: fixed; inset: 0; z-index: 60;
  display: grid; place-items: center; padding: 20px;
  background: rgba(5, 8, 24, .62);
  backdrop-filter: blur(8px) saturate(140%);
  -webkit-backdrop-filter: blur(8px) saturate(140%);
}
.form-panel {
  position: relative;
  width: min(520px, 100%);
  max-height: 88vh; overflow-y: auto;
  border-radius: 20px; padding: 26px 26px 28px;
  background: linear-gradient(160deg, rgba(20, 24, 56, .94), rgba(11, 13, 38, .96));
  border: 1px solid rgba(255, 255, 255, .16);
  box-shadow: 0 30px 80px rgba(0, 0, 0, .55), 0 0 0 1px rgba(45, 226, 230, .12);
  animation: pop .3s ease;
}
.form-close {
  position: absolute; top: 14px; right: 14px; z-index: 2;
  width: 36px; height: 36px; border-radius: 50%; cursor: pointer;
  display: grid; place-items: center; color: #eef2ff;
  background: rgba(10, 14, 39, .5); border: 1px solid rgba(255, 255, 255, .2); transition: .25s;
}
.form-close svg { width: 18px; height: 18px; }
.form-close:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 14px rgba(255, 72, 196, .45); }

.form-title { font-size: 21px; font-weight: 600; color: #eef2ff; margin-bottom: 6px; }
.form-sub { font-size: 13px; color: #9fb0d8; margin-bottom: 20px; }

.form-fields { display: flex; flex-direction: column; gap: 16px; }
.fld { display: flex; flex-direction: column; gap: 7px; }
.fld-row { display: flex; gap: 14px; }
.fld-row .fld { flex: 1; }
.fld-label { font-size: 12.5px; color: #aeb9dd; letter-spacing: .5px; }
.fld-label i { color: var(--magenta); font-style: normal; }
.fld input, .fld textarea, .fld select {
  width: 100%; padding: 11px 13px; font-family: inherit; font-size: 14px; color: #fff;
  background: linear-gradient(180deg, rgba(255, 255, 255, .09), rgba(255, 255, 255, .04));
  border: 1px solid rgba(255, 255, 255, .16); border-radius: 12px; outline: none; transition: .25s;
}
.fld input::-webkit-calendar-picker-indicator { filter: invert(.8); }
.fld textarea { resize: vertical; line-height: 1.6; }
.fld input:focus, .fld textarea:focus, .fld select:focus {
  border-color: var(--cyan); box-shadow: 0 0 0 3px rgba(45, 226, 230, .2); background: rgba(45, 226, 230, .06);
}
.fld select option { background: #141a34; color: #fff; }

.seg { display: flex; gap: 8px; }
.seg-btn {
  flex: 1; padding: 11px 0; border-radius: 12px; cursor: pointer; font-family: inherit; font-size: 13.5px;
  color: #cdd6f4; background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .16); transition: .22s;
}
.seg-btn.on {
  color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 16px rgba(138, 92, 255, .35);
}

.form-err { font-size: 12.5px; color: #ff8aa8; }
.form-submit {
  margin-top: 4px; border: 0; cursor: pointer; font-family: inherit; font-size: 15px; font-weight: 600; color: #04121f;
  padding: 13px; border-radius: 13px; letter-spacing: 2px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  background-size: 200% 100%; transition: .4s; box-shadow: 0 12px 30px rgba(138, 92, 255, .4);
}
.form-submit:hover:not(:disabled) { background-position: 100% 0; transform: translateY(-1px); }
.form-submit:disabled { opacity: .7; cursor: not-allowed; }

.cover-upload { display: flex; flex-direction: column; gap: 8px; }
.cover-preview { position: relative; width: 100%; max-width: 260px; border-radius: 12px; overflow: hidden; border: 1px solid rgba(255, 255, 255, .16); }
.cover-preview img { display: block; width: 100%; height: 150px; object-fit: cover; }
.cover-actions { position: absolute; right: 8px; bottom: 8px; display: flex; gap: 6px; }
.ca { border: 1px solid rgba(255, 255, 255, .2); cursor: pointer; font-family: inherit; font-size: 12px; padding: 5px 10px; border-radius: 8px; color: #eef2ff; background: rgba(10, 14, 39, .6); backdrop-filter: blur(4px); transition: .2s; }
.ca:hover { color: #fff; border-color: var(--cyan); }
.ca.danger:hover { border-color: var(--magenta); color: #ff8aa8; }
.cover-pick { display: flex; align-items: center; justify-content: center; gap: 8px; width: 100%; max-width: 260px; padding: 16px; cursor: pointer; font-family: inherit; font-size: 13.5px; color: #cdd6f4; background: rgba(255, 255, 255, .05); border: 1px dashed rgba(255, 255, 255, .22); border-radius: 12px; transition: .22s; }
.cover-pick:hover:not(:disabled) { color: #fff; border-color: var(--cyan); background: rgba(45, 226, 230, .08); }
.cover-pick:disabled { opacity: .6; cursor: not-allowed; }
.cover-pick svg { width: 20px; height: 20px; }
.hidden-file { display: none; }
.cover-hint { font-size: 11.5px; color: #8b97bd; }

.cover-upload.drag-over { border-radius: 12px; border: 1px dashed var(--cyan); background: rgba(45, 226, 230, .1); padding: 10px; }
.progress { width: 100%; max-width: 260px; height: 6px; border-radius: 999px; overflow: hidden; background: rgba(255, 255, 255, .12); }
.progress .bar { height: 100%; background: linear-gradient(135deg, var(--cyan), var(--magenta)); transition: width .2s ease; }
.cover-progress { position: absolute; left: 0; right: 0; bottom: 0; height: 5px; background: rgba(0, 0, 0, .35); }
.cover-progress .bar { height: 100%; background: linear-gradient(135deg, var(--cyan), var(--magenta)); transition: width .2s ease; }

@keyframes pop { from { opacity: 0; transform: translateY(14px) scale(.97); } to { opacity: 1; transform: none; } }
.pop-enter-active, .pop-leave-active { transition: opacity .26s ease; }
.pop-enter-from, .pop-leave-to { opacity: 0; }
</style>
