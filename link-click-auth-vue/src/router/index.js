import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Timeline from '../views/Timeline.vue'
import Album from '../views/Album.vue'
import Community from '../views/Community.vue'
import GameZone from '../views/GameZone.vue'
import FunZone from '../views/FunZone.vue'

/**
 * 前端路由表。
 * 首页 / 时间线 / 相册 / 社区 + 独立的「娱乐」功能（/fun 娱乐专区、/games 游戏专区）。
 * 游戏专区与娱乐专区都是独立页面，与社区分开；登录态由 App.vue 控制。
 */
const routes = [
  { path: '/', name: 'home', component: Home, meta: { title: '首页' } },
  { path: '/timeline', name: 'timeline', component: Timeline, meta: { title: '时间线' } },
  { path: '/album', name: 'album', component: Album, meta: { title: '相册' } },
  { path: '/community', name: 'community', component: Community, meta: { title: '社区' } },
  { path: '/fun', name: 'fun', component: FunZone, meta: { title: '娱乐' } },
  { path: '/games', name: 'games', component: GameZone, meta: { title: '游戏专区' } }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
