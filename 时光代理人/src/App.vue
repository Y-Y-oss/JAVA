<template>
  <main class="auth">
    <!-- 左侧视觉面板 -->
    <section class="visual">
      <div class="portal"><span></span><span></span><span></span><span></span></div>
      <div class="brand">
        <span class="logo"><span class="dot"></span>LINK CLICK</span>
      </div>
      <div>
        <h1>时光代理人</h1>
        <div class="en">Dive into the moment</div>
        <p class="tagline">潜入照片，定格瞬间。登录时光照相馆，开启你的时间潜行。</p>
      </div>
      <div class="foot">© 时光照相馆 · 仅作前端演示，非官方页面</div>
    </section>

    <!-- 右侧登录表单 -->
    <section class="form-side">
      <h2>欢迎回来</h2>
      <p class="sub">登录以继续你的时光之旅</p>

      <form novalidate @submit.prevent="onSubmit">
        <div class="field" :class="{ error: errors.account }">
          <label for="account">邮箱 / 用户名</label>
          <div class="input-wrap">
            <input
              id="account"
              v-model.trim="form.account"
              type="text"
              placeholder="name@linkclick.cn"
              autocomplete="username"
              @blur="validateField('account')"
            />
          </div>
          <div class="msg">{{ errors.account }}</div>
        </div>

        <div class="field" :class="{ error: errors.password }">
          <label for="password">密码</label>
          <div class="input-wrap">
            <input
              id="password"
              v-model="form.password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="请输入密码"
              autocomplete="current-password"
              @blur="validateField('password')"
            />
            <button
              type="button"
              class="icon"
              @click="showPassword = !showPassword"
              :aria-label="showPassword ? '隐藏密码' : '显示密码'"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6">
                <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z" />
                <circle cx="12" cy="12" r="3" />
              </svg>
            </button>
          </div>
          <div class="msg">{{ errors.password }}</div>
        </div>

        <div class="row">
          <label><input type="checkbox" v-model="form.remember" /> 记住我</label>
          <a href="#">忘记密码？</a>
        </div>

        <button type="submit" class="btn" :disabled="loading">
          {{ loading ? '正在穿越时光…' : '登 录' }}
        </button>

        <div class="divider">其他登录方式</div>
        <div class="social">
          <button type="button">
            <svg viewBox="0 0 24 24" fill="#2ee6d6"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2Zm0 4a3 3 0 1 1 0 6 3 3 0 0 1 0-6Zm0 14c-2.4 0-4.6-1.1-6-2.9.8-1.9 4-3 6-3s5.2 1.1 6 3c-1.4 1.8-3.6 2.9-6 2.9Z"/></svg>
            微信
          </button>
          <button type="button">
            <svg viewBox="0 0 24 24" fill="#3a8bff"><path d="M12 2C6.5 2 2 5.9 2 10.6c0 2.6 1.5 4.9 3.8 6.4L5 20l3-1.6c.9.2 1.9.4 3 .4 5.5 0 10-3.9 10-8.8S17.5 2 12 2Z"/></svg>
            QQ
          </button>
        </div>

        <div class="switch">还没有账号？<a href="#">立即注册</a></div>
      </form>
    </section>

    <!-- 全局提示 -->
    <div class="toast" :class="[toast.show ? 'show' : '', toast.type]">{{ toast.text }}</div>
  </main>
</template>

<script setup>
import { reactive, ref } from 'vue'

// 表单数据：用 reactive 实现响应式，数据变视图自动更新
const form = reactive({
  account: '',
  password: '',
  remember: true,
})

const showPassword = ref(false)
const loading = ref(false)
const errors = reactive({ account: '', password: '' })
const toast = reactive({ show: false, text: '', type: '' })

// 校验规则
const validators = {
  account: (v) => (!v.trim() ? '请输入邮箱或用户名' : ''),
  password: (v) => {
    if (!v) return '请输入密码'
    if (v.length < 8) return '密码至少 8 位，含字母与数字'
    if (!/[a-zA-Z]/.test(v) || !/\d/.test(v)) return '密码需同时包含字母和数字'
    return ''
  },
}

function validateField(name) {
  errors[name] = validators[name](form[name])
  return !errors[name]
}

function validateAll() {
  let ok = true
  for (const name of Object.keys(validators)) {
    if (!validateField(name)) ok = false
  }
  return ok
}

let toastTimer
function showToast(text, type) {
  toast.text = text
  toast.type = type || ''
  toast.show = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => (toast.show = false), 2600)
}

function onSubmit() {
  if (!validateAll()) {
    showToast('请检查表单中的错误项', 'err')
    return
  }
  loading.value = true
  // 模拟登录请求
  setTimeout(() => {
    loading.value = false
    showToast('登录成功，欢迎回到时光照相馆', 'ok')
  }, 1200)
}
</script>
