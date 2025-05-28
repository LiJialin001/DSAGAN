<template>
    <div class="upload-container">
        <el-card class="upload-card">
            <template #header>
                <div class="card-header">
                    <span>图像黑边裁剪</span>
                </div>
            </template>

            <!-- 上一步数据提示 -->
            <div class="previous-data-alert" v-if="fromPrevious">
                <el-alert
                    title="已自动接收上一步转换的图像进行处理"
                    type="success"
                    show-icon
                    :closable="false"
                >
                    <div class="previous-images-info">
                        <span>共接收 {{ receivedImageUrls.length }} 张图像</span>
                    </div>
                </el-alert>
            </div>

            <!-- 文件上传区域 -->
            <el-upload
                class="upload-area"
                drag
                :action="null"
                :auto-upload="false"
                :on-change="handleFileChange"
                :on-remove="handleFileRemove"
                :show-file-list="true"
                :accept="'image/*'"
                multiple
                v-if="!fromPrevious"
            >
                <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                <div class="el-upload__text">
                    拖拽图像文件到此处或 <em>点击上传</em>
                </div>
                <template #tip>
                    <div class="el-upload__tip">
                        支持JPG、JPEG、PNG和BMP格式的图像文件
                    </div>
                </template>
            </el-upload>

            <!-- 上传按钮 -->
            <div class="upload-actions">
                <el-switch
                    v-model="testMode"
                    active-text="测试模式"
                    inactive-text="正常模式"
                    style="margin-right: 20px;"
                />
                <el-button 
                    type="primary" 
                    :loading="uploading"
                    @click="handleUpload"
                    :disabled="!testMode && !fromPrevious && selectedFiles.length === 0"
                >
                    开始裁剪
                </el-button>
                <el-button 
                    type="default" 
                    @click="goToPrevStep"
                    v-if="fromPrevious"
                >
                    返回上一步
                </el-button>
            </div>

            <!-- 上传进度显示 -->
            <div class="upload-progress" v-if="uploading">
                <el-progress 
                    :percentage="uploadProgress"
                    :status="uploadStatus"
                />
            </div>

            <div class="process-result" v-if="uploadResult">
                <el-alert
                    :title="uploadResult.message"
                    :type="uploadResult.type ? 'success' : 'error'"
                    show-icon
                />
                <!-- 下载和下一步按钮 -->
                <div class="operation-actions" v-if="uploadResult.type">
                    <el-button 
                        type="primary"
                        @click="downloadArchive"
                        :disabled="!uploadResult.archiveUrl"
                    >
                        <el-icon><Download /></el-icon>
                        下载裁剪后图像压缩包
                    </el-button>
                    <el-button 
                        type="success"
                        @click="goToNextStep"
                        :disabled="resultList.length === 0"
                    >
                        <el-icon><Right /></el-icon>
                        进行图像风格统一
                    </el-button>
                </div>
            </div>

            <!-- 图片展示区域 -->
            <div class="image-display">
                <h3>裁剪结果预览</h3>
                <div v-if="resultList.length" class="result-list">
                    <el-row :gutter="20">
                        <el-col :span="12" v-for="(item, index) in resultList" :key="index">
                            <el-card class="result-card" shadow="hover">
                                <template #header>
                                    <div class="result-card-header">
                                        <span>图片 {{ index + 1 }}</span>
                                    </div>
                                </template>
                                <el-image
                                    :src="item.imageUrl"
                                    :preview-src-list="resultList.map(r => r.imageUrl)"
                                    :initial-index="index"
                                    fit="contain"
                                    class="result-image"
                                >
                                    <template #placeholder>
                                        <div class="image-placeholder">
                                            <el-icon><Picture /></el-icon>
                                            <span>加载中...</span>
                                        </div>
                                    </template>
                                    <template #error>
                                        <div class="image-error">
                                            <el-icon><PictureFilled /></el-icon>
                                            <span>加载失败</span>
                                        </div>
                                    </template>
                                </el-image>
                            </el-card>
                        </el-col>
                    </el-row>
                </div>
                <div v-else class="no-result">
                    <el-empty 
                        description="暂无裁剪结果" 
                        :image-size="200"
                    >
                        <template #image>
                            <el-icon class="no-result-icon"><Picture /></el-icon>
                        </template>
                    </el-empty>
                </div>
                
                <!-- 调试信息 -->
                <div class="debug-info" v-if="resultList.length">
                    <h4>图片URL调试信息</h4>
                    <div v-for="(item, index) in resultList" :key="`debug-${index}`" class="debug-item">
                        <p>图片 {{index+1}} URL: <code>{{ item.imageUrl }}</code></p>
                        <div>
                            <a :href="item.imageUrl" target="_blank" style="margin-right: 10px;">在新窗口打开</a>
                        </div>
                    </div>
                    <div v-if="uploadResult && uploadResult.archiveUrl">
                        <p>压缩包URL: <code>{{ uploadResult.archiveUrl }}</code></p>
                    </div>
                </div>
            </div>
        </el-card>
    </div>
