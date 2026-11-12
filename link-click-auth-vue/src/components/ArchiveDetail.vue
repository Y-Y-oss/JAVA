<script setup>
import { ref, computed, inject, watch } from 'vue'
import { coverStyle, visibilityText } from '../utils/archiveStyle'
import { getInteraction, toggleLike, toggleFavorite, fetchComments, addComment, deleteComment } from '../api/social'
import { applyFriend, fetchFriends, fetchFriendRequests, fetchSentRequests } from '../api/friends'

const props = defineProps({
  archive: { type: Object, default: null },
  loading: { type: Boolean, default: false },
  error: { type: String, default: '' }
})
const emit = defineEmits(['close', 'edit', 'delete'])

// 当前登录用户（App.vue provide 注入），用于判断是否是档案主人 / 是否可互动
const user = inject('appUser', null)
const notify = inject('appNotify', null)
const confirmDel = ref(false)

const isOwner = computed(() => {
  const u = user && user.value
  return !!(u && props.archive && props.archive.userId === u.id)
})
const isLoggedIn = computed(() => !!(user && user.value))

/* ===== 互动数据（点赞/收藏/评论） ===== */
const likeCount = ref(0)
const favoriteCount = ref(0)
const liked = ref(false)
const favorited = ref(false)
const comments = ref([])
const commentsLoading = ref(false)
const commentText = ref('')
const commentSubmitting = ref(false)

async function loadSocial() {
  const arch = props.archive
  if (!arch || !arch.id) return
  likeCount.value = arch.likeCount || 0
  favoriteCount.value = arch.favoriteCount || 0
  liked.value = !!arch.liked
  favorited.value = !!arch.favorited
  comments.value = []
  commentsLoading.value = true
  try {
    const [it, cm] = await Promise.all([getInteraction(arch.id), fetchComments(arch.id)])
    if (props.archive !== arch) return // 弹窗已切到别的档案，丢弃过期结果
    likeCount.value = it.data.likeCount
    favoriteCount.value = it.data.favoriteCount
    liked.value = !!it.data.liked
    favorited.value = !!it.data.favorited
    comments.value = cm.data || []
  } catch (_) {
    // 互动数据加载失败不打断详情阅读
  } finally {
    commentsLoading.value = false
  }
}

watch(() => props.archive, (v) => { if (v) { confirmDel.value = false; loadSocial(); loadFriendState() } })

async function onLike() {
  if (!isLoggedIn.value) { if (notify) notify('✗ 请先登录，再来和大家互动'); return }
  const arch = props.archive
  try {
    const res = await toggleLike(arch.id)
    liked.value = !!res.data.liked
    likeCount.value = res.data.likeCount
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '点赞失败'))
  }
}

async function onFavorite() {
  if (!isLoggedIn.value) { if (notify) notify('✗ 请先登录，再来和大家互动'); return }
  const arch = props.archive
  try {
    const res = await toggleFavorite(arch.id)
    favorited.value = !!res.data.favorited
    favoriteCount.value = res.data.favoriteCount
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '收藏失败'))
  }
}

async function submitComment() {
  const text = commentText.value.trim()
  if (!text) return
  if (!isLoggedIn.value) { if (notify) notify('✗ 请先登录，再来和大家互动'); return }
  commentSubmitting.value = true
  try {
    const res = await addComment(props.archive.id, text)
    comments.value.push(res.data)
    commentText.value = ''
    if (notify) notify('✓ 评论已发表')
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '评论失败'))
  } finally {
    commentSubmitting.value = false
  }
}

async function removeComment(c) {
  try {
    await deleteComment(c.id)
    comments.value = comments.value.filter((x) => x.id !== c.id)
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '删除失败'))
  }
}

const isMyComment = (c) => {
  const u = user && user.value
  return !!(u && c.userId === u.id)
}

/* ===== 一键加好友（作者非本人时显示） ===== */
const friendState = ref('') // self/friends/incoming/sent/none/''

