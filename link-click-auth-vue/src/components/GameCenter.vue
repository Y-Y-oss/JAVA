<script setup>
import { ref } from 'vue'
import SnakeGame from './SnakeGame.vue'
import GomokuGame from './GomokuGame.vue'

const tabs = [
  { key: 'snake', label: '🐍 贪吃蛇' },
  { key: 'gomoku', label: '⚫ 五子棋' }
]
const active = ref('snake')
</script>

<template>
  <div class="game-center">
    <div class="gc-tabs">
      <button
        v-for="t in tabs"
        :key="t.key"
        class="gc-tab"
        :class="{ on: active === t.key }"
        @click="active = t.key"
      >{{ t.label }}</button>
    </div>
    <div class="gc-body">
      <SnakeGame v-show="active === 'snake'" />
      <GomokuGame v-show="active === 'gomoku'" />
    </div>
  </div>
</template>

<style scoped>
.game-center { width: 100%; }
.gc-tabs { display: flex; gap: 8px; margin-bottom: 14px; }
.gc-tab {
  border: 1px solid rgba(255, 255, 255, .16); cursor: pointer; font-family: inherit;
  background: rgba(255, 255, 255, .05); color: #cdd6f4; font-size: 13.5px; padding: 8px 20px;
  border-radius: 999px; transition: .22s;
}
.gc-tab:hover { color: #fff; border-color: var(--cyan); }
.gc-tab.on {
  color: #04121f; font-weight: 600; border-color: transparent;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 16px rgba(138, 92, 255, .35);
}
.gc-body { display: flex; justify-content: center; }
</style>
