<template>
  <el-container class="layout-container">
    <!-- 侧边栏导航 -->
    <el-aside width="220px">
      <div class="logo-container">
        <h1 class="logo-title">EG3D重建系统</h1>
      </div>
      <el-menu
        :default-active="activeMenu"
        class="el-menu-vertical"
        :router="true"
        :unique-opened="true"
        background-color="#304156"
        text-color="#fff"
        active-text-color="#409EFF"
      >
        <!-- 数据处理模块 -->
        <el-sub-menu index="/data-processing">
          <template #title>
            <el-icon><DataAnalysis /></el-icon>
            <span>数据处理</span>
          </template>
          <el-menu-item index="/data-processing/extraction">
            <el-icon><Document /></el-icon>
            信息提取
          </el-menu-item>
          <el-menu-item index="/data-processing/processing">
            <el-icon><Operation /></el-icon>
            信息处理
          </el-menu-item>
          <el-menu-item index="/data-processing/multi-center">
            <el-icon><Share /></el-icon>
            多中心处理
          </el-menu-item>
          <el-menu-item index="/data-processing/keyframe">
            <el-icon><PictureFilled /></el-icon>
            关键帧提取
          </el-menu-item>
        </el-sub-menu>

        <!-- 三维重建模块 -->
        <el-sub-menu index="/reconstruction">
          <template #title>
            <el-icon><Monitor /></el-icon>
            <span>三维重建</span>
          </template>
          <el-menu-item index="/reconstruction/embedding">
            <el-icon><Connection /></el-icon>
            初始潜空间嵌入
          </el-menu-item>
          <el-menu-item index="/reconstruction/optimization">
            <el-icon><SetUp /></el-icon>
            优化
          </el-menu-item>
          <el-menu-item index="/reconstruction/3d-reconstruction">
            <el-icon><Histogram /></el-icon>
            三维重建
          </el-menu-item>
        </el-sub-menu>
      </el-menu>
    </el-aside>

    <!-- 主内容区 -->
    <el-container>
      <el-header>
        <div class="header-content">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item>{{ currentMainModule }}</el-breadcrumb-item>
            <el-breadcrumb-item>{{ currentSubModule }}</el-breadcrumb-item>
          </el-breadcrumb>
          
          <div class="user-info">
            <el-tooltip
              content="全屏"
              placement="bottom"
            >
              <el-icon class="header-icon" @click="toggleFullScreen">
                <FullScreen />
              </el-icon>
            </el-tooltip>
            
            <el-dropdown>
              <span class="el-dropdown-link">
                <el-avatar :size="32" icon="UserFilled" />
                <span class="username">管理员</span>
                <el-icon class="el-icon--right"><ArrowDown /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item>
                    <el-icon><User /></el-icon>个人信息
                  </el-dropdown-item>
                  <el-dropdown-item>
                    <el-icon><SwitchButton /></el-icon>退出登录
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </div>
      </el-header>

      <el-main>
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
// 在 script setup 部分修改图标导入
import {
  DataAnalysis,
  Monitor,
  Connection,
  SetUp,
  Histogram,
  FullScreen,
  User,
  SwitchButton,
  Document,  // 替换 Extraction
  Operation,
  Share,
  ArrowDown,  // 添加ArrowDown图标
  PictureFilled
} from '@element-plus/icons-vue'

const route = useRoute()

// 计算当前激活的菜单项
const activeMenu = computed(() => route.path)

// 计算当前主模块名称
const currentMainModule = computed(() => {
  return route.path.includes('data-processing') ? '数据处理' : '三维重建'
})

// 计算当前子模块名称
const currentSubModule = computed(() => {
  const moduleMap = {
    'extraction': '信息提取',
    'processing': '信息处理',
    'multi-center': '多中心处理',
    'keyframe': '关键帧提取',
    'embedding': '初始潜空间嵌入',
    'optimization': '优化',
    '3d-reconstruction': '三维重建'
  }
  const pathSegments = route.path.split('/')
  const lastSegment = pathSegments[pathSegments.length - 1]
  return moduleMap[lastSegment] || ''
})

// 切换全屏
const toggleFullScreen = () => {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen()
  } else {
    document.exitFullscreen()
  }
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
}

.logo-container {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #263445;
}

.logo-title {
  color: #fff;
  font-size: 18px;
  font-weight: 600;
  margin: 0;
}

.el-aside {
  background-color: #304156;
  color: #fff;
}

.el-menu-vertical {
  border-right: none;
}

.el-header {
  background-color: #fff;
  border-bottom: 1px solid #dcdfe6;
  padding: 0 20px;
  height: 60px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 100%;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 20px;
}

.header-icon {
  font-size: 20px;
  cursor: pointer;
  color: #606266;
}

.el-dropdown-link {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.username {
  margin: 0 8px;
  color: #606266;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>