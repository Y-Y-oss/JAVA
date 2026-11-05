import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 后端服务地址（spring.profiles.active=dev -> server.port=8081）
const API_TARGET = 'http://localhost:8081'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: true,
    port: 5173,
    open: true,
    proxy: {
      // 前端所有 /api 请求转发到 Spring Boot 后端
      '/api': {
        target: API_TARGET,
        changeOrigin: true
      },
      // 后台管理静态页（static/admin/index.html）也由后端托管，开发环境一并代理
      '/admin': {
        target: API_TARGET,
        changeOrigin: true
      },
      // 用户上传的时光照片（/uploads/**）由后端静态资源映射提供，开发环境一并代理
      '/uploads': {
        target: API_TARGET,
        changeOrigin: true
      }
    }
  }
})
