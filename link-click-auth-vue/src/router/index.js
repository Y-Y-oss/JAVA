import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Timeline from '../views/Timeline.vue'
import Album from '../views/Album.vue'
import Community from '../views/Community.vue'

/**
 * 前端路由表。
 * 首页 / 时间线 / 相册 / 社区 四个页面都已落地，导航栏通过 router 切换。
 * 登录态由 App.vue 控制：未登录时不渲染 router-view，直接显示登录卡片。
 */
const routes = [
  { path: '/', name: 'home', component: Home, meta: { title: '首页' } },
  { path: '/timeline', name: 'timeline', component: Timeline, meta: { title: '时间线' } },
  { path: '/album', name: 'album', component: Album, meta: { title: '相册' } },
  { path: '/community', name: 'community', component: Community, meta: { title: '社区' } }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
