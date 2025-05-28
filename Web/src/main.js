import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import './assets/styles/main.css'  // 如果你有全局样式

const app = createApp(App)

app.use(router)
app.use(ElementPlus)
app.mount('#app')