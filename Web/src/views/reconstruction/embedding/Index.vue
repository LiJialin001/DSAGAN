<template>
    <div class="upload-container">
        <el-card class="upload-card">
            <template #header>
                <div class="card-header">
                    <span>初始潜空间嵌入</span>
                </div>
            </template>

            <!-- 文件上传区域 -->
            <el-upload
                class="upload-area"
                drag
                :action="null"
                :auto-upload="false"
                :on-change="handleFileChange"
                :show-file-list="true"
                :accept="'.jpg,.jpeg,.png,.bmp'"
                multiple
            >
                <el-icon class="el-icon--upload"><upload-filled /></el-icon>
                <div class="el-upload__text">
                    拖拽图像文件到此处或 <em>点击上传</em>
                </div>
                <template #tip>
                    <div class="el-upload__tip">
                        请上传JPG、JPEG、PNG或BMP格式的图像文件，每个文件大小不超过 10MB
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
                    :disabled="!testMode && selectedFiles.length === 0"
                >
                    开始处理
                </el-button>
            </div>

            <!-- 上传进度显示 -->
            <div class="upload-progress" v-if="uploading">
                <el-progress 
                    :percentage="uploadProgress"
                    :status="uploadStatus"
                />
            </div>

            <!-- 处理结果显示 -->
            <div class="process-result" v-if="uploadResult">
                <el-alert
                    :title="uploadResult.message"
                    :type="uploadResult.type ? 'success' : 'error'"
                    show-icon
                />
                <!-- 下载处理结果按钮 -->
                <div class="download-actions" v-if="uploadResult.type">
                    <el-button 
                        type="primary"
                        @click="downloadArchive"
                        :disabled="!uploadResult.archiveUrl"
                    >
                        <el-icon><Download /></el-icon>
                        下载嵌入结果压缩包
                    </el-button>
                </div>
            </div>

            <!-- 处理信息显示 -->
            <div class="info-display" v-if="uploadResult && uploadResult.type">
                <el-card class="info-card">
                    <template #header>
                        <div class="info-header">
                            <span>处理信息</span>
                        </div>
                    </template>
                    <div class="info-content">
                        <p>已处理图像数量：{{ uploadResult.processedCount || 0 }} 张</p>
                        <p>生成文件数量：{{ uploadResult.outputCount || 0 }} 个</p>
                        <p class="info-tip">提示：下载的压缩包中包含所有图像对应的 .npy 文件</p>
                    </div>
                </el-card>
            </div>
        </el-card>
    </div>
</template>

<script setup>
import { ref } from 'vue'
import { UploadFilled, Download } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { embedImages, testEmbedImages } from '@/api/reconstruction'
import { formatDownloadUrl } from '@/utils/download'

// 测试模式状态
const testMode = ref(false)

// 状态变量
const selectedFiles = ref([])
const uploading = ref(false)
const uploadProgress = ref(0)
const uploadStatus = ref('')
const uploadResult = ref(null)

// 处理文件选择
const handleFileChange = (file) => {
    const extension = file.name.split('.').pop().toLowerCase()
    
    if (!['jpg', 'jpeg', 'png', 'bmp'].includes(extension)) {
        ElMessage.error('请上传JPG、JPEG、PNG或BMP格式的图像文件！')
        return false
    }
    
    if (file.size > 10 * 1024 * 1024) {
        ElMessage.error('文件大小不能超过 10MB！')
        return false
    }

    // 将文件添加到选中文件列表
    if (!selectedFiles.value.some(f => f.uid === file.uid)) {
        selectedFiles.value.push(file)
    }
    
    uploadProgress.value = 0
    uploadResult.value = null
    return true
}

// 处理文件上传
const handleUpload = async () => {
    if (!testMode.value && selectedFiles.value.length === 0) {
        ElMessage.warning('请先选择图像文件')
        return
    }

    try {
        uploading.value = true
        uploadStatus.value = ''
        uploadProgress.value = 0
        
        let result;
        
        if (testMode.value) {
            // 使用测试模式，不需要上传文件
            uploadProgress.value = 50;
            result = await testEmbedImages();
        } else {
            // 正常模式，需要上传文件
            const formData = new FormData()
            
            // 添加多个图像文件
            selectedFiles.value.forEach((file, index) => {
                formData.append(`image_${index}`, file.raw)
            })
            
            result = await embedImages(formData, (progressEvent) => {
                if (progressEvent.lengthComputable) {
                    const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
                    uploadProgress.value = Math.min(progress, 90)
                }
            })
        }

        uploadProgress.value = 100
        uploadStatus.value = 'success'
        
        if (result.code === 200 && result.data) {
            uploadResult.value = {
                type: true,
                message: `成功处理 ${result.data.processedCount} 张图片！`,
                archiveUrl: result.data.archiveUrl,
                processedCount: result.data.processedCount,
                outputCount: result.data.outputCount
            }

            ElMessage.success(uploadResult.value.message)
        } else {
            throw new Error('返回数据格式不正确')
        }

    } catch (error) {
        uploadStatus.value = 'exception'
        uploadResult.value = {
            type: false,
            message: '处理失败：' + (error.message || '网络错误')
        }
        ElMessage.error(uploadResult.value.message)
    } finally {
        uploading.value = false
    }
}

// 下载压缩包功能
const downloadArchive = async () => {
    if (!uploadResult.value?.archiveUrl) {
        ElMessage.warning('下载链接不存在')
        return
    }

    try {
        // 使用formatDownloadUrl处理下载地址
        const downloadUrl = formatDownloadUrl(uploadResult.value.archiveUrl)
        const response = await fetch(downloadUrl)
        const blob = await response.blob()
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.download = `embedding_results_${new Date().getTime()}.zip`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        window.URL.revokeObjectURL(url)
    } catch (error) {
        ElMessage.error('下载失败：' + error.message)
    }
}
</script>

<style scoped>
.upload-container {
    padding: 20px;
}

.upload-card {
    max-width: 800px;
    margin: 0 auto;
}

.card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
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

.download-actions {
    margin-top: 20px;
    text-align: center;
}

.info-display {
    margin-top: 20px;
}

.info-card {
    margin-top: 20px;
}

.info-header {
    font-weight: bold;
}

.info-content {
    padding: 10px 0;
}

.info-tip {
    color: #909399;
    font-size: 0.9em;
    margin-top: 10px;
}
</style>