</template>

<script setup>
import { ref, onMounted, defineEmits } from 'vue'
import { useRoute } from 'vue-router'
import { UploadFilled, Picture, PictureFilled, Download, Right } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { processFile, testProcess } from '@/api/process'
import { formatDownloadUrl } from '@/utils/download'

// 声明事件
const emit = defineEmits(['step-completed', 'prev-step'])

// 路由对象
const route = useRoute()

// 测试模式状态
const testMode = ref(false)

// 状态变量
const selectedFiles = ref([])
const uploading = ref(false)
const uploadProgress = ref(0)
const uploadStatus = ref('')
const uploadResult = ref(null)
const resultList = ref([])

// 上一步传递的数据
const fromPrevious = ref(false)
const receivedImageUrls = ref([])
const prevArchiveUrl = ref('')

// 处理来自上一步的数据
onMounted(() => {
    if (route.query.from_previous === 'true') {
        fromPrevious.value = true
        
        // 解析来自上一步的图像URL数组
        if (route.query.imageUrls) {
            if (typeof route.query.imageUrls === 'string') {
                // 单个URL作为字符串
                receivedImageUrls.value = [route.query.imageUrls]
            } else {
                // 多个URL作为数组
                receivedImageUrls.value = route.query.imageUrls
            }
            ElMessage.success(`已接收 ${receivedImageUrls.value.length} 张图像准备处理`)
        }
        
        // 获取压缩包URL
        if (route.query.archiveUrl) {
            prevArchiveUrl.value = route.query.archiveUrl
        }
    } else if (route.query.from_next === 'true') {
        ElMessage.info('您已返回到图像裁剪步骤')
    }
})

// 处理文件选择
const handleFileChange = (file) => {
    const extension = file.name.split('.').pop().toLowerCase()
    
    if (!['jpg', 'jpeg', 'png', 'bmp'].includes(extension)) {
        ElMessage.error('请上传JPG、JPEG、PNG或BMP格式的图像文件！')
        return false
    }
    
    // 将文件添加到选中文件列表
    if (!selectedFiles.value.some(f => f.uid === file.uid)) {
        selectedFiles.value.push(file)
    }
    
    uploadProgress.value = 0
    return true
}

// 处理文件移除
const handleFileRemove = (file) => {
    // 从选中文件列表中移除
    selectedFiles.value = selectedFiles.value.filter(f => f.uid !== file.uid)
}

