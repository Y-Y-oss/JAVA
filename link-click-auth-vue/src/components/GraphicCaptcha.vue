<script setup>
/**
 * 图形验证码（服务端生成，前端只负责取图和提交）
 *
 * 用法：<GraphicCaptcha ref="capRef" @error="onErr" />
 *      capRef.value.getCaptchaId() 取本次验证码标识，随表单一起提交；
 *      后端校验后会作废该 id，所以提交失败要调 capRef.value.refresh() 换一张。
 */
import { onMounted, ref } from 'vue'
import { getCaptcha } from '../api/auth'

const emit = defineEmits(['error'])

const image = ref('')
const captchaId = ref('')
const loading = ref(false)
const failed = ref(false)

async function refresh() {
  // 同一时刻只允许一个请求，避免连点把 id 冲乱
  if (loading.value) return
  loading.value = true
  failed.value = false
  try {
    const res = await getCaptcha()
    image.value = res.data.image
    captchaId.value = res.data.captchaId
  } catch (err) {
    // 后端没起来时这里会失败，交给父组件提示
    image.value = ''
    captchaId.value = ''
    failed.value = true
    emit('error', err.message || '图形验证码加载失败')
  } finally {
    loading.value = false
  }
}

defineExpose({
  refresh,
  getCaptchaId: () => captchaId.value,
  isLoading: () => loading.value
})

onMounted(refresh)
</script>

<template>
  <!-- 单一根元素：父组件传进来的 class（.captcha-slot）才能稳定透传到这层 -->
  <div class="captcha-img" title="点击换一张" @click="refresh">
    <img v-if="image" :src="image" alt="图形验证码" />
    <span v-else>{{ failed ? '点击重试' : '加载中…' }}</span>
  </div>
</template>
