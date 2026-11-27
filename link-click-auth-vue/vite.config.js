import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import os from 'node:os'
import dgram from 'node:dgram'

/**
 * 自动获取本机访问外网时使用的局域网 IPv4。
 * 不再写死 IP：换网络 / DHCP 重新分配地址后会自动生效。
 * 可用环境变量 LINK_CLICK_IP 手动指定，LINK_CLICK_API_TARGET 整体覆盖后端代理地址。
 */
function fallbackLanIp() {
  for (const list of Object.values(os.networkInterfaces())) {
    for (const nic of list || []) {
      if (nic.family === 'IPv4' && !nic.internal && /^(192\.168\.|10\.|172\.)/.test(nic.address)) {
        return nic.address
      }
    }
  }
  return '127.0.0.1'
}

function detectLanIp() {
  return new Promise((resolve) => {
    if (process.env.LINK_CLICK_IP) return resolve(process.env.LINK_CLICK_IP)

    const socket = dgram.createSocket('udp4')
    let done = false
    const finish = (ip) => {
      if (done) return
      done = true
      clearTimeout(timer)
      try { socket.close() } catch { /* 忽略重复关闭 */ }
      resolve(ip)
    }

    const timer = setTimeout(() => finish(fallbackLanIp()), 800)
    socket.once('error', () => finish(fallbackLanIp()))
    // UDP connect 只确定出口路由，不真正发包；拿到的就是访问外网所用的本机 IP
    socket.connect(53, '223.5.5.5', () => {
      const ip = socket.address().address
      finish(ip && ip !== '0.0.0.0' ? ip : fallbackLanIp())
    })
  })
}

export default defineConfig(async () => {
  const lanIp = await detectLanIp()
  const apiTarget = process.env.LINK_CLICK_API_TARGET || `http://${lanIp}:8081`
  console.log(`[LinkClick] 本机 IP: ${lanIp}，后端代理目标: ${apiTarget}`)

  return {
    plugins: [vue()],
    server: {
      host: true,
      port: 5173,
      open: true,
      proxy: {
        // 前端所有 /api 请求转发到 Spring Boot 后端（端口见 application-dev.properties）
        '/api': {
          target: apiTarget,
          changeOrigin: true
        },
        // 后台管理静态页（static/admin/index.html）也由后端托管，开发环境一并代理
        '/admin': {
          target: apiTarget,
          changeOrigin: true
        },
        // 用户上传的时光照片（/uploads/**）由后端静态资源映射提供，开发环境一并代理
        '/uploads': {
          target: apiTarget,
          changeOrigin: true
        }
      }
    }
  }
})
