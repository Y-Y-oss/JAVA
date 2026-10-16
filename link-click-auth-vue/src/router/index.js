import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'

/**
 * 前端路由表。
 * 目前只落地「首页」；后续页面（时间线 / 相册 / 社区 等）在此按需追加路由即可。
 * 登录态由 App.vue 控制：未登录时不渲染 router-view，直接显示登录卡片。
 */
const routes = [
  {
    path: '/',
    name: 'home',
    component: Home,
    meta: { title: '首页' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
