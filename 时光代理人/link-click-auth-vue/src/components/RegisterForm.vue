<script setup>
import { ref, onUnmounted } from 'vue'

const emit = defineEmits(['notify'])

const name = ref('')
const phone = ref('')
const code = ref('')
const pwd = ref('')
const pwd2 = ref('')
const showPwd = ref(false)
const agree = ref(false)

const nameErr = ref('')
const phoneErr = ref('')
const codeErr = ref('')
const pwdErr = ref('')
const pwd2Err = ref('')
const agreeErr = ref('')

const codeText = ref('获取验证码')
const codeDisabled = ref(false)
let timer = null

function sendCode() {
  if (!/^1[3-9]\d{9}$/.test(phone.value.trim())) {
    phoneErr.value = '请输入正确的 11 位手机号'
    return
  }
  phoneErr.value = ''
  emit('notify', '✓ 验证码已发送（演示）')
  let n = 60
  codeDisabled.value = true
  codeText.value = n + 's'
  timer = setInterval(() => {
    n--
    codeText.value = n + 's'
    if (n <= 0) {
      clearInterval(timer)
      codeDisabled.value = false
      codeText.value = '获取验证码'
    }
  }, 1000)
}

function onSubmit() {
  let ok = true
  nameErr.value = name.value.trim() ? '' : '请输入用户名'
  if (!name.value.trim()) ok = false
  const phoneOk = /^1[3-9]\d{9}$/.test(phone.value.trim())
  phoneErr.value = phoneOk ? '' : '请输入正确的 11 位手机号'
  if (!phoneOk) ok = false
  codeErr.value = code.value.trim() ? '' : '请输入验证码'
  if (!code.value.trim()) ok = false
  const pwdOk = pwd.value.length >= 6 && pwd.value.length <= 20
  pwdErr.value = pwdOk ? '' : '密码需 6-20 位'
  if (!pwdOk) ok = false
  pwd2Err.value = pwd2.value === pwd.value ? '' : '两次密码不一致'
  if (pwd2.value !== pwd.value) ok = false
  agreeErr.value = agree.value ? '' : '请先同意用户协议'
  if (!agree.value) ok = false
  if (ok) emit('notify', '✓ 注册成功，欢迎成为时光代理人')
}

onUnmounted(() => clearInterval(timer))
</script>

<template>
  <form class="form show" novalidate @submit.prevent="onSubmit">
    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6"/></svg>
      <input type="text" v-model="name" placeholder="用户名" />
    </div>
    <div class="err" :class="{ show: nameErr }">{{ nameErr }}</div>

    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><rect x="7" y="3" width="10" height="18" rx="2"/><path d="M11 18h2"/></svg>
      <input type="tel" v-model="phone" placeholder="手机号" />
      <button type="button" class="code-btn" :disabled="codeDisabled" @click="sendCode">{{ codeText }}</button>
    </div>
    <div class="err" :class="{ show: phoneErr }">{{ phoneErr }}</div>

    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><path d="M4 7h16v10H4z"/><path d="M4 7l8 6 8-6"/></svg>
      <input type="text" v-model="code" placeholder="短信验证码" />
    </div>
    <div class="err" :class="{ show: codeErr }">{{ codeErr }}</div>

    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
      <input :type="showPwd ? 'text' : 'password'" v-model="pwd" placeholder="设置密码（6-20位）" autocomplete="new-password" />
      <svg class="eye" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2" @click="showPwd = !showPwd"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>
    </div>
    <div class="err" :class="{ show: pwdErr }">{{ pwdErr }}</div>

    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
      <input type="password" v-model="pwd2" placeholder="确认密码" autocomplete="new-password" />
    </div>
    <div class="err" :class="{ show: pwd2Err }">{{ pwd2Err }}</div>

    <label class="check" style="font-size:12.5px;color:#aeb9dd">
      <input type="checkbox" v-model="agree" /> 我已阅读并同意《用户协议》和《隐私政策》
    </label>
    <div class="err" :class="{ show: agreeErr }">{{ agreeErr }}</div>

    <button type="submit" class="btn">注 册</button>
  </form>
</template>
