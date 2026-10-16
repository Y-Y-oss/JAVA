<script setup>
import { ref, onMounted, provide } from 'vue'
import LoginForm from './components/LoginForm.vue'
import RegisterForm from './components/RegisterForm.vue'
import { profile, logout } from './api/auth'
import { loadSession, clearSession, getAccessToken } from './api/session'
import { setTokenProvider } from './api/request'

// request 层每次请求都会问这里要 token，实现 Authorization 头的自动携带
setTokenProvider(getAccessToken)

const activeTab = ref('login')
const toastVisible = ref(false)
const toastMsg = ref('')
let toastTimer = null

/** 当前登录用户；null 表示未登录。sessionReady 防止刷新瞬间闪出登录框 */
const currentUser = ref(null)
const sessionReady = ref(false)
const loggingOut = ref(false)

function notify(msg) {
  toastMsg.value = msg
  toastVisible.value = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => (toastVisible.value = false), 2200)
}

onMounted(async () => {
  // 页面刷新后尝试用本地 token 恢复登录态；token 失效就清掉回到登录页
  const s = loadSession()
  if (s && s.accessToken) {
    try {
      const res = await profile()
      currentUser.value = res.data
    } catch (err) {
      clearSession()
    }
  }
  sessionReady.value = true
})

function onLoginSuccess(data) {
  // 登录接口返回的 data 里直接带了用户信息，省一次 profile 请求
  currentUser.value = data
}

async function onLogout() {
  if (loggingOut.value) return
  loggingOut.value = true
  try {
    const res = await logout()
    notify('✓ ' + (res.message || '已退出登录'))
  } catch (err) {
    // token 已失效也算退出——本地凭证本来就要清
    notify('✓ 已退出登录')
  } finally {
    clearSession()
    currentUser.value = null
    activeTab.value = 'login'
    loggingOut.value = false
  }
}

// 通过 provide 把登录态、退出、提示方法下发给首页（router-view 内的组件）。
// 必须放在相关 ref / 函数声明之后，避免 TDZ（暂时性死区）报错。
provide('appUser', currentUser)
provide('appLogout', onLogout)
provide('appNotify', notify)

const colors = ['rgba(122,245,247,.9)', 'rgba(255,72,196,.8)', 'rgba(138,92,255,.8)']
const particles = Array.from({ length: 34 }, (_, i) => ({
  size: 2 + Math.random() * 4,
  left: Math.random() * 100,
  duration: 7 + Math.random() * 9,
  delay: -Math.random() * 12,
  color: colors[i % 3]
}))
</script>

<template>
  <div class="bg">
    <img class="bg-img" src="/bg.png" alt="" />
    <div class="bg-tint"></div>
    <div class="bg-grain"></div>
    <div class="leak"></div>
    <div class="photo p1"><i style="background:linear-gradient(135deg,#2de2e6,#8a5cff)"></i><span>2019.04</span></div>
    <div class="photo p2"><i style="background:linear-gradient(135deg,#ff48c4,#8a5cff)"></i><span>记忆</span></div>
    <div class="photo p3"><i style="background:linear-gradient(135deg,#7af5f7,#2de2e6)"></i><span>时光</span></div>
    <div class="photo p4"><i style="background:linear-gradient(135deg,#8a5cff,#ff48c4)"></i><span>2021.07</span></div>
    <div
      class="particle"
      v-for="(p, i) in particles"
      :key="i"
      :style="{
        width: p.size + 'px',
        height: p.size + 'px',
        left: p.left + '%',
        background: 'radial-gradient(circle,' + p.color + ',transparent)',
        animationDuration: p.duration + 's',
        animationDelay: p.delay + 's'
      }"
    ></div>
  </div>

  <!-- 未登录：登录 / 注册 卡片 -->
  <div class="stage" v-if="sessionReady && !currentUser">
    <div class="card-wrap">
      <div class="card">
        <div class="brand">
          <svg class="logo" viewBox="0 0 64 64" fill="none">
            <circle cx="32" cy="32" r="30" stroke="#2de2e6" stroke-width="2.5" />
            <circle cx="32" cy="32" r="14" fill="#0a0e27" stroke="#ff48c4" stroke-width="2.5" />
            <circle cx="32" cy="32" r="6" fill="#7af5f7" />
            <path d="M32 2v10M32 52v10M2 32h10M52 32h10" stroke="#2de2e6" stroke-width="2.5" stroke-linecap="round" />
          </svg>
          <h1>时光代理人</h1>
          <p class="en">Link Click</p>
        </div>

        <div class="tabs" :class="{ register: activeTab === 'register' }">
          <div class="tab-glider"></div>
          <button class="tab" :class="{ active: activeTab === 'login' }" @click="activeTab = 'login'">登录</button>
          <button class="tab" :class="{ active: activeTab === 'register' }" @click="activeTab = 'register'">注册</button>
        </div>

        <div class="forms">
          <LoginForm v-if="activeTab === 'login'" @notify="notify" @login-success="onLoginSuccess" />
          <RegisterForm v-else @notify="notify" />
        </div>
      </div>
    </div>
  </div>

  <!-- 已登录：渲染首页（router-view）。登录成功后自动进入这里 -->
  <router-view v-else-if="sessionReady && currentUser" />

  <div class="toast" :class="{ show: toastVisible }">{{ toastMsg }}</div>
</template>