// 处理文件上传
const handleUpload = async () => {
    if (!testMode.value && !fromPrevious.value && selectedFiles.value.length === 0) {
        ElMessage.warning('请先选择图像文件')
        return
    }

    try {
        uploading.value = true
        uploadStatus.value = ''
        uploadProgress.value = 0
        resultList.value = []
        
        let result;
        
        if (testMode.value) {
            // 使用测试模式，不需要上传文件
            uploadProgress.value = 50;
            result = await testProcess();
        } else {
            const formData = new FormData()
            
            if (fromPrevious.value) {
                // 如果是从上一步接收的图像URL，则将URL传递给后端
                receivedImageUrls.value.forEach((url, index) => {
                    formData.append(`image_url_${index}`, url)
                })
            } else {
                // 否则，上传文件
                selectedFiles.value.forEach((file, index) => {
                    formData.append(`image_${index}`, file.raw)
                })
            }
            
            result = await processFile(formData, (progressEvent) => {
                if (progressEvent.lengthComputable) {
                    const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
                    uploadProgress.value = Math.min(progress, 90)
                }
            })
        }

        uploadProgress.value = 100
        uploadStatus.value = 'success'
        
        if (result.code === 200 && result.data) {
            // 检查是否有images数组
            if (result.data.images && Array.isArray(result.data.images)) {
                resultList.value = result.data.images.map(img => {
                    let imageUrl = img.url || img;
                    
                    // 处理图片URL
                    if (typeof imageUrl === 'string') {
                        // 确保URL以/uploads开头
                        if (imageUrl.startsWith('api/')) {
                            imageUrl = `/uploads/${imageUrl}`;
                        } else if (!imageUrl.startsWith('http') && !imageUrl.startsWith('/uploads')) {
                            imageUrl = `/uploads/${imageUrl}`;
                        }
                    }
                    
                    return {
                        imageUrl: imageUrl
                    };
                });
            }
            
            // 处理压缩包URL
            let archiveUrl = result.data.archiveUrl || '';
            if (archiveUrl.startsWith('api/')) {
                archiveUrl = `/uploads/${archiveUrl}`;
            } else if (archiveUrl && !archiveUrl.startsWith('http') && !archiveUrl.startsWith('/uploads')) {
                archiveUrl = `/uploads/${archiveUrl}`;
            }
            
            uploadResult.value = {
                type: true,
                message: `成功裁剪 ${resultList.value.length} 张图像！`,
                archiveUrl: archiveUrl
            }

            ElMessage.success(uploadResult.value.message)
        } else {
            throw new Error('返回数据格式不正确')
        }

    } catch (error) {
        uploadStatus.value = 'exception'
        uploadResult.value = {
            type: false,
            message: '裁剪失败：' + (error.message || '服务器错误')
        }
        resultList.value = []
        ElMessage.error(uploadResult.value.message)
    } finally {
        uploading.value = false
    }
}

// 下载处理结果压缩包
const downloadArchive = async () => {
    if (!uploadResult.value?.archiveUrl) {
        ElMessage.warning('下载链接不存在')
        return
    }

    try {
        window.open(uploadResult.value.archiveUrl, '_blank')
    } catch (error) {
        ElMessage.error('下载失败：' + error.message)
    }
}

// 返回上一步
const goToPrevStep = () => {
    emit('prev-step')
}

// 前往下一步处理
const goToNextStep = () => {
    // 准备传递给下一步的数据
    const passData = {
        imageUrls: resultList.value.map(item => item.imageUrl),
        archiveUrl: uploadResult.value?.archiveUrl || ''
    }
    
    // 触发步骤完成事件，传递数据
    emit('step-completed', passData)
}
</script>

<style scoped>
.upload-container {
    padding: 20px;
}

.upload-card {
    max-width: 1200px;
    margin: 0 auto;
}

.card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.previous-data-alert {
    margin: 20px 0;
}

.previous-images-info {
    margin-top: 8px;
    font-size: 13px;
}

.upload-area {
    margin: 20px 0;
}

.upload-actions {
    margin-top: 20px;
    text-align: center;
}

.upload-progress {
    margin-top: 20px;
}

.process-result {
    margin-top: 20px;
}

.operation-actions {
    display: flex;
    justify-content: center;
    margin-top: 16px;
    gap: 16px;
}

.el-upload__text {
    margin-top: 10px;
}

.el-upload__text em {
    color: #409EFF;
    font-style: normal;
}

.image-display {
    margin-top: 20px;
    padding: 20px;
    background-color: #f5f7fa;
    border-radius: 4px;
}

.image-display h3 {
    margin-bottom: 20px;
    color: #303133;
    font-size: 16px;
    font-weight: bold;
    text-align: center;
}

.result-list {
    margin-top: 20px;
}

.result-card {
    margin-bottom: 20px;
}

.result-card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.result-image {
    width: 100%;
    height: 300px;
    object-fit: contain;
}

.image-placeholder,
.image-error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 300px;
    color: #909399;
}

.image-placeholder .el-icon,
.image-error .el-icon {
    font-size: 24px;
    margin-bottom: 8px;
}

.no-result {
    padding: 40px 0;
    text-align: center;
}

.no-result-icon {
    font-size: 48px;
    color: #909399;
}

/* 调试信息样式 */
.debug-info {
    margin-top: 30px;
    padding: 15px;
    background-color: #f0f9eb;
    border-radius: 4px;
    font-size: 12px;
}

.debug-info h4 {
    color: #67c23a;
    margin-bottom: 10px;
}

.debug-item {
    margin-bottom: 8px;
    padding-bottom: 8px;
    border-bottom: 1px dashed #e1e1e1;
}

.debug-item code {
    display: inline-block;
    padding: 2px 5px;
    background-color: #f0f0f0;
    border-radius: 3px;
    color: #444;
    word-break: break-all;
}
</style>