async function loadFriendState() {
  const u = user && user.value
  const arch = props.archive
  if (!u || !arch) { friendState.value = ''; return }
  if (arch.userId === u.id) { friendState.value = 'self'; return }
  try {
    const [f, r, s] = await Promise.all([fetchFriends(), fetchFriendRequests(), fetchSentRequests()])
    const names = (list) => new Set((list || []).map((x) => x.username))
    if (names(f.data).has(arch.username)) friendState.value = 'friends'
    else if (names(r.data).has(arch.username)) friendState.value = 'incoming'
    else if (names(s.data).has(arch.username)) friendState.value = 'sent'
    else friendState.value = 'none'
  } catch (_) { friendState.value = '' }
}

const friendBtnText = computed(() => {
  switch (friendState.value) {
    case 'friends': return '✓ 已是好友'
    case 'incoming': return '通过验证'
    case 'sent': return '已申请，待验证'
    case 'none': return '＋ 加好友'
    default: return ''
  }
})

async function handleAddFriend() {
  const arch = props.archive
  if (!arch) return
  if (friendState.value === 'incoming') {
    if (notify) notify('对方已申请加你为好友，请到社区「我的好友 → 验证」里处理')
    return
  }
  try {
    const res = await applyFriend(arch.username)
    if (notify) notify('✓ ' + (res.message || '好友申请已发送'))
    friendState.value = 'sent'
  } catch (err) {
    if (notify) notify('✗ ' + (err.message || '申请失败'))
  }
}
</script>

<template>
  <transition name="pop">
    <div v-if="archive || loading || error" class="detail-mask" @click.self="emit('close')">
      <div class="detail-panel">
        <button class="detail-close" @click="emit('close')" aria-label="关闭">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
            <path d="M6 6l12 12M18 6L6 18" />
          </svg>
        </button>

        <div v-if="loading" class="detail-state">载入中…</div>
        <div v-else-if="error" class="detail-state err">{{ error }}</div>

        <template v-else-if="archive">
          <div class="detail-cover" :style="coverStyle(archive)">
            <span class="detail-tag">{{ archive.tag || '时光' }}</span>
            <span class="detail-vis">{{ visibilityText(archive.visibility) }}</span>
          </div>
          <div class="detail-body">
            <h2 class="detail-title">{{ archive.title }}</h2>

            <!-- 作者信息条：头像（优先用户上传的头像）+ 昵称 + 一键加好友 -->
            <div class="author-row" v-if="archive.username && !isOwner">
              <img v-if="archive.authorAvatar" class="au-avatar" :src="archive.authorAvatar" alt="作者头像" />
              <span v-else class="au-avatar au-fallback">{{ (archive.nickname || archive.username || '?').slice(0, 1).toUpperCase() }}</span>
              <span class="au-name">{{ archive.nickname || archive.username }}</span>
              <span class="au-sub">@{{ archive.username }}</span>
              <button
                v-if="friendBtnText"
                class="da-friend"
                :class="{ pending: friendState === 'sent', verify: friendState === 'incoming' }"
                :disabled="friendState === 'sent'"
                @click="handleAddFriend"
              >{{ friendBtnText }}</button>
            </div>

            <div class="detail-meta">
              <span><i>记录日期</i>{{ archive.archiveDate || '—' }}</span>
              <span><i>创建于</i>{{ archive.createTime || '—' }}</span>
              <span v-if="archive.updateTime"><i>更新于</i>{{ archive.updateTime }}</span>
              <span v-if="isOwner && archive.username"><i>作者</i>{{ archive.nickname || archive.username }}</span>
            </div>
            <div class="detail-content">{{ archive.content || '（这段时光还没有写下文字）' }}</div>

            <!-- 互动区：点赞 / 收藏 -->
            <div class="social-bar">
              <button class="sb like" :class="{ on: liked }" @click="onLike">
                <svg viewBox="0 0 24 24" :fill="liked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8z" />
                </svg>
                <span>{{ liked ? '已点赞' : '点赞' }} · {{ likeCount }}</span>
              </button>
              <button class="sb fav" :class="{ on: favorited }" @click="onFavorite">
                <svg viewBox="0 0 24 24" :fill="favorited ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M12 2l3 6.5 7 .8-5.2 4.7 1.5 6.9L12 17.3 5.7 21l1.5-6.9L2 9.3l7-.8z" />
                </svg>
                <span>{{ favorited ? '已收藏' : '收藏' }} · {{ favoriteCount }}</span>
              </button>
              <span v-if="!isLoggedIn" class="sb-hint">登录后才能点赞 / 收藏 / 评论</span>
            </div>

            <!-- 评论区 -->
            <div class="cmt-zone">
              <h3 class="cmt-title">时光评论 <i>{{ comments.length }}</i></h3>
              <form class="cmt-input" @submit.prevent="submitComment">
                <input
                  v-model="commentText"
                  type="text"
                  maxlength="500"
                  :placeholder="isLoggedIn ? '说点什么吧…（≤500字）' : '登录后可以发表评论'"
                />
                <button type="submit" :disabled="commentSubmitting || !commentText.trim()">
                  {{ commentSubmitting ? '发送中…' : '发送' }}
                </button>
              </form>
              <div v-if="commentsLoading" class="cmt-state">评论载入中…</div>
              <div v-else-if="!comments.length" class="cmt-state">还没有人留言，来当第一个吧。</div>
              <ul v-else class="cmt-list">
                <li v-for="c in comments" :key="c.id" class="cmt-item">
                  <span class="cmt-avatar">{{ (c.username || '?').slice(0, 1).toUpperCase() }}</span>
                  <div class="cmt-main">
                    <div class="cmt-head">
                      <span class="cmt-user">@{{ c.username }}</span>
                      <span class="cmt-time">{{ (c.createTime || '').replace('T', ' ').slice(0, 16) }}</span>
                      <button v-if="isMyComment(c)" class="cmt-del" @click="removeComment(c)">删除</button>
                    </div>
                    <p class="cmt-text">{{ c.content }}</p>
                  </div>
                </li>
              </ul>
            </div>

            <div class="detail-actions" v-if="isOwner">
              <button class="da edit" @click="emit('edit', archive)">编辑</button>
              <template v-if="!confirmDel">
                <button class="da del" @click="confirmDel = true">删除</button>
              </template>
              <template v-else>
                <span class="da-warn">删除后不可恢复，确定吗？</span>
                <button class="da cancel" @click="confirmDel = false">取消</button>
                <button class="da del solid" @click="emit('delete', archive)">确认删除</button>
              </template>
            </div>
          </div>
        </template>
      </div>
    </div>
  </transition>
