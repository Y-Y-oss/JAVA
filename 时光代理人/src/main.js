import { createApp } from 'vue'
import App from './App.vue'
// 样式单独抽到 style.css，由入口统一引入
import './style.css'

createApp(App).mount('#app')
