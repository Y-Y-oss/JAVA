<script setup>
import { inject, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const user = inject('appUser')
const onLogout = inject('appLogout')

const route = useRoute()
const router = useRouter()

const navItems = [
  { key: 'home', label: '首页', path: '/', icon: 'M3 11l9-8 9 8M5 10v10h5v-6h4v6h5V10' },
  { key: 'timeline', label: '时间线', path: '/timeline', icon: 'M4 6h16M4 12h16M4 18h10' },
  { key: 'album', label: '相册', path: '/album', icon: 'M4 5h16v14H4zM4 15l4-4 4 4 4-5 4 5' },
  { key: 'community', label: '社区', path: '/community', icon: 'M16 11a4 4 0 1 0-8 0M3 21v-2a5 5 0 0 1 10 0v2M14 21v-2a5 5 0 0 1 7 0v2' },
  { key: 'admin', label: '后台管理', href: '/admin/index.html', icon: 'M4 4h7v7H4zM13 4h7v4h-7zM13 11h7v9h-7zM4 13h7v7H4z' }
]

// 用路由 name 判断当前高亮（和 router 的 name 对应）
const activeKey = computed(() => route.name)

function go(path) {
  if (route.path !== path) router.push(path)
}

const initial = computed(() =>
  (user && (user.value?.nickname || user.value?.username || '?'))?.slice(0, 1).toUpperCase()
)
</script>

<template>
  <header class="navbar">
    <div class="nav-inner">
      <div class="brand" @click="go('/')" style="cursor:pointer">
        <svg class="logo" viewBox="0 0 64 64" fill="none">
          <circle cx="32" cy="32" r="30" stroke="#2de2e6" stroke-width="2.5" />
          <circle cx="32" cy="32" r="14" fill="#0a0e27" stroke="#ff48c4" stroke-width="2.5" />
          <circle cx="32" cy="32" r="6" fill="#7af5f7" />
          <path d="M32 2v10M32 52v10M2 32h10M52 32h10" stroke="#2de2e6" stroke-width="2.5" stroke-linecap="round" />
        </svg>
        <div class="brand-text">
          <span class="b-cn">时光代理人</span>
          <span class="b-en">Link Click</span>
        </div>
      </div>

      <nav class="nav-links">
        <template v-for="item in navItems" :key="item.key">
          <a
            v-if="item.href"
            class="nav-link nav-admin"
            :href="item.href"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path :d="item.icon" />
            </svg>
            <span>{{ item.label }}</span>
          </a>
          <button
            v-else
            class="nav-link"
            :class="{ active: activeKey === item.key }"
            @click="go(item.path)"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path :d="item.icon" />
            </svg>
            <span>{{ item.label }}</span>
          </button>
        </template>
      </nav>

      <div class="nav-user">
        <div class="avatar" :title="user?.nickname || user?.username">{{ initial }}</div>
        <div class="u-meta">
          <span class="u-name">{{ user?.nickname || user?.username }}</span>
          <span class="u-role">{{ user?.role === 'admin' ? '管理员' : '时光代理人' }}</span>
        </div>
        <button class="logout-btn" @click="onLogout" title="退出登录">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9" />
          </svg>
        </button>
      </div>
    </div>
  </header>
</template>

<style scoped>
.navbar {
  position: sticky;
  top: 0;
  z-index: 5;
  backdrop-filter: blur(18px) saturate(150%);
  -webkit-backdrop-filter: blur(18px) saturate(150%);
  background: linear-gradient(180deg, rgba(10, 14, 39, .82), rgba(10, 14, 39, .42));
  border-bottom: 1px solid rgba(255, 255, 255, .12);
  box-shadow: 0 8px 30px rgba(0, 0, 0, .35);
}
.nav-inner {
  max-width: 1180px;
  margin: 0 auto;
  height: 66px;
  padding: 0 22px;
  display: flex;
  align-items: center;
  gap: 22px;
}
.brand { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.logo { width: 38px; height: 38px; filter: drop-shadow(0 4px 12px rgba(45, 226, 230, .5)); }
.brand-text { display: flex; flex-direction: column; line-height: 1.1; }
.b-cn {
  font-size: 16px; font-weight: 600; letter-spacing: 2px;
  background: linear-gradient(90deg, var(--cyan), #fff 45%, var(--magenta));
  -webkit-background-clip: text; background-clip: text; color: transparent;
}
.b-en { font-size: 10px; letter-spacing: 3px; color: #9fb0d8; text-transform: uppercase; }

.nav-links { display: flex; gap: 6px; margin: 0 auto; }
.nav-link {
  display: flex; align-items: center; gap: 7px;
  padding: 9px 16px; border: 0; cursor: pointer; font-family: inherit;
  background: transparent; color: #aab6da; font-size: 14px;
  border-radius: 12px; transition: .25s;
}
.nav-link svg { width: 17px; height: 17px; }
.nav-link:hover { color: #fff; background: rgba(255, 255, 255, .06); }
.nav-link.active {
  color: #04121f; font-weight: 600;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 18px rgba(45, 226, 230, .4);
}
.nav-link.nav-admin {
  text-decoration: none; cursor: pointer;
  color: #04121f; font-weight: 600;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 18px rgba(45, 226, 230, .4);
}
.nav-link.nav-admin:hover { color: #04121f; filter: brightness(1.08); }

.nav-user { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.avatar {
  width: 38px; height: 38px; border-radius: 50%; display: grid; place-items: center;
  font-size: 16px; font-weight: 600; color: #04121f;
  background: linear-gradient(135deg, var(--cyan), var(--purple) 60%, var(--magenta));
  box-shadow: 0 6px 18px rgba(45, 226, 230, .4); user-select: none;
}
.u-meta { display: flex; flex-direction: column; line-height: 1.2; }
.u-name { font-size: 13.5px; font-weight: 600; color: #eef2ff; }
.u-role { font-size: 11px; color: var(--cyan-soft); }
.logout-btn {
  width: 36px; height: 36px; border-radius: 10px; cursor: pointer;
  display: grid; place-items: center; margin-left: 4px;
  background: rgba(255, 255, 255, .07); border: 1px solid rgba(255, 255, 255, .16);
  color: #aab6da; transition: .25s;
}
.logout-btn svg { width: 18px; height: 18px; }
.logout-btn:hover { color: #fff; border-color: var(--magenta); box-shadow: 0 0 14px rgba(255, 72, 196, .4); }

@media (max-width: 720px) {
  .nav-links { display: none; }
  .u-meta { display: none; }
}
</style>
