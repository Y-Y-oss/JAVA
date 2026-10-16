<script setup>
import { ref } from 'vue'
import GraphicCaptcha from './GraphicCaptcha.vue'
import { register } from '../api/auth'

const emit = defineEmits(['notify'])

const name = ref('')
const pwd = ref('')
const pwd2 = ref('')
const captcha = ref('')
const showPwd = ref(false)
const agree = ref(false)
const capRef = ref(null)
const submitting = ref(false)

const nameErr = ref('')
const pwdErr = ref('')
const pwd2Err = ref('')
const captchaErr = ref('')
const agreeErr = ref('')

/**
 * 后端字段名 -> 表单错误行。
 * 这样服务端的 @Validated 字段级错误也能精确落到对应输入框下面。
 */
const FIELD_MAP = {
  username: nameErr,
  password: pwdErr,
  confirmPassword: pwd2Err,
  pwd2: pwd2Err,
  captchaCode: captchaErr,
  captcha: captchaErr
}

function clearErrors() {
  nameErr.value = ''
  pwdErr.value = ''
  pwd2Err.value = ''
  captchaErr.value = ''
  agreeErr.value = ''
}

function onCaptchaError(msg) {
  captchaErr.value = msg
}

async function onSubmit() {
  if (submitting.value) return
  clearErrors()

  // 先做本地校验，能立刻拦住的就不打扰后端
  let ok = true
  if (!name.value.trim()) {
    nameErr.value = '请输入用户名'
    ok = false
  }
  const pwdOk = pwd.value.length >= 6 && pwd.value.length <= 20
  if (!pwdOk) {
    pwdErr.value = '密码需 6-20 位'
    ok = false
  }
  if (pwd2.value !== pwd.value) {
    pwd2Err.value = '两次密码不一致'
    ok = false
  }
  if (!captcha.value.trim()) {
    captchaErr.value = '请输入图形验证码'
    ok = false
  }
  if (!agree.value) {
    agreeErr.value = '请先同意用户协议'
    ok = false
  }
  if (!ok) return

  const captchaId = capRef.value ? capRef.value.getCaptchaId() : ''
  if (!captchaId) {
    captchaErr.value = '图形验证码还没加载好，请点击图片重试'
    return
  }

  submitting.value = true
  try {
    const res = await register({
      username: name.value.trim(),
      password: pwd.value,
      confirmPassword: pwd2.value,
      captchaId,
      captchaCode: captcha.value.trim()
    })
    emit('notify', '✓ ' + (res.message || '注册成功'))
    name.value = ''
    pwd.value = ''
    pwd2.value = ''
    agree.value = false
  } catch (err) {
    const errors = err.errors || {}
    Object.keys(errors).forEach((key) => {
      const target = FIELD_MAP[key]
      if (target) target.value = errors[key]
    })
    // 后端没给字段级错误时（例如"图形验证码不正确"以外的异常），用总提示兜底
    if (!Object.keys(errors).length) {
      captchaErr.value = err.message || '注册失败，请稍后再试'
    }
    emit('notify', '✗ ' + (err.message || '注册失败'))
  } finally {
    // 验证码是一次性的，无论成功失败都换一张，避免拿着过期 id 重复提交
    captcha.value = ''
    if (capRef.value) capRef.value.refresh()
    submitting.value = false
  }
}
</script>

<template>
  <form class="form show" novalidate @submit.prevent="onSubmit">
    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 4-6 8-6s8 2 8 6"/></svg>
      <input type="text" v-model="name" placeholder="用户名" autocomplete="username" />
    </div>
    <div class="err" :class="{ show: nameErr }">{{ nameErr }}</div>

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

    <div class="field">
      <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="#9fb0d8" stroke-width="2"><path d="M12 3l7 3v5c0 4.4-3 8.3-7 10-4-1.7-7-5.6-7-10V6z"/><path d="M9.5 12l1.8 1.8 3.4-3.6"/></svg>
      <input type="text" v-model="captcha" class="has-suffix" placeholder="图形验证码" maxlength="4" autocomplete="off" />
      <GraphicCaptcha ref="capRef" class="captcha-slot" @error="onCaptchaError" />
    </div>
    <div class="cap-row">
      <span class="err" :class="{ show: captchaErr }">{{ captchaErr }}</span>
      <a href="#" class="cap-refresh" @click.prevent="capRef && capRef.refresh()">看不清，换一张</a>
    </div>

    <label class="check" style="font-size:12.5px;color:#aeb9dd">
      <input type="checkbox" v-model="agree" /> 我已阅读并同意《用户协议》和《隐私政策》
    </label>
    <div class="err" :class="{ show: agreeErr }">{{ agreeErr }}</div>

    <button type="submit" class="btn" :disabled="submitting">{{ submitting ? '注 册 中…' : '注 册' }}</button>
  </form>
</template>
