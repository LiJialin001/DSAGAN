import axios from 'axios'
import { ElMessage } from 'element-plus'

// 创建一个 axios 实例，设置基础配置
const service = axios.create({
    // 在生产环境中使用相对URL，以便通过Nginx工作
    // baseURL: process.env.NODE_ENV === 'production' ? '/api' : 'http://localhost:8000',
    baseURL: '',
    timeout: 0, // 取消超时限制
})

// 添加响应拦截器来统一处理响应
service.interceptors.response.use(
    response => {
        const res = response.data
        if (res.code === 200) {
            return res
        } else {
            const errorMsg = res.message || res.detail || '请求失败'
            ElMessage.error(errorMsg)
            return Promise.reject(new Error(errorMsg))
        }
    },
    error => {
        // 处理 500 错误
        const errorMsg = error.response?.data?.detail || error.message || '服务器错误'
        ElMessage.error(errorMsg)
        return Promise.reject(error)
    }
)

export default service