</template>

<style scoped>
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
/* 作者信息条 */
.author-row { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
.au-avatar {
  width: 40px; height: 40px; border-radius: 50%; object-fit: cover; display: block;
  border: 1px solid rgba(255, 255, 255, .25); box-shadow: 0 4px 14px rgba(0, 0, 0, .4);
}
.au-fallback {
  display: grid; place-items: center; font-size: 16px; font-weight: 700; color: #04121f;
  background: linear-gradient(135deg, var(--cyan), var(--purple));
}
.au-name { font-size: 14.5px; font-weight: 600; color: #eef2ff; }
.au-sub { font-size: 12px; color: #7e8ab0; }
.author-row .da-friend { margin-left: auto; }

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

/* ===== 互动区（点赞/收藏） ===== */
.social-bar { display: flex; align-items: center; gap: 10px; margin-top: 16px; }
.sb {
  display: inline-flex; align-items: center; gap: 7px; cursor: pointer; font-family: inherit;
  font-size: 13px; color: #cdd6f4; padding: 8px 16px; border-radius: 12px;
  background: rgba(255, 255, 255, .05); border: 1px solid rgba(255, 255, 255, .16); transition: .22s;
}
.sb svg { width: 16px; height: 16px; }
.sb:hover { color: #fff; border-color: var(--cyan); }
.sb.like.on { color: #ff5e9c; border-color: rgba(255, 94, 156, .5); background: rgba(255, 94, 156, .12); }
.sb.fav.on { color: #ffd166; border-color: rgba(255, 209, 102, .5); background: rgba(255, 209, 102, .12); }
.sb-hint { font-size: 11.5px; color: #7e8ab0; }

/* 作者行「加好友」按钮 */
.da-friend {
  border: 1px solid rgba(45, 226, 230, .4); cursor: pointer; font-family: inherit; font-size: 12.5px;
  color: var(--cyan-soft); background: rgba(45, 226, 230, .08); padding: 6px 14px; border-radius: 10px; transition: .2s;
}
.da-friend:hover:not(:disabled) { color: #04121f; border-color: transparent; background: var(--cyan); }
.da-friend.pending { color: #8b97bd; border-color: rgba(255, 255, 255, .16); background: rgba(255, 255, 255, .05); cursor: default; }
.da-friend.verify { color: #ffd166; border-color: rgba(255, 209, 102, .5); background: rgba(255, 209, 102, .1); }

/* ===== 评论区 ===== */
.cmt-zone { margin-top: 20px; padding-top: 16px; border-top: 1px solid rgba(255, 255, 255, .1); }
.cmt-title { font-size: 14.5px; font-weight: 600; color: #eef2ff; margin: 0 0 12px; }
.cmt-title i { font-style: normal; font-size: 12px; color: var(--cyan-soft); margin-left: 6px; }
.cmt-input { display: flex; gap: 8px; margin-bottom: 14px; }
.cmt-input input {
  flex: 1; padding: 10px 13px; font-family: inherit; font-size: 13.5px; color: #fff;
  background: rgba(255, 255, 255, .06); border: 1px solid rgba(255, 255, 255, .16);
  border-radius: 11px; outline: none; transition: .22s;
}
.cmt-input input:focus { border-color: var(--cyan); background: rgba(45, 226, 230, .06); }
.cmt-input button {
  border: 0; cursor: pointer; font-family: inherit; font-size: 13px; font-weight: 600; color: #04121f;
  padding: 0 18px; border-radius: 11px;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta)); transition: .22s;
}
.cmt-input button:disabled { opacity: .5; cursor: not-allowed; }
.cmt-state { font-size: 12.5px; color: #8b97bd; padding: 14px 0; text-align: center; }
.cmt-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; max-height: 260px; overflow-y: auto; }
.cmt-item { display: flex; gap: 10px; }
.cmt-avatar {
  flex-shrink: 0; width: 30px; height: 30px; border-radius: 50%; display: grid; place-items: center;
  font-size: 13px; font-weight: 700; color: #04121f; background: linear-gradient(135deg, var(--cyan), var(--purple));
}
.cmt-main { flex: 1; min-width: 0; }
.cmt-head { display: flex; align-items: baseline; gap: 8px; }
.cmt-user { font-size: 12.5px; color: var(--cyan-soft); }
.cmt-time { font-size: 11px; color: #7e8ab0; }
.cmt-del {
  margin-left: auto; border: 0; cursor: pointer; font-family: inherit; font-size: 11px; color: #7e8ab0;
  background: transparent; padding: 2px 6px; border-radius: 6px; transition: .2s;
}
.cmt-del:hover { color: #ff8aa8; background: rgba(255, 72, 196, .14); }
.cmt-text { font-size: 13.5px; line-height: 1.6; color: #dfe5fb; margin: 4px 0 0; word-break: break-word; white-space: pre-wrap; }

.detail-actions {
  display: flex; align-items: center; gap: 10px; margin-top: 20px;
  padding-top: 18px; border-top: 1px solid rgba(255, 255, 255, .1);
}
.da {
  border: 1px solid rgba(255, 255, 255, .18); cursor: pointer; font-family: inherit;
  background: transparent; color: #cdd6f4; font-size: 13px; padding: 9px 18px; border-radius: 11px; transition: .22s;
}
.da:hover { color: #fff; border-color: var(--cyan); box-shadow: 0 0 12px rgba(45, 226, 230, .28); }
.da.del:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 12px rgba(255, 72, 196, .4); }
.da.del.solid { background: linear-gradient(135deg, #ff48c4, #8a5cff); color: #fff; border-color: transparent; }
.da.cancel { color: #9fb0d8; }
.da-warn { font-size: 12.5px; color: #ff8aa8; margin-right: auto; }

@keyframes pop {
  from { opacity: 0; transform: translateY(14px) scale(.97); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}
.pop-enter-active, .pop-leave-active { transition: opacity .26s ease; }
.pop-enter-from, .pop-leave-to { opacity: 0; }
</style>
