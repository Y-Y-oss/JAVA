<script setup>
import { ref } from 'vue'

const emit = defineEmits(['notify'])

const account = ref('')
const pwd = ref('')
const showPwd = ref(false)
const remember = ref(false)
const accErr = ref('')
const pwdErr = ref('')

function onSubmit() {
  let ok = true
  accErr.value = account.value.trim() ? '' : '请输入手机号或账号'
  if (!account.value.trim()) ok = false
  pwdErr.value = pwd.value.length >= 6 ? '' : '密码至少 6 位'
  if (pwd.value.length < 6) ok = false
  if (ok) emit('notify', '✓ 登录成功，正在穿越时光…')
}
</script>

<template>
  <form class="form show" novalidate @submit.prevent="onSubmit">
    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6"/></svg>
      <input type="text" v-model="account" placeholder="手机号 / 账号" autocomplete="username" />
    </div>
    <div class="err" :class="{ show: accErr }">{{ accErr }}</div>

    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
      <input :type="showPwd ? 'text' : 'password'" v-model="pwd" placeholder="密码" autocomplete="current-password" />
      <svg class="eye" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2" @click="showPwd = !showPwd"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>
    </div>
    <div class="err" :class="{ show: pwdErr }">{{ pwdErr }}</div>

    <div class="row">
      <label class="check"><input type="checkbox" v-model="remember" /> 记住我</label>
      <a href="#" @click.prevent>忘记密码？</a>
    </div>

    <button type="submit" class="btn">登 录</button>

    <div class="divider">其他登录方式</div>
    <div class="socials">
      <div class="social" title="微信"><svg viewBox="0 0 24 24" fill="#7af5f7"><path d="M9 4C5 4 2 6.7 2 10c0 1.9 1 3.5 2.6 4.7L4 17l2.6-1.3c.8.2 1.6.3 2.4.3h.6a5.6 5.6 0 0 1-.2-1.5C9.4 11.4 12 9 15.4 9c.3 0 .6 0 .9.1C15.5 6.2 12.6 4 9 4zm-2.5 4.2a1 1 0 1 1 0 2 1 1 0 0 1 0-2zm5 0a1 1 0 1 1 0 2 1 1 0 0 1 0-2z"/><path d="M22 14.5c0-2.8-2.7-5-6-5s-6 2.2-6 5 2.7 5 6 5c.7 0 1.4-.1 2-.3l2 1-.5-1.7c1.5-.9 2.5-2.3 2.5-3.9zm-8-1.2a.9.9 0 1 1 0 1.8.9.9 0 0 1 0-1.8zm4 0a.9.9 0 1 1 0 1.8.9.9 0 0 1 0-1.8z"/></svg></div>
      <div class="social" title="QQ"><svg viewBox="0 0 24 24" fill="#7af5f7"><path d="M12 3c3.3 0 5.5 2.6 5.5 6 0 1.3.9 2 1.5 3.2.7 1.4.4 3-.6 3.2-.3-.6-.8-1.1-1.3-1.3-.3 2-1.9 3.4-3.7 3.7.8.5 1.3 1.3 1.3 2.2 0 .3-.2.5-.5.5s-.5-.2-.5-.5c0-.7-.4-1.3-1-1.6-.6.3-1 .9-1 1.6 0 .3-.2.5-.5.5s-.5-.2-.5-.5c0-.9.5-1.7 1.3-2.2-1.8-.3-3.4-1.7-3.7-3.7-.5.2-1 .7-1.3 1.3-1-.2-1.3-1.8-.6-3 .6-1.2 1.5-1.9 1.5-3.2 0-3.4 2.2-6 5.5-6z"/></svg></div>
      <div class="social" title="微博"><svg viewBox="0 0 24 24" fill="#ff48c4"><path d="M10 13c-3 0-5 1.8-5 4s2 4 5 4 5-1.8 5-4-2-4-5-4zm8-7c-2.5 0-4.5 2-4.5 4.5 0 .5 0 1 .1 1.4-1.2.6-2 1.7-2 3 0 1.9 1.8 3.5 4 3.5 2.5 0 4.4-1.7 4.4-4 0-2.6-2-4.6-4.5-4.6 0-1.6-1-2.8-2-2.8z"/></svg></div>
    </div>
  </form>
</template>
