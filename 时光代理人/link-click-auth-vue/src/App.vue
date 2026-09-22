<script setup>
import { ref } from 'vue'
import LoginForm from './components/LoginForm.vue'
import RegisterForm from './components/RegisterForm.vue'

const activeTab = ref('login')
const toastVisible = ref(false)
const toastMsg = ref('')
let toastTimer = null

function notify(msg) {
  toastMsg.value = msg
  toastVisible.value = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => (toastVisible.value = false), 2200)
}

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

  <div class="stage">
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
          <LoginForm v-if="activeTab === 'login'" @notify="notify" />
          <RegisterForm v-else @notify="notify" />
        </div>
      </div>
    </div>
  </div>

  <div class="toast" :class="{ show: toastVisible }">{{ toastMsg }}</div>
</template>
