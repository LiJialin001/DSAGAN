import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    redirect: '/data-processing/extraction'  // 默认重定向到信息提取页面
  },
  {
    path: '/data-processing',
    name: 'dataProcessing',
    component: () => import('../views/data-processing/Layout.vue'),
    redirect: '/data-processing/extraction',
    meta: { title: '数据处理' },
    children: [
      {
        path: 'extraction',
        name: 'infoExtraction',
        component: () => import('../views/data-processing/extraction/Index.vue'),
        meta: { title: '信息提取' }
      },
      {
        path: 'processing',
        name: 'infoProcessing',
        component: () => import('../views/data-processing/processing/Index.vue'),
        meta: { title: '信息处理' }
      },
      {
        path: 'multi-center',
        name: 'multiCenter',
        component: () => import('../views/data-processing/multi-center/Index.vue'),
        meta: { title: '多中心处理' }
      },
      {
        path: 'keyframe',
        name: 'keyframeExtraction',
        component: () => import('../views/data-processing/keyframe/Index.vue'),
        meta: { 
          title: '关键帧提取',
          hideSteps: true  // 添加标记以隐藏进度条
        }
      }
    ]
  },
  {
    path: '/reconstruction',
    name: 'reconstruction',
    component: () => import('../views/reconstruction/Layout.vue'),
    redirect: '/reconstruction/embedding',
    meta: { title: '三维重建' },
    children: [
      {
        path: 'embedding',
        name: 'latentEmbedding',
        component: () => import('../views/reconstruction/embedding/Index.vue'),
        meta: { title: '初始潜空间嵌入' }
      },
      {
        path: 'optimization',
        name: 'optimization',
        component: () => import('../views/reconstruction/optimization/Index.vue'),
        meta: { title: '优化' }
      },
      {
        path: '3d-reconstruction',
        name: '3dReconstruction',
        component: () => import('../views/reconstruction/reconstruction/Index.vue'),
        meta: { title: '三维重建' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

export default router