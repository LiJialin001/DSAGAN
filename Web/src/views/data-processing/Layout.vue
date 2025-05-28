<template>
  <div class="data-processing-layout">
    <el-card class="process-flow-card">
      <template #header>
        <div class="card-header">
          <span>冠状动脉三维重建数据处理流程</span>
        </div>
      </template>
      
      <!-- 流程步骤条 -->
      <el-steps v-if="!$route.meta.hideSteps" :active="activeStep" finish-status="success" align-center>
        <el-step title="信息提取" description="DICOM转PNG" />
        <el-step title="信息处理" description="图像裁剪黑边" />
        <el-step title="多中心处理" description="图像风格统一" />
      </el-steps>

      <!-- 处理步骤内容区 -->
      <div class="step-container">
        <!-- 二级路由出口，用于显示子模块内容 -->
        <router-view @step-completed="handleStepCompleted" @prev-step="handlePrevStep"></router-view>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

// 当前活跃步骤
const activeStep = ref(0)
const route = useRoute()
const router = useRouter()

// 路径和步骤的映射关系
const pathStepMap = {
  'extraction': 0,
  'processing': 1,
  'multi-center': 2
}

// 根据当前路由更新步骤
const updateActiveStep = () => {
  const currentPath = route.path.split('/').pop()
  activeStep.value = pathStepMap[currentPath] || 0
}

// 监听路由变化
watch(() => route.path, updateActiveStep)

// 组件挂载时更新步骤
onMounted(() => {
  updateActiveStep()
})

// 处理步骤完成事件
const handleStepCompleted = (data) => {
  const nextStep = activeStep.value + 1
  if (nextStep <= 2) {
    // 根据步骤导航到对应路由
    const nextPaths = ['processing', 'multi-center']
    router.push({
      path: `/data-processing/${nextPaths[activeStep.value]}`,
      query: { from_previous: 'true', ...data }
    })
  }
}

// 处理返回上一步事件
const handlePrevStep = () => {
  const prevStep = activeStep.value - 1
  if (prevStep >= 0) {
    // 根据步骤导航到对应路由
    const prevPaths = ['extraction', 'processing']
    router.push({
      path: `/data-processing/${prevPaths[prevStep]}`,
      query: { from_next: 'true' }
    })
  }
}
</script>

<style scoped>
.data-processing-layout {
  padding: 20px;
}

.process-flow-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: bold;
  font-size: 16px;
}

.step-container {
  margin-top: 30px;
}
</style